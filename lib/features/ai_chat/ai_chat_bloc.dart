// AI Chat BLoC file

import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../ai_prompting/ai_message_service.dart';
import '../mood_data/mood_data_bloc.dart';
import '../settings/settings_bloc.dart';
import '../settings/settings_state.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'ai_chat_widgets.dart';
import 'gemini_chat_service.dart';

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final SettingsBloc _settingsBloc;
  final GeminiChatService _geminiService;
  final AiMessageService _aiMessageService;
  StreamSubscription<SettingsState>? _settingsSubscription;
  String _currentModel = '';

  // Constructor using dependency injection — builds a single GeminiChatService instance.
  AIChatBloc({
    required SettingsBloc settingsBloc,
    required MoodDataBloc moodDataBloc,
    GeminiChatService? geminiService,
  }) : this._withService(
         settingsBloc: settingsBloc,
         moodDataBloc: moodDataBloc,
         service:
             geminiService ??
             createGeminiChatService(
               apiKey: settingsBloc.state.geminiApiKey,
               model: settingsBloc.state.geminiModel,
             ),
       );

  AIChatBloc._withService({
    required SettingsBloc settingsBloc,
    required MoodDataBloc moodDataBloc,
    required GeminiChatService service,
  }) : _settingsBloc = settingsBloc,
       _geminiService = service,
       _aiMessageService = AiMessageService(
         chatService: service,
         getAiGuidelines: () => settingsBloc.state.aiGuideLines,
         getMoodDataState: () => moodDataBloc.state,
       ),
       super(
         AIChatState(
           currentModel:
               settingsBloc.state.geminiModel.isNotEmpty
                   ? settingsBloc.state.geminiModel
                   : kDefaultGeminiModel,
         ),
       ) {
    _currentModel = state.currentModel;

    // Listen for settings changes to update the API key and model without leaking the subscription.
    _settingsSubscription = _settingsBloc.stream.listen((settings) {
      final resolvedModel =
          settings.geminiModel.isNotEmpty
              ? settings.geminiModel
              : kDefaultGeminiModel;
      final bool modelChanged = resolvedModel != _currentModel;
      final bool keyChanged = settings.geminiApiKey != _geminiService.apiKey;

      if (keyChanged || modelChanged) {
        _geminiService.updateApiKey(
          settings.geminiApiKey,
          newModel: resolvedModel,
        );
        _currentModel = resolvedModel;
        if (modelChanged && state.messages.isNotEmpty) {
          add(StartNewConversation());
        }
      }
    });

    on<SendMessage>(_onSendMessage, transformer: droppable());
    on<ClearMessages>(_onClearMessages);
    on<StartNewConversation>(_onStartNewConversation);
  }

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    return super.close();
  }

  /// Handle the SendMessage event by sending a message to Gemini API
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIChatState> emit,
  ) async {
    final userMessage = ChatMessage(text: event.message, isUser: true);
    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    try {
      // Always read the latest API key and model from settings per request.
      final settings = _settingsBloc.state;
      final apiKey = settings.geminiApiKey;
      final modelName =
          settings.geminiModel.isNotEmpty
              ? settings.geminiModel
              : kDefaultGeminiModel;

      if (apiKey.isEmpty) {
        final aiMessage = ChatMessage(
          text:
              "Please set your Gemini API key in the settings to use the AI chat feature.",
          isUser: false,
        );

        final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
          ..add(aiMessage);
        emit(state.copyWith(messages: messagesWithResponse, isLoading: false));
        return;
      }

      // Update API key or model only on real change so history isn't wiped.
      if (_geminiService.apiKey != apiKey || _geminiService.model != modelName) {
        await _geminiService.updateApiKey(apiKey, newModel: modelName);
      }
      _currentModel = modelName;

      // Get AI response using AI Message Service
      final response = await _aiMessageService.sendMessage(event.message);

      if (response['success'] != true) {
        final errorText = GeminiChatService.sanitizeErrorText(
          response['error']?.toString() ??
              "Sorry, I couldn't generate a response.",
          secretKey: apiKey,
        );
        final errorMessage = ChatMessage(text: errorText, isUser: false);
        final messagesWithError = List<ChatMessage>.from(updatedMessages)
          ..add(errorMessage);
        emit(
          state.copyWith(
            messages: messagesWithError,
            isLoading: false,
            currentModel: modelName,
          ),
        );
        return;
      }

      final rawResponse = response['rawResponse'] as String?;

      // Extract function call results with proper type handling
      final functionCallResultsRaw = response['functionCallResults'];
      final List<FunctionCallResult> functionCallResults = [];

      if (functionCallResultsRaw is List) {
        for (var item in functionCallResultsRaw) {
          if (item is FunctionCallResult) {
            functionCallResults.add(item);
          } else if (item is Map) {
            final name = item['name']?.toString() ?? 'Unknown Function';
            final success = item['success'] == true;
            functionCallResults.add(
              FunctionCallResult(name: name, success: success),
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Function calls to display: ${functionCallResults.length}');
      }

      final aiMessage = ChatMessage(
        text: rawResponse ?? "Sorry, I couldn't generate a response.",
        isUser: false,
      );

      final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);

      for (var functionCall in functionCallResults) {
        messagesWithResponse.add(
          ChatMessage(
            text: functionCall.name,
            isUser: false,
            isSystemMessage: true,
            isFunctionCallMessage: true,
            functionCalls: [functionCall],
          ),
        );
      }

      emit(
        state.copyWith(
          messages: messagesWithResponse,
          isLoading: false,
          currentModel: modelName,
        ),
      );
    } catch (e) {
      final sanitized = GeminiChatService.sanitizeErrorText(
        e.toString(),
        secretKey: _geminiService.apiKey,
      );
      final aiMessage = ChatMessage(
        text: "Error: $sanitized",
        isUser: false,
      );

      final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);
      emit(state.copyWith(messages: messagesWithResponse, isLoading: false));
    }
  }

  /// Handle the ClearMessages event by clearing the chat history
  void _onClearMessages(ClearMessages event, Emitter<AIChatState> emit) {
    // Clear conversation history in both services
    _geminiService.clearConversation();
    _aiMessageService.clearConversation();

    // Clear messages in the state
    emit(state.copyWith(messages: []));
  }

  /// Handle the StartNewConversation event by clearing history and starting a new conversation
  void _onStartNewConversation(
    StartNewConversation event,
    Emitter<AIChatState> emit,
  ) {
    // Clear conversation history in both services
    _geminiService.clearConversation();
    _aiMessageService.clearConversation();

    // Update state to indicate a new conversation has started
    final modelName = _settingsBloc.state.geminiModel;
    _currentModel = modelName;

    // Clear all previous messages and add a system message
    final systemMessage = ChatMessage(
      text: "New conversation started with model: $_currentModel",
      isUser: false,
      isSystemMessage: true,
    );

    // Create a new messages list with only the system message
    final newMessages = [systemMessage];

    emit(state.copyWith(messages: newMessages, currentModel: modelName));
  }
}
