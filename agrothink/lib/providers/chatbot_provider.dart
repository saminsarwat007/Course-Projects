import 'package:flutter/material.dart';
import 'package:agrothink/models/chatbot_message_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatbotStatus { initial, loading, ready, sending, receiving, error }

class ChatbotProvider extends ChangeNotifier {
  ChatbotStatus _status = ChatbotStatus.initial;
  List<ChatbotMessageModel> _messages = [];
  String? _errorMessage;
  bool _isTyping = false;

  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gemini Model
  final _gemini = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyC1iVm3TcG4Hva7kgVBIDO36NYxKIBFy0w',
    safetySettings: [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ],
    generationConfig: GenerationConfig(temperature: 0.8),
  );
  late ChatSession _chat;

  // Getters
  ChatbotStatus get status => _status;
  List<ChatbotMessageModel> get messages => _messages;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;

  // Constructor
  ChatbotProvider(this._userId) {
    _chat = _gemini.startChat(
      history: [
        Content.model([
          TextPart(
            "You are an expert AI Agriculture Assistant for the Agrothink app. Your goal is to provide helpful and concise advice to farmers. Focus on practical tips for crop management, pest control, soil health, irrigation, and identifying plant diseases based on descriptions. If a user asks a question outside of agriculture, politely decline to answer and steer the conversation back to farming topics. Keep your responses informative and easy to understand.",
          ),
        ]),
        Content.text(
          "Okay, I understand my role. I will assist users with their farming questions.",
        ),
      ],
    );
    _loadMessages();
  }

  // Load messages from Firestore for the current user
  Future<void> _loadMessages() async {
    if (_userId == null) {
      _status = ChatbotStatus.ready;
      _addWelcomeMessageIfNeededLocally();
      notifyListeners();
      return;
    }

    _status = ChatbotStatus.loading;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('chat_messages')
              .where('userId', isEqualTo: _userId)
              .orderBy('timestamp', descending: false)
              .get();

      _messages =
          snapshot.docs
              .map(
                (doc) => ChatbotMessageModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      _addWelcomeMessageIfNeededLocally();

      _status = ChatbotStatus.ready;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load chat history: ${e.toString()}';
      _status = ChatbotStatus.error;
      notifyListeners();
    }
  }

  void _addWelcomeMessageIfNeededLocally() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatbotMessageModel.botMessage(
          message:
              'Hello! I am your AI Agriculture Assistant. How can I help you today? You can ask me about crop management, pest control, soil health, or any other farming-related questions.',
          userId: _userId ?? 'guest',
        ),
      );
    }
  }

  // Initialize chatbot - original _initializeChatbot is now split into constructor and _loadMessages
  // This method is kept for clearChat to call, ensuring _chat is re-initialized.
  void _reInitializeChatSessionOnly() {
    _chat = _gemini.startChat(
      history: [
        Content.model([
          TextPart(
            "You are an expert AI Agriculture Assistant for the Agrothink app. Your goal is to provide helpful and concise advice to farmers. Focus on practical tips for crop management, pest control, soil health, irrigation, and identifying plant diseases based on descriptions. If a user asks a question outside of agriculture, politely decline to answer and steer the conversation back to farming topics. Keep your responses informative and easy to understand.",
          ),
        ]),
        Content.text(
          "Okay, I understand my role. I will assist users with their farming questions.",
        ),
      ],
    );
  }

  // Send a message to the chatbot
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (_userId == null) {
      _errorMessage = "User not logged in. Cannot send message.";
      _status = ChatbotStatus.error;
      notifyListeners();
      return;
    }

    // 1. Add user message and save to Firestore
    final userMessage = ChatbotMessageModel.userMessage(
      message: message,
      userId: _userId!,
    );
    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      await _firestore.collection('chat_messages').add(userMessage.toMap());
    } catch (e) {
      _errorMessage = 'Failed to save your message: ${e.toString()}';
      _status = ChatbotStatus.error;
      _isTyping = false;
      notifyListeners();
      return;
    }

    // 2. Add empty bot message to start streaming into
    final botMessage = ChatbotMessageModel.botMessage(
      message: '',
      userId: _userId!,
    );
    _messages.add(botMessage);

    try {
      // 3. Stream the response from Gemini
      final stream = _chat.sendMessageStream(Content.text(message));

      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null) {
          // Create a new message model with the updated text
          _messages.last = _messages.last.copyWith(
            message: _messages.last.message + text,
          );
          notifyListeners();
        }
      }

      // 4. Once streaming is complete, save the final message to Firestore
      await _firestore.collection('chat_messages').add(_messages.last.toMap());
    } catch (e) {
      _messages.last = _messages.last.copyWith(
        message: 'Failed to get AI response: ${e.toString()}',
      );
      _status = ChatbotStatus.error;
    } finally {
      _isTyping = false;
      _status = ChatbotStatus.ready;
      notifyListeners();
    }
  }

  // Clear chat history for the current user
  Future<void> clearChat() async {
    if (_userId == null) {
      _messages.clear(); // Clear local messages if no user
      _addWelcomeMessageIfNeededLocally();
      notifyListeners();
      return;
    }

    _status = ChatbotStatus.loading;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('chat_messages')
              .where('userId', isEqualTo: _userId)
              .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _messages.clear();
      _reInitializeChatSessionOnly(); // Re-initialize Gemini session state
      _addWelcomeMessageIfNeededLocally(); // Add welcome message back
      _status = ChatbotStatus.ready;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear chat history: ${e.toString()}';
      _status = ChatbotStatus.error;
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _errorMessage = null;
    // Optionally set status back to ready if it was error
    if (_status == ChatbotStatus.error) _status = ChatbotStatus.ready;
    notifyListeners();
  }
}
