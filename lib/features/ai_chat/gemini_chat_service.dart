import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/material.dart';
import '../settings/settings_bloc.dart';
import '../../main.dart' as app_main;

class GeminiChatService {
  final String apiKey;
  String model;
  bool _isInitialized = false;
  int _retryCount = 0;
  final int _maxRetries = 3;
  Gemini? _gemini;
  List<Map<String, String>> _history = [];

  // Previous messages to provide context
  String _contextPrompt = '';
  int _maxContextLength = 2000; // Character limit for context

  GeminiChatService(this.apiKey, {this.model = 'gemini-pro'}) {
    if (apiKey.isNotEmpty) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      // Keep using Gemini package only for model listing
      Gemini.init(apiKey: apiKey, enableDebugging: true);

      // We don't need _gemini instance for chat anymore, only for listing models
      _gemini = Gemini.instance;

      // Check connectivity by making a test request
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        debugPrint('Connectivity check failed during initialization');
        throw Exception('Network connectivity issue');
      }

      _isInitialized = true;
      debugPrint('Gemini service initialized successfully with model: $model');
    } catch (e) {
      debugPrint('Error initializing Gemini service: $e');
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

      // Print detailed information about each model
      debugPrint('===== GEMINI MODELS LIST =====');
      for (var model in models) {
        debugPrint('Model: ${model.name}');
        debugPrint('Display Name: ${model.displayName}');
        debugPrint('Description: ${model.description}');
        debugPrint('Input Token Limit: ${model.inputTokenLimit}');
        debugPrint('Output Token Limit: ${model.outputTokenLimit}');
        debugPrint(
          'Supported Generation Methods: ${model.supportedGenerationMethods}',
        );
        debugPrint('----------------------------');
      }
      debugPrint('==============================');

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

      // If we have history, format it as a conversation
      if (_history.length > 1) {
        // Create a single content object with multiple message parts
        Map<String, dynamic> contentObj = {'role': 'user', 'parts': []};

        // Add all history messages as parts
        for (int i = 0; i < _history.length; i++) {
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

          // Add this message as a part
          contentObj['parts'].add({'text': text});
        }

        // Add the final content object
        contents.add(contentObj);
      } else {
        // Just use the single message if no history
        contents = [
          {
            'role': 'user',
            'parts': [
              {'text': message},
            ],
          },
        ];
      }

      // Create the request body
      final requestBody = {'contents': contents};

      debugPrint('Sending request to model: $modelName');
      // Print the full request for debugging
      debugPrint('====== FULL GEMINI API REQUEST ======');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint(
        'Body: ${const JsonEncoder.withIndent('  ').convert(requestBody)}',
      );
      debugPrint('====================================');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Print the full response for debugging
        debugPrint('====== FULL GEMINI API RESPONSE ======');
        debugPrint(const JsonEncoder.withIndent('  ').convert(jsonResponse));
        debugPrint('======================================');

        final generatedText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Add response to history
        _history.add({'role': 'model', 'message': generatedText});

        return generatedText;
      } else {
        debugPrint(
          'API request failed with status code: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');

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
      return "Network error: Please check your internet connection and try again.";
    } catch (e) {
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
