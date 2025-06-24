import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItemModel {
  final String id;
  final String userId;
  final String title;
  final DateTime dueDate;
  bool isCompleted;
  final String? relatedGuideId;

  TodoItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    this.relatedGuideId,
  });

  factory TodoItemModel.fromMap(Map<String, dynamic> map, String id) {
    if (map['userId'] == null || (map['userId'] as String).isEmpty) {
      throw FormatException('Todo item $id is missing a valid userId.');
    }
    if (map['title'] == null) {
      throw FormatException('Todo item $id is missing a title.');
    }
    if (map['dueDate'] == null || map['dueDate'] is! Timestamp) {
      throw FormatException('Todo item $id is missing a valid dueDate.');
    }

    return TodoItemModel(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      relatedGuideId: map['relatedGuideId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'relatedGuideId': relatedGuideId,
    };
  }
} 