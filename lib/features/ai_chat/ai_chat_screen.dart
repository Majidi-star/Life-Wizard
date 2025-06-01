import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import 'ai_chat_widgets.dart';
import 'ai_chat_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'gemini_chat_service.dart';
import '../../main.dart' as app_main;

/// The AI Chat Screen which displays the chat interface
/// This screen follows the BLoC pattern by:
/// 1. Creating and providing the BLoC
/// 2. Dispatching events to the BLoC
/// 3. Rebuilding UI based on state changes
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;
    final bool hasApiKey = settingsState.geminiApiKey.isNotEmpty;

    return BlocProvider.value(
      // Use the global bloc instance
      value: app_main.aiChatBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
          title: BlocBuilder<AIChatBloc, AIChatState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Chat'),
                  if (hasApiKey)
                    Text(
                      'Using: ${state.currentModel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                ],
              );
            },
          ),
          backgroundColor: ThemeUtils.getAppBarColor(context),
          actions: [
            // New conversation button
            BlocBuilder<AIChatBloc, AIChatState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Start New Conversation',
                  onPressed:
                      () => context.read<AIChatBloc>().add(
                        StartNewConversation(),
                      ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.functions),
              tooltip: 'Function Test',
              onPressed: () {
                Navigator.pushNamed(context, '/function_test');
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Warning bar if API key is not set
              if (!hasApiKey)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber[100],
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please set your Gemini API key in the settings to use the AI chat feature.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to settings
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        },
                        child: const Text('GO TO SETTINGS'),
                      ),
                    ],
                  ),
                ),

              // Chat messages list
              Expanded(
                child: BlocConsumer<AIChatBloc, AIChatState>(
                  listener: (context, state) {
                    // Auto-scroll to bottom when a new message is added
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  },
                  builder: (context, state) {
                    return ChatMessageList(
                      messages: state.messages,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),

              // Chat input field
              BlocBuilder<AIChatBloc, AIChatState>(
                builder: (context, state) {
                  return ChatInputField(
                    onSendMessage: (text) {
                      // Dispatch SendMessage event to BLoC
                      context.read<AIChatBloc>().add(SendMessage(text));
                    },
                    isLoading: state.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
