// AI Chat BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'ai_chat_widgets.dart';
import 'gemini_chat_service.dart';
import '../../main.dart' as app_main;

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final GeminiChatService _geminiService;
  String _currentModel = '';

  // Constructor using dependency injection pattern
  AIChatBloc({GeminiChatService? geminiService})
    : _geminiService = geminiService ?? createGeminiChatService(),
      super(const AIChatState()) {
    // Initialize the current model
    _currentModel = app_main.settingsBloc.state.geminiModel;

    on<SendMessage>(_onSendMessage);
    on<ClearMessages>(_onClearMessages);
    on<StartNewConversation>(_onStartNewConversation);
  }

  /// Handle the SendMessage event by sending a message to Gemini API
  void _onSendMessage(SendMessage event, Emitter<AIChatState> emit) async {
    // Add user message to the state
    final userMessage = ChatMessage(text: event.message, isUser: true);

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    try {
      // Check if Gemini API key is set
      final settings = app_main.settingsBloc.state;
      final apiKey = settings.geminiApiKey;
      final modelName = settings.geminiModel;

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

      // Update API key or model if they have changed
      if (_geminiService.apiKey != apiKey || _currentModel != modelName) {
        await _geminiService.updateApiKey(apiKey, newModel: modelName);
        _currentModel = modelName;
      }

      // Get AI response
      final response = await _geminiService.sendMessage(event.message);

      // Add AI response to the state
      final aiMessage = ChatMessage(
        text: response ?? "Sorry, I couldn't generate a response.",
        isUser: false,
      );

      final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);
      emit(
        state.copyWith(
          messages: messagesWithResponse,
          isLoading: false,
          currentModel: modelName,
        ),
      );
    } catch (e) {
      // Handle error
      final aiMessage = ChatMessage(
        text: "Error: ${e.toString()}",
        isUser: false,
      );

      final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);
      emit(state.copyWith(messages: messagesWithResponse, isLoading: false));
    }
  }

  /// Handle the ClearMessages event by clearing the chat history
  void _onClearMessages(ClearMessages event, Emitter<AIChatState> emit) {
    // Clear conversation history in the Gemini service
    _geminiService.clearConversation();

    // Clear messages in the state
    emit(state.copyWith(messages: []));
  }

  /// Handle the StartNewConversation event by keeping history but starting a new conversation
  void _onStartNewConversation(
    StartNewConversation event,
    Emitter<AIChatState> emit,
  ) {
    // Clear conversation history in the Gemini service but keep the UI history
    _geminiService.clearConversation();

    // Update state to indicate a new conversation has started
    final modelName = app_main.settingsBloc.state.geminiModel;
    _currentModel = modelName;

    // Add a system message to indicate a new conversation has started
    final systemMessage = ChatMessage(
      text: "Starting a new conversation with model: $_currentModel",
      isUser: false,
      isSystemMessage: true,
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(systemMessage);

    emit(state.copyWith(messages: updatedMessages, currentModel: modelName));
  }
}
