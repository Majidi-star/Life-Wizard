import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Default Gemini model used when none is configured.
const String kDefaultGeminiModel = 'gemini-2.5-flash';

/// Metadata for a model returned by the Gemini `/v1beta/models` endpoint.
class GeminiModelInfo {
  final String? name;
  final String? displayName;
  final String? description;
  final List<String> supportedGenerationMethods;

  const GeminiModelInfo({
    this.name,
    this.displayName,
    this.description,
    this.supportedGenerationMethods = const [],
  });

  factory GeminiModelInfo.fromJson(Map<String, dynamic> json) {
    final methodsRaw = json['supportedGenerationMethods'];
    return GeminiModelInfo(
      name: json['name']?.toString(),
      displayName: json['displayName']?.toString(),
      description: json['description']?.toString(),
      supportedGenerationMethods:
          methodsRaw is List
              ? methodsRaw.map((e) => e.toString()).toList()
              : const [],
    );
  }

  static List<GeminiModelInfo> jsonToList(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((m) => GeminiModelInfo.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

/// Base exception for Gemini transport errors.
abstract class GeminiTransportException implements Exception {
  final String message;
  const GeminiTransportException(this.message);

  bool get isRetryable => false;

  @override
  String toString() => message;
}

/// Thrown on network/timeout errors (safe to retry).
class GeminiNetworkException extends GeminiTransportException {
  const GeminiNetworkException(super.message);

  @override
  bool get isRetryable => true;
}

/// Thrown when the Gemini REST API returns a non-200 HTTP status.
class GeminiApiException extends GeminiTransportException {
  final int statusCode;
  const GeminiApiException(this.statusCode, super.message);

  @override
  bool get isRetryable => statusCode >= 500 && statusCode < 600;
}

/// Thrown when a prompt or candidate response is blocked by safety/policy filters.
class GeminiBlockedException extends GeminiTransportException {
  final String? reason;
  const GeminiBlockedException(super.message, {this.reason});
}

/// Thrown when the response payload is malformed or empty.
class GeminiResponseException extends GeminiTransportException {
  const GeminiResponseException(super.message);
}

class GeminiChatService {
  static const int _maxHistoryLength = 30;

  String apiKey;
  String model;
  bool _isInitialized = false;
  List<Map<String, String>> _history = [];

  /// Debug mode - defaults to kDebugMode so production builds never log requests/responses.
  final bool debugMode;

  GeminiChatService(
    this.apiKey, {
    this.model = kDefaultGeminiModel,
    this.debugMode = kDebugMode,
  }) {
    if (apiKey.isNotEmpty) {
      _initialize();
    }
  }

  /// Strips any query parameters or raw API key strings before surfacing messages.
  static String sanitizeErrorText(String text, {String? secretKey}) {
    var sanitized = text.replaceAll(
      RegExp(r'([?&]key=)[^&\s]+', caseSensitive: false),
      r'$1***',
    );
    if (secretKey != null && secretKey.isNotEmpty) {
      sanitized = sanitized.replaceAll(secretKey, '***');
    }
    return sanitized;
  }

  Future<void> _initialize() async {
    if (apiKey.isEmpty) {
      _isInitialized = false;
      return;
    }

    _isInitialized = true;
    if (debugMode) {
      debugPrint('Gemini service initialized with model: $model');
    }
  }

  /// Fetch available Gemini models from the API using the x-goog-api-key header.
  Future<List<GeminiModelInfo>> getAvailableModels() async {
    if (apiKey.isEmpty) {
      throw const GeminiApiException(
        401,
        'Gemini API key is not set. Please set your API key in settings.',
      );
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models',
      );
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['models'] is List) {
          final models = GeminiModelInfo.jsonToList(decoded['models'] as List);
          if (debugMode) {
            debugPrint('Successfully fetched ${models.length} Gemini models');
          }
          return models;
        }
        return [];
      }

      throw GeminiApiException(
        response.statusCode,
        'Failed to fetch Gemini models (HTTP ${response.statusCode}).',
      );
    } on SocketException catch (_) {
      throw const GeminiNetworkException(
        'Network error: Please check your internet connection and try again.',
      );
    } on TimeoutException catch (_) {
      throw const GeminiNetworkException(
        'Request timed out while fetching Gemini models.',
      );
    } on http.ClientException catch (e) {
      throw GeminiNetworkException(
        'Network error: ${sanitizeErrorText(e.message, secretKey: apiKey)}',
      );
    }
  }

  /// Update API key and/or model only when they actually change.
  Future<void> updateApiKey(String newApiKey, {String? newModel}) async {
    final bool keyChanged = apiKey != newApiKey;
    final bool modelChanged = newModel != null && newModel != model;
    if (!keyChanged && !modelChanged) {
      return;
    }

    final bool hadPreviousKey = apiKey.isNotEmpty;
    apiKey = newApiKey;
    if (newModel != null) {
      model = newModel;
    }

    if (apiKey.isEmpty) {
      _isInitialized = false;
      _history = [];
      return;
    }

    // Clear history only if switching away from an existing key or changing model.
    if ((keyChanged && hadPreviousKey) || modelChanged) {
      _history = [];
    }

    await _initialize();
  }

  /// Update just the model when it changes in settings.
  Future<void> updateModel(String newModel) async {
    if (newModel == model) {
      return;
    }
    model = newModel;
    _history = [];
    if (debugMode) {
      debugPrint('Model updated to: $model');
    }
  }

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  void clearConversation() {
    _history = [];
    if (debugMode) {
      debugPrint('Conversation history cleared');
    }
  }

  void _appendToHistory(String role, String message) {
    _history.add({'role': role, 'message': message});
    if (_history.length > _maxHistoryLength) {
      _history.removeRange(0, _history.length - _maxHistoryLength);
    }
  }

  /// Sends a request to Gemini.
  ///
  /// When [contents] is supplied (from [AiMessageService]), it is sent directly as
  /// the alternating user/model `contents` list alongside optional [systemInstruction].
  /// Throws typed [GeminiTransportException] subclasses on failure.
  Future<String> sendMessage(
    String message, {
    String? systemInstruction,
    List<Map<String, dynamic>>? contents,
  }) async {
    if (apiKey.isEmpty) {
      throw const GeminiApiException(
        401,
        'Please set a Gemini API key in settings to use the AI chat feature.',
      );
    }

    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        throw const GeminiApiException(
          500,
          'Failed to initialize the Gemini API. Please check your API key.',
        );
      }
    }

    // Extract the actual model name without the "models/" prefix
    String modelName = model.isNotEmpty ? model : kDefaultGeminiModel;
    if (modelName.startsWith('models/')) {
      modelName = modelName.substring('models/'.length);
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final List<Map<String, dynamic>> requestContents =
        contents ??
        [
          ..._history.map(
            (entry) => <String, dynamic>{
              'role': entry['role'] == 'model' ? 'model' : 'user',
              'parts': [
                {'text': entry['message'] ?? ''},
              ],
            },
          ),
          <String, dynamic>{
            'role': 'user',
            'parts': [
              {'text': message},
            ],
          },
        ];

    final Map<String, dynamic> requestBody = {
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'contents': requestContents,
    };

    if (debugMode) {
      debugPrint(
        'Sending Gemini request: model=$modelName, turns=${requestContents.length}',
      );
    }

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final generatedText = _parseGeneratedText(response.body);
        if (contents == null) {
          _appendToHistory('user', message);
          _appendToHistory('model', generatedText);
        }
        return generatedText;
      }

      if (debugMode) {
        debugPrint(
          'Gemini API error: status=${response.statusCode}, body=${sanitizeErrorText(response.body, secretKey: apiKey)}',
        );
      }

      if (response.statusCode == 404) {
        throw GeminiApiException(
          404,
          'Model error: The selected Gemini model ($modelName) is not available or not supported with your current API key. Please try a different model in settings.',
        );
      }
      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          (response.statusCode == 400 &&
              response.body.contains('API key not valid'))) {
        throw GeminiApiException(
          response.statusCode,
          'Invalid API key. Please check your Gemini API key in settings and try again.',
        );
      }
      if (response.statusCode == 429) {
        throw const GeminiApiException(
          429,
          'Rate limit exceeded. Please wait a moment and try again.',
        );
      }

      throw GeminiApiException(
        response.statusCode,
        'API Error (${response.statusCode}): ${response.reasonPhrase ?? 'Request failed'}',
      );
    } on GeminiTransportException {
      rethrow;
    } on SocketException catch (_) {
      throw const GeminiNetworkException(
        'Network error: Please check your internet connection and try again.',
      );
    } on TimeoutException catch (_) {
      throw const GeminiNetworkException(
        'Request timed out: Please check your internet connection and try again.',
      );
    } on http.ClientException catch (e) {
      throw GeminiNetworkException(
        'Network error: ${sanitizeErrorText(e.message, secretKey: apiKey)}',
      );
    } catch (e) {
      throw GeminiResponseException(
        sanitizeErrorText(e.toString(), secretKey: apiKey),
      );
    }
  }

  String _parseGeneratedText(String responseBody) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      throw const GeminiResponseException(
        'Invalid JSON received from Gemini API.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const GeminiResponseException(
        'Unexpected response format from Gemini API.',
      );
    }

    final promptFeedback = decoded['promptFeedback'];
    if (promptFeedback is Map) {
      final blockReason = promptFeedback['blockReason']?.toString();
      if (blockReason != null && blockReason.isNotEmpty) {
        throw GeminiBlockedException(
          'Your message was blocked by safety filters ($blockReason).',
          reason: blockReason,
        );
      }
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiResponseException(
        'No response candidates were returned by Gemini.',
      );
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      throw const GeminiResponseException(
        'Invalid candidate structure in Gemini response.',
      );
    }

    final finishReason = firstCandidate['finishReason']?.toString();
    final content = firstCandidate['content'];
    final parts = content is Map ? content['parts'] : null;

    final StringBuffer textBuffer = StringBuffer();
    if (parts is List) {
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          textBuffer.write(part['text'] as String);
        }
      }
    }

    final generatedText = textBuffer.toString();
    if (generatedText.isEmpty) {
      if (finishReason == 'SAFETY' ||
          finishReason == 'RECITATION' ||
          finishReason == 'PROHIBITED_CONTENT' ||
          finishReason == 'BLOCKLIST' ||
          finishReason == 'SPII') {
        throw GeminiBlockedException(
          'Response was blocked by Gemini ($finishReason).',
          reason: finishReason,
        );
      }
      throw GeminiResponseException(
        'Empty response received from Gemini (finishReason: ${finishReason ?? 'unknown'}).',
      );
    }

    return generatedText;
  }

  // For debugging - get conversation history count
  int get historyCount => _history.length;
}

// Factory function to create a GeminiChatService instance without importing main.dart.
GeminiChatService createGeminiChatService({
  String apiKey = '',
  String model = kDefaultGeminiModel,
}) {
  return GeminiChatService(
    apiKey,
    model: model.isNotEmpty ? model : kDefaultGeminiModel,
  );
}
