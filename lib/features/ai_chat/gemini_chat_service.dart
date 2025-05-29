import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/material.dart';
import '../settings/settings_bloc.dart';
import '../../main.dart' as app_main;

class GeminiChatService {
  final String apiKey;
  bool _isInitialized = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  GeminiChatService(this.apiKey) {
    if (apiKey.isNotEmpty) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      // Use a direct URL to the API endpoint
      Gemini.init(
        apiKey: apiKey,
        enableDebugging: true, // Enable debug logs
      );
      _isInitialized = true;
      debugPrint('Gemini initialized successfully');
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

  // Update API key when it changes in settings
  Future<void> updateApiKey(String newApiKey) async {
    if (apiKey != newApiKey && newApiKey.isNotEmpty) {
      _retryCount = 0;
      try {
        Gemini.init(apiKey: newApiKey, enableDebugging: true);
        _isInitialized = true;
        debugPrint('Gemini API key updated successfully');
      } catch (e) {
        debugPrint('Error updating Gemini API key: $e');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint('Retrying key update (${_retryCount}/${_maxRetries})');
          await Future.delayed(Duration(seconds: 1));
          await updateApiKey(newApiKey);
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
      final gemini = Gemini.instance;
      final response = await gemini.text(message);
      return response?.output;
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
}

// Factory function to create a GeminiChatService instance
GeminiChatService createGeminiChatService() {
  final settingsState = app_main.settingsBloc.state;
  return GeminiChatService(settingsState.geminiApiKey);
}
