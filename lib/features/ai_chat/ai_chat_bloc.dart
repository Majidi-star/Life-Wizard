// AI Chat BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'ai_chat_widgets.dart';
import 'gemini_chat_service.dart';
import '../../main.dart' as app_main;

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  late final GeminiChatService _geminiService;

  AIChatBloc() : super(const AIChatState()) {
    _geminiService = createGeminiChatService();
    on<SendMessage>(_onSendMessage);
    on<ClearMessages>(_onClearMessages);
  }

  void _onSendMessage(SendMessage event, Emitter<AIChatState> emit) async {
    // Add user message to the state
    final userMessage = ChatMessage(text: event.message, isUser: true);

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    try {
      // Check if Gemini API key is set
      final apiKey = app_main.settingsBloc.state.geminiApiKey;
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

      // Update API key if it has changed
      if (_geminiService.apiKey != apiKey) {
        await _geminiService.updateApiKey(apiKey);
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
      emit(state.copyWith(messages: messagesWithResponse, isLoading: false));
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

  void _onClearMessages(ClearMessages event, Emitter<AIChatState> emit) {
    emit(state.copyWith(messages: []));
  }
}
