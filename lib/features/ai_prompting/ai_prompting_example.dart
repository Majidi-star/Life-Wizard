import 'package:flutter/material.dart';
import '../ai_chat/gemini_chat_service.dart';
import 'ai_message_service.dart';
import 'message_formatter.dart';
import 'respones_handler.dart';
import 'function_executor.dart';

/// A simple example widget showing how to use the AI prompting system
class AiPromptingExample extends StatefulWidget {
  const AiPromptingExample({super.key});

  @override
  State<AiPromptingExample> createState() => _AiPromptingExampleState();
}

class _AiPromptingExampleState extends State<AiPromptingExample> {
  late final AiMessageService _aiMessageService;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String _lastFormattedMessage = '';

  @override
  void initState() {
    super.initState();
    // Create the Gemini chat service
    final chatService = createGeminiChatService();

    // Initialize the AI message service with the chat service
    _aiMessageService = AiMessageService(
      chatService: chatService,
      maxHistoryLength: 15, // Keep up to 15 messages in history
      debugMode: true, // Enable debug mode to see formatted messages
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    // Save a sample of the formatted message for debugging
    _lastFormattedMessage = MessageFormatter.formatMessageWithHistory(
      message,
      _aiMessageService.conversationHistory,
    );

    setState(() {
      _messages.add({'isUser': true, 'message': message});
      _isLoading = true;
    });

    try {
      final response = await _aiMessageService.sendMessage(message);

      setState(() {
        if (response['success'] == true) {
          // Add the raw response
          _messages.add({
            'isUser': false,
            'message': response['rawResponse'],
            'tags': response['taggedContent'],
          });

          // Print the tagged content to the console for debugging
          ResponseHandler.printTaggedContent(
            List<Map<String, String>>.from(response['taggedContent'] ?? []),
          );
        } else {
          _messages.add({
            'isUser': false,
            'isError': true,
            'message': response['error'] ?? 'An error occurred',
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'isUser': false,
          'isError': true,
          'message': 'Error: $e',
        });
        _isLoading = false;
      });
    }
  }

  // Direct test of function execution
  void _testFunctionExecution() async {
    setState(() {
      _isLoading = true;
      _messages.add({
        'isUser': true,
        'message': 'Testing direct function execution for get_all_todo_items',
      });
    });

    try {
      // Create a sample function call JSON
      const functionCall = '''
{
  "name": "get_all_todo_items",
  "parameters": {
    "filter": "all"
  }
}
''';

      debugPrint(
        "DIRECT TEST: About to execute function with content: $functionCall",
      );

      // Execute the function directly
      final result = await FunctionExecutor.executeFunction(functionCall);

      debugPrint("DIRECT TEST: Function returned result: $result");

      setState(() {
        _messages.add({
          'isUser': false,
          'message': 'Function result: $result',
          'isFunctionResult': true,
        });
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("DIRECT TEST: Error executing function: $e");
      setState(() {
        _messages.add({
          'isUser': false,
          'isError': true,
          'message': 'Error executing function: $e',
        });
        _isLoading = false;
      });
    }
  }

  void _showConversationContext() {
    final history = _aiMessageService.conversationHistory;
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conversation Context',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Messages in history: ${history.length}'),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            history.map((msg) {
                              final isUser = msg['isUser'] == true;
                              final content = msg['message'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  '${isUser ? "User" : "Assistant"}: $content',
                                  style: TextStyle(
                                    fontWeight:
                                        isUser
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showFormattedMessage() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formatted Message',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'This is how messages are formatted before sending to the AI:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _lastFormattedMessage.isEmpty
                              ? 'Send a message first to see its formatting'
                              : _lastFormattedMessage,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showLastExchange() {
    final exchange = _aiMessageService.lastExchange;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Message Exchange',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Sent message section
                  const Text(
                    'Sent to AI:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        exchange['sent'] ?? 'No message sent yet',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Received response section
                  const Text(
                    'Received from AI:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        exchange['received'] ?? 'No response received yet',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prompting Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'View last exchange',
            onPressed: _showLastExchange,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View formatted message',
            onPressed: _showFormattedMessage,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View conversation history',
            onPressed: _showConversationContext,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear conversation',
            onPressed: () {
              setState(() {
                _aiMessageService.clearConversation();
                _messages.clear();
                _lastFormattedMessage = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.functions),
            onPressed: _testFunctionExecution,
            tooltip: 'Test function execution',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageWidget(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Send a message',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(Map<String, dynamic> message) {
    final isUser = message['isUser'] ?? false;
    final isError = message['isError'] ?? false;
    final text = message['message'] ?? '';
    final tags = message['tags'] as List<Map<String, String>>? ?? [];

    if (isUser) {
      return _buildUserMessage(text);
    } else if (isError) {
      return _buildErrorMessage(text);
    } else {
      return _buildAiMessage(text, tags);
    }
  }

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildAiMessage(String text, List<Map<String, String>> tags) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text('Tagged Content:'),
              ...tags.map((tag) => _buildTagWidget(tag)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagWidget(Map<String, String> tag) {
    final tagName = tag['tag_name'] ?? '';
    final content = tag['content'] ?? '';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag: <$tagName>',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String text) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
      ),
    );
  }
}
