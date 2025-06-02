// AI Chat BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';
import 'ai_chat_widgets.dart';
import 'gemini_chat_service.dart';
import '../ai_prompting/ai_message_service.dart';
import '../../main.dart' as app_main;
import 'package:flutter/foundation.dart';

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final GeminiChatService _geminiService;
  final AiMessageService _aiMessageService;
  String _currentModel = '';

  // Constructor using dependency injection pattern
  AIChatBloc({GeminiChatService? geminiService})
    : _geminiService = geminiService ?? createGeminiChatService(),
      _aiMessageService = AiMessageService(
        chatService: geminiService ?? createGeminiChatService(),
      ),
      super(const AIChatState()) {
    // Initialize the current model
    _currentModel = app_main.settingsBloc.state.geminiModel;

    // Listen for settings changes to update the model
    app_main.settingsBloc.stream.listen((settings) {
      if (settings.geminiModel != _currentModel) {
        _currentModel = settings.geminiModel;
        _geminiService.updateModel(_currentModel);
        add(
          StartNewConversation(),
        ); // Optionally start a new conversation when model changes
      }
    });

    on<SendMessage>(_onSendMessage);
    on<ClearMessages>(_onClearMessages);
    on<StartNewConversation>(_onStartNewConversation);
  }

  /// Handle the SendMessage event by sending a message to Gemini API
  void _onSendMessage(SendMessage event, Emitter<AIChatState> emit) async {
    // Add user message to the state
    final userMessage = ChatMessage(text: event.message, isUser: true);

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    try {
      // Check if Gemini API key is set
      final settings = app_main.settingsBloc.state;
      final apiKey = settings.geminiApiKey;
      final modelName = settings.geminiModel;

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

      // Update API key or model if they have changed
      if (_geminiService.apiKey != apiKey || _currentModel != modelName) {
        await _geminiService.updateApiKey(apiKey, newModel: modelName);
        _currentModel = modelName;
      }

      // Get AI response using AI Message Service
      final response = await _aiMessageService.sendMessage(event.message);
      final rawResponse = response['rawResponse'] as String?;

      // Extract function call results with proper type handling
      final functionCallResultsRaw = response['functionCallResults'];
      List<FunctionCallResult> functionCallResults = [];

      if (functionCallResultsRaw != null) {
        // Handle the case where functionCallResults might be a List<dynamic>
        if (functionCallResultsRaw is List) {
          for (var item in functionCallResultsRaw) {
            if (item is FunctionCallResult) {
              functionCallResults.add(item);
            } else if (item is Map) {
              // Try to convert from Map to FunctionCallResult
              try {
                final name = item['name']?.toString() ?? 'Unknown Function';
                final success = item['success'] == true;
                functionCallResults.add(
                  FunctionCallResult(name: name, success: success),
                );
              } catch (e) {
                debugPrint('Error converting function call result: $e');
              }
            }
          }
        }
      }

      // Ensure we have at least one function call result if a function was executed
      if (functionCallResults.isEmpty && response['functionResult'] != null) {
        // Extract function name using regex as fallback
        String functionName = 'Function Call';
        final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
        final match = nameRegex.firstMatch(
          response['functionResult'].toString(),
        );
        if (match != null && match.groupCount >= 1) {
          functionName = match.group(1) ?? 'Function Call';
        }

        functionCallResults.add(
          FunctionCallResult(name: functionName, success: true),
        );
      }

      debugPrint('Function calls to display: ${functionCallResults.length}');

      // Add AI response to the state
      final aiMessage = ChatMessage(
        text: rawResponse ?? "Sorry, I couldn't generate a response.",
        isUser: false,
      );

      // Create a list with the AI message and then add function call messages
      final messagesWithResponse = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);

      // Now add separate messages for each function call
      for (var functionCall in functionCallResults) {
        messagesWithResponse.add(
          ChatMessage(
            text: functionCall.name,
            isUser: false,
            isSystemMessage: true,
            isFunctionCallMessage: true,
            functionCalls: [functionCall],
          ),
        );
      }

      emit(
        state.copyWith(
          messages: messagesWithResponse,
          isLoading: false,
          currentModel: modelName,
        ),
      );
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

  /// Handle the ClearMessages event by clearing the chat history
  void _onClearMessages(ClearMessages event, Emitter<AIChatState> emit) {
    // Clear conversation history in both services
    _geminiService.clearConversation();
    _aiMessageService.clearConversation();

    // Clear messages in the state
    emit(state.copyWith(messages: []));
  }

  /// Handle the StartNewConversation event by clearing history and starting a new conversation
  void _onStartNewConversation(
    StartNewConversation event,
    Emitter<AIChatState> emit,
  ) {
    // Clear conversation history in both services
    _geminiService.clearConversation();
    _aiMessageService.clearConversation();

    // Update state to indicate a new conversation has started
    final modelName = app_main.settingsBloc.state.geminiModel;
    _currentModel = modelName;

    // Clear all previous messages and add a system message
    final systemMessage = ChatMessage(
      text: "New conversation started with model: $_currentModel",
      isUser: false,
      isSystemMessage: true,
    );

    // Create a new messages list with only the system message
    final newMessages = [systemMessage];

    emit(state.copyWith(messages: newMessages, currentModel: modelName));
  }
}
