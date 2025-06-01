import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/material.dart';
import '../settings/settings_bloc.dart';
import '../ai_prompting/sys_prompt.dart';
import '../ai_prompting/respones_handler.dart';
import '../../main.dart' as app_main;
import '../mood_data/mood_data_bloc.dart';
import '../mood_data/mood_data_state.dart';

class GeminiChatService {
  final String apiKey;
  String model;
  bool _isInitialized = false;
  int _retryCount = 0;
  final int _maxRetries = 3;
  Gemini? _gemini;
  List<Map<String, String>> _history = [];

  /// Debug mode - when true, print detailed information about requests and responses
  final bool debugMode;

  // Previous messages to provide context
  String _contextPrompt = '';
  int _maxContextLength = 20000; // Character limit for context

  GeminiChatService(
    this.apiKey, {
    this.model = 'gemini-pro',
    this.debugMode = true, // Default to true for debugging
  }) {
    if (apiKey.isNotEmpty) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      // Keep using Gemini package only for model listing
      Gemini.init(apiKey: apiKey, enableDebugging: debugMode);

      // We don't need _gemini instance for chat anymore, only for listing models
      _gemini = Gemini.instance;

      // Check connectivity by making a test request
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        if (debugMode) {
          debugPrint('========== INITIALIZATION ERROR ==========');
          debugPrint('Connectivity check failed during initialization');
          debugPrint('==========================================');
        } else {
          debugPrint('Connectivity check failed during initialization');
        }
        throw Exception('Network connectivity issue');
      }

      _isInitialized = true;
      if (debugMode) {
        debugPrint('========== INITIALIZATION SUCCESS ==========');
        debugPrint(
          'Gemini service initialized successfully with model: $model',
        );
        debugPrint(
          'API Key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        debugPrint('===========================================');
      } else {
        debugPrint(
          'Gemini service initialized successfully with model: $model',
        );
      }
    } catch (e) {
      if (debugMode) {
        debugPrint('========== INITIALIZATION ERROR ==========');
        debugPrint('Error initializing Gemini service: $e');
        debugPrint('Retry count: $_retryCount / $_maxRetries');
        debugPrint('==========================================');
      } else {
        debugPrint('Error initializing Gemini service: $e');
      }

      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying initialization (${_retryCount}/${_maxRetries})');
        await Future.delayed(Duration(seconds: 1));
        await _initialize();
      }
    }
  }

  // Fetch available Gemini models from the API
  Future<List<dynamic>> getAvailableModels() async {
    if (!_isInitialized && apiKey.isNotEmpty) {
      await _initialize();
    }

    if (!_isInitialized) {
      throw Exception('Gemini API not initialized. Please check your API key.');
    }

    try {
      final models = await Gemini.instance.listModels();
      debugPrint('Successfully fetched ${models.length} Gemini models');

      return models;
    } on SocketException catch (_) {
      throw Exception(
        'Network error: Please check your internet connection and try again.',
      );
    } on GeminiException catch (e) {
      throw Exception('Gemini API error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }

  // Update API key when it changes in settings
  Future<void> updateApiKey(String newApiKey, {String? newModel}) async {
    if ((apiKey != newApiKey && newApiKey.isNotEmpty) ||
        (newModel != null && newModel != model)) {
      _retryCount = 0;
      try {
        Gemini.init(
          apiKey: newApiKey,
          enableDebugging: true,
          // Model will be specified when making the request
        );

        _gemini = Gemini.instance;

        // Clear history when API key or model changes
        _history = [];
        _contextPrompt = '';

        _isInitialized = true;
        debugPrint('Gemini API key updated successfully');
        if (newModel != null && newModel != model) {
          // Update the model field
          model = newModel;
          debugPrint('Model changed to: $model');
        }
      } catch (e) {
        debugPrint('Error updating Gemini API key: $e');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint('Retrying key update (${_retryCount}/${_maxRetries})');
          await Future.delayed(Duration(seconds: 1));
          await updateApiKey(newApiKey, newModel: newModel);
        }
      }
    }
  }

  // Update just the model when it changes in settings
  Future<void> updateModel(String newModel) async {
    if (newModel != model) {
      // Update the model field
      model = newModel;
      debugPrint('Model updated to: $model');

      // Clear conversation history for new model
      _history = [];
      _contextPrompt = '';
    }
  }

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // Try to connect to Google's API endpoint
      final response = await http
          .get(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 400;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  void clearConversation() {
    if (_isInitialized) {
      _history = [];
      _contextPrompt = '';
      debugPrint('Conversation history cleared');
    }
  }

  // Update context prompt with conversation history
  void _updateContextPrompt() {
    if (_history.isEmpty) {
      _contextPrompt = '';
      return;
    }

    // Create a context prompt from history
    StringBuffer context = StringBuffer();
    context.writeln("This is the conversation history so far:");

    for (final entry in _history) {
      final role = entry['role'] ?? 'user';
      final message = entry['message'] ?? '';

      if (role == 'user') {
        context.writeln("User: $message");
      } else {
        context.writeln("Assistant: $message");
      }
    }

    // Limit context size if too large
    String fullContext = context.toString();
    if (fullContext.length > _maxContextLength) {
      fullContext = fullContext.substring(
        fullContext.length - _maxContextLength,
      );
      // Find the first complete message after truncation
      final firstUserIndex = fullContext.indexOf('User: ');
      if (firstUserIndex > 0) {
        fullContext = fullContext.substring(firstUserIndex);
      }
    }

    _contextPrompt = fullContext;
  }

  // Get formatted mood data for the system prompt
  String _getFormattedMoodData() {
    final moodDataBloc = app_main.moodDataBloc;
    final state = moodDataBloc.state;

    if (state.responses.isEmpty) {
      return 'The user has not provided any mood data yet.';
    }

    final StringBuffer moodInfo = StringBuffer();
    moodInfo.writeln('User Mood Data:');

    for (final entry in state.responses.entries) {
      final questionId = entry.key;
      final question = state.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => const MoodQuestion(id: '', question: '', options: []),
      );

      if (question.id.isNotEmpty) {
        moodInfo.writeln('- ${question.question}: ${entry.value}');
      }
    }

    return moodInfo.toString();
  }

  // Send a message to Gemini and get a response
  Future<String?> sendMessage(String message) async {
    if (!_isInitialized) {
      if (apiKey.isEmpty) {
        return "Please set a Gemini API key in settings to use the AI chat feature.";
      }
      await _initialize();
      if (!_isInitialized) {
        return "Failed to initialize the Gemini API. Please check your API key and internet connection.";
      }
    }

    // Check internet connection first
    final hasConnectivity = await _checkConnectivity();
    if (!hasConnectivity) {
      return "No internet connection. Please check your network settings and try again.";
    }

    _retryCount = 0;
    return await _attemptSendMessage(message);
  }

  Future<String?> _attemptSendMessage(String message) async {
    try {
      // Format the message with <user_request> tags
      final String formattedUserMessage =
          '<user_request>$message</user_request>';

      // Add user message to history
      _history.add({'role': 'user', 'message': message});

      // Update context with history
      _updateContextPrompt();

      // Extract the actual model name without the "models/" prefix
      String modelName = model;
      if (modelName.startsWith('models/')) {
        modelName = modelName.substring('models/'.length);
        debugPrint('Using model name without prefix: $modelName');
      }

      // Direct HTTP request to Gemini API
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      );

      final headers = {'Content-Type': 'application/json'};

      // Format conversation history for the API
      List<Map<String, dynamic>> contents = [];

      // If no history, just send the current message with system prompt
      if (_history.length <= 1) {
        contents = [
          {
            'role': 'user',
            'parts': [
              {'text': formattedUserMessage},
            ],
          },
        ];

        // Add system prompt after user message
        if (SystemPrompt.prompt.isNotEmpty) {
          // Replace mood data placeholder with actual mood data
          final systemPrompt = SystemPrompt.prompt.replaceAll(
            '{MOOD_DATA_PLACEHOLDER}',
            _getFormattedMoodData(),
          );

          contents.add({
            'role': 'user',
            'parts': [
              {'text': '<system_prompt>$systemPrompt</system_prompt>'},
            ],
          });
        }
      } else {
        // Create a single content object with multiple message parts
        Map<String, dynamic> contentObj = {'role': 'user', 'parts': []};

        // Add all history messages as parts
        for (int i = 0; i < _history.length - 1; i++) {
          // Skip the last message (current one)
          final entry = _history[i];
          final role = entry['role'] == 'user' ? 'user' : 'model';
          final text = entry['message'] ?? '';

          // Change role for the content object when needed
          if (i == 0 || role != _history[i - 1]['role']) {
            // If this isn't the first message and role changed, add the previous content
            if (i > 0) {
              contents.add(contentObj);
              contentObj = {'role': role, 'parts': []};
            } else {
              contentObj['role'] = role;
            }
          }

          // Add this message as a part (normal formatting for history)
          contentObj['parts'].add({'text': text});
        }

        // Add the final history content object
        contents.add(contentObj);

        // Now add the current message with <user_request> tags
        contents.add({
          'role': 'user',
          'parts': [
            {'text': formattedUserMessage},
          ],
        });

        // Add system prompt after the user message
        if (SystemPrompt.prompt.isNotEmpty) {
          // Replace mood data placeholder with actual mood data
          final systemPrompt = SystemPrompt.prompt.replaceAll(
            '{MOOD_DATA_PLACEHOLDER}',
            _getFormattedMoodData(),
          );

          contents.add({
            'role': 'user',
            'parts': [
              {'text': '<system_prompt>$systemPrompt</system_prompt>'},
            ],
          });
        }
      }

      // Create the request body
      final requestBody = {'contents': contents};
      final bodys = jsonEncode(requestBody);

      if (debugMode) {
        debugPrint('========== DEBUG INFO ==========');
        debugPrint('Sending request to model: $modelName');
        debugPrint('The header: $headers');
        debugPrint('The body: $bodys');
        debugPrint('================================');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Process the response using ResponseHandler
        final taggedContent = ResponseHandler.processResponse(generatedText);

        // Print the tagged content if in debug mode
        if (debugMode) {
          debugPrint('========== RESPONSE ==========');
          debugPrint('Response status: ${response.statusCode}');
          debugPrint('Generated text: $generatedText');
          debugPrint('Tagged content:');
          ResponseHandler.printTaggedContent(taggedContent);
          debugPrint('==============================');
        }

        // Add response to history
        _history.add({'role': 'model', 'message': generatedText});

        return generatedText;
      } else {
        if (debugMode) {
          debugPrint('========== ERROR RESPONSE ==========');
          debugPrint(
            'API request failed with status code: ${response.statusCode}',
          );
          debugPrint('Response body: ${response.body}');
          debugPrint('====================================');
        } else {
          debugPrint(
            'API request failed with status code: ${response.statusCode}',
          );
          debugPrint('Response body: ${response.body}');
        }

        if (response.statusCode == 400 &&
            response.body.contains('API key not valid')) {
          return "Invalid API key. Please check your Gemini API key in settings and try again.";
        } else if (response.statusCode == 404 &&
            response.body.contains('Model not found')) {
          return "Model error: The selected Gemini model ($modelName) is not available or not supported with your current API key. Please try a different model in settings.";
        } else {
          return "API Error (${response.statusCode}): ${response.reasonPhrase}";
        }
      }
    } on SocketException catch (_) {
      if (debugMode) {
        debugPrint('========== NETWORK ERROR ==========');
        debugPrint('Network connection error detected');
        debugPrint('===================================');
      }
      return "Network error: Please check your internet connection and try again.";
    } catch (e) {
      if (debugMode) {
        debugPrint('========== EXCEPTION ==========');
        debugPrint('Error: $e');
        debugPrint('Attempt: ${_retryCount + 1} of $_maxRetries');
        debugPrint('===============================');
      }

      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Error occurred, retrying (${_retryCount}/${_maxRetries})');
        await Future.delayed(Duration(seconds: 1));
        return _attemptSendMessage(message);
      }
      return "Error: $e";
    }
  }

  // For debugging - get conversation history count
  int get historyCount => _history.length;
}

// Factory function to create a GeminiChatService instance
GeminiChatService createGeminiChatService() {
  final settingsState = app_main.settingsBloc.state;
  return GeminiChatService(
    settingsState.geminiApiKey,
    model: settingsState.geminiModel,
  );
}
