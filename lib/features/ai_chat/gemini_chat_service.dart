import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/material.dart';
import '../settings/settings_bloc.dart';
import '../../main.dart' as app_main;

class GeminiChatService {
  final String apiKey;
  final String model;
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
      Gemini.init(
        apiKey: apiKey,
        enableDebugging: true, // Enable debug logs
        // Model will be specified when making the request
      );

      _gemini = Gemini.instance;
      _isInitialized = true;
      debugPrint('Gemini initialized successfully with model: $model');
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
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
          debugPrint('Model changed to: $newModel');
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

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // Try multiple domains to ensure connectivity
      for (final domain in [
        'google.com',
        'generativelanguage.googleapis.com',
        'cloud.google.com',
      ]) {
        try {
          final result = await InternetAddress.lookup(domain);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      return false;
    } on SocketException catch (_) {
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
      if (_gemini == null) {
        _gemini = Gemini.instance;
      }

      // Add user message to history
      _history.add({'role': 'user', 'message': message});

      // Update context with history
      _updateContextPrompt();

      // Create prompt with context + new message
      String prompt = message;
      if (_contextPrompt.isNotEmpty) {
        prompt =
            '$_contextPrompt\n\nUser: $message\n\nRespond to the last message from the User, taking into account the conversation history above.';
      }

      // Use simple text method with model parameter
      final response = await _gemini!.text(
        prompt,
        modelName: model, // Specify the model here
      );

      if (response != null && response.output != null) {
        // Add response to history
        _history.add({'role': 'model', 'message': response.output!});

        return response.output;
      }
      return "No response from Gemini AI.";
    } on SocketException catch (_) {
      return "Network error: Please check your internet connection and try again.";
    } on GeminiException catch (e) {
      final errorMsg = e.message.toString();
      if (errorMsg.contains('API key not valid')) {
        return "Invalid API key. Please check your Gemini API key in settings and try again.";
      } else if (errorMsg.contains('Failed host lookup')) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint('Network error, retrying (${_retryCount}/${_maxRetries})');
          await Future.delayed(Duration(seconds: 1));
          return _attemptSendMessage(message);
        }
        return "Network error: Unable to connect to Gemini API. Please check your internet connection and try again.";
      } else if (errorMsg.contains('Model not found') ||
          errorMsg.contains('not supported')) {
        return "Model error: The selected Gemini model ($model) is not available or not supported with your current API key. Please try a different model in settings.";
      } else {
        return "Gemini API error: $errorMsg";
      }
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
