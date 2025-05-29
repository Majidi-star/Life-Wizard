// AI Chat Event file

import 'package:equatable/equatable.dart';

abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object> get props => [];
}

class SendMessage extends AIChatEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
}

class ClearMessages extends AIChatEvent {
  const ClearMessages();
}
