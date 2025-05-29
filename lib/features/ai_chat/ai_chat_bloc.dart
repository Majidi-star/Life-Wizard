// AI Chat BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'ai_chat_widgets.dart';

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  AIChatBloc() : super(const AIChatState()) {
    on<SendMessage>(_onSendMessage);
    on<ClearMessages>(_onClearMessages);
  }

  void _onSendMessage(SendMessage event, Emitter<AIChatState> emit) async {
    // Add user message to the state
    final userMessage = ChatMessage(text: event.message, isUser: true);

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    // Simulate AI response
    await Future.delayed(const Duration(seconds: 1));

    // Add AI response to the state
    final aiMessage = ChatMessage(
      text: "This is a simulated AI response to: ${event.message}",
      isUser: false,
    );

    final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
      ..add(aiMessage);
    emit(state.copyWith(messages: messagesWithResponse, isLoading: false));
  }

  void _onClearMessages(ClearMessages event, Emitter<AIChatState> emit) {
    emit(state.copyWith(messages: []));
  }
}
