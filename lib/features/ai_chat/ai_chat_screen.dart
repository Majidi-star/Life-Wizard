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
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late AIChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = AIChatBloc();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatBloc.close();
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
              _chatBloc.add(const ClearMessages());
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: BlocProvider(
                create: (context) => _chatBloc,
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
            ),
            BlocBuilder<AIChatBloc, AIChatState>(
              bloc: _chatBloc,
              builder: (context, state) {
                return ChatInputField(
                  onSendMessage: (text) {
                    _chatBloc.add(SendMessage(text));
                  },
                  isLoading: state.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
