// AI Chat State file

import 'package:equatable/equatable.dart';
import 'ai_chat_widgets.dart';

class AIChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String currentModel;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentModel = 'gemini-pro',
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? currentModel,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentModel: currentModel ?? this.currentModel,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, currentModel];
}
