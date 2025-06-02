import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter/services.dart'; // For clipboard
import 'package:markdown/markdown.dart' as md;
import 'markdown_code_block.dart'; // Import our custom code block builder

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
    final isFunctionCallMessage = message.isFunctionCallMessage;

    // For system messages with function calls, use a special style
    if (isFunctionCallMessage && message.functionCalls.isNotEmpty) {
      final functionCall = message.functionCalls.first;
      final success = functionCall.success;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    success
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: success ? Colors.green.shade300 : Colors.red.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.cancel,
                    color: success ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Function: ${message.text}",
                    style: TextStyle(
                      color:
                          success ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    success ? "Executed" : "Failed",
                    style: TextStyle(
                      color:
                          success ? Colors.green.shade600 : Colors.red.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For regular system messages, use the existing style
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

    // For regular user and AI messages
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _buildAvatar(context),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isUser
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    isUser
                        ? Text(
                          message.text,
                          style: TextStyle(color: Colors.white),
                        )
                        : _buildMarkdownContent(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isUser) _buildAvatar(context, isUser: true),
      ],
    );
  }

  /// Build a markdown widget for AI responses
  Widget _buildMarkdownContent(BuildContext context) {
    final theme = Theme.of(context);

    return MarkdownBody(
      data: message.text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: theme.colorScheme.onSurface),
        h1: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        h2: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        h3: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        code: TextStyle(
          backgroundColor: theme.colorScheme.surfaceVariant,
          color: theme.colorScheme.secondary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.surfaceVariant, width: 1),
        ),
        blockquote: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.secondary, width: 4),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16.0),
        listBullet: TextStyle(color: theme.colorScheme.secondary),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
    );
  }

  /// Launch URLs when tapped in markdown
  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      await url_launcher.launchUrl(
        url,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
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

/// Function call result information
class FunctionCallResult {
  final String name;
  final bool success;

  FunctionCallResult({required this.name, required this.success});
}

/// Model class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSystemMessage;
  final List<FunctionCallResult> functionCalls;
  final bool isFunctionCallMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isSystemMessage = false,
    this.functionCalls = const [],
    this.isFunctionCallMessage = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
