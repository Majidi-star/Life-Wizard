import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import 'ai_chat_widgets.dart';
import 'ai_chat_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import '../../main.dart' as app_main;

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Wait for the UI to update
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AIChatBloc, AIChatState>(
      bloc: app_main.aiChatBloc,
      listener: (context, state) {
        // Scroll to bottom whenever messages change
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            title: const Text('AI Chat'),
            backgroundColor: ThemeUtils.getAppBarColor(context),
            actions: [
              // New chat button
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  app_main.aiChatBloc.add(const ClearMessages());
                },
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                // Chat messages list
                Expanded(
                  child: ChatMessageList(
                    messages: state.messages,
                    scrollController: _scrollController,
                  ),
                ),

                // Input field and send button
                ChatInputField(
                  onSendMessage: (message) {
                    app_main.aiChatBloc.add(SendMessage(message));
                  },
                  isLoading: state.isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
