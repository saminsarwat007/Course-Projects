import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

enum MessageSender { user, bot }

class ChatbotMessageModel {
  final String id;
  final String userId; // Added userId
  final String message;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isRead;

  ChatbotMessageModel({
    required this.id,
    required this.userId, // Added userId
    required this.message,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  });

  // Create a message from Firebase data
  factory ChatbotMessageModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ChatbotMessageModel(
      id: documentId, // Use Firestore document ID
      userId: map['userId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.bot,
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(), // Corrected Timestamp parsing
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  // Convert message to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // ID will be the document ID, not stored as a field in the map
      'userId': userId,
      'message': message,
      'sender': sender == MessageSender.user ? 'user' : 'bot',
      'timestamp':
          FieldValue.serverTimestamp(), // Use server timestamp for consistency
      'isRead': isRead,
    };
  }

  // Create a new user message
  factory ChatbotMessageModel.userMessage({
    required String message,
    required String userId,
  }) {
    return ChatbotMessageModel(
      id:
          DateTime.now().millisecondsSinceEpoch
              .toString(), // Temporary ID, Firestore ID will be definitive
      userId: userId,
      message: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(), // Will be replaced by server timestamp on save
      isRead: true,
    );
  }

  // Create a new bot message
  factory ChatbotMessageModel.botMessage({
    required String message,
    required String userId,
  }) {
    return ChatbotMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      userId: userId,
      message: message,
      sender: MessageSender.bot,
      timestamp: DateTime.now(), // Will be replaced by server timestamp on save
      isRead:
          false, // Bot messages are initially unread by user UI logic perhaps
    );
  }

  // Create a copy with updated fields
  ChatbotMessageModel copyWith({
    String? id,
    String? userId,
    String? message,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatbotMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
