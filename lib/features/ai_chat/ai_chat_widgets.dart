import 'package:flutter/material.dart';

/// Widget to display the chat conversation
class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatMessageList({
    Key? key,
    required this.messages,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Start a conversation by typing a message below',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MessageBubble(message: message),
        );
      },
    );
  }
}

/// Widget for the chat input field and send button
class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInputField({
    Key? key,
    required this.onSendMessage,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    widget.onSendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? theme.colorScheme.primary : theme.colorScheme.background;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.surfaceTint.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.surfaceTint.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.secondary,
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _handleSubmit(),
              enabled: !widget.isLoading,
            ),
          ),
          const SizedBox(width: 8),
          SendButton(onPressed: _handleSubmit, isLoading: widget.isLoading),
        ],
      ),
    );
  }
}

/// Send button widget with loading state
class SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SendButton({Key? key, required this.onPressed, this.isLoading = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? theme.colorScheme.primary : theme.colorScheme.background;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: const Color.fromARGB(255, 255, 255, 255),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
          ),
        ),
      ),
    );
  }
}

/// Message bubble to display user and AI messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isSystemMessage = message.isSystemMessage;

    // For system messages, use a different style
    if (isSystemMessage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _buildAvatar(context),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isUser) _buildAvatar(context, isUser: true),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.tertiaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color:
            isUser
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onTertiaryContainer,
        size: 20,
      ),
    );
  }
}

/// Model class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSystemMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isSystemMessage = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
