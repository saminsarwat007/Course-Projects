import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsType { foodPrice, weatherWarning, agriculturalNews }

class NewsModel {
  final String id;
  final String title;
  final String content;
  final NewsType type;
  final DateTime publishedDate;
  final String publishedBy;
  final Map<String, dynamic>? additionalData;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.publishedDate,
    required this.publishedBy,
    this.additionalData,
  });

  // Create a news item from Firebase data
  factory NewsModel.fromMap(Map<String, dynamic> map, String id) {
    return NewsModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: _getNewsTypeFromString(map['type'] ?? 'agriculturalNews'),
      publishedDate:
          map['publishedDate'] != null
              ? (map['publishedDate'] as Timestamp).toDate()
              : DateTime.now(),
      publishedBy: map['publishedBy'] ?? 'System',
      additionalData: map['additionalData'],
    );
  }

  // Convert news item to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      //'id': id, // ID is now the document ID, not stored in the map
      'title': title,
      'content': content,
      'type': _getStringFromNewsType(type),
      'publishedDate': publishedDate,
      'publishedBy': publishedBy,
      'additionalData': additionalData,
    };
  }

  // Helper method to get NewsType from string
  static NewsType _getNewsTypeFromString(String typeString) {
    switch (typeString) {
      case 'foodPrice':
        return NewsType.foodPrice;
      case 'weatherWarning':
        return NewsType.weatherWarning;
      case 'agriculturalNews':
      default:
        return NewsType.agriculturalNews;
    }
  }

  // Helper method to get string from NewsType
  static String _getStringFromNewsType(NewsType type) {
    switch (type) {
      case NewsType.foodPrice:
        return 'foodPrice';
      case NewsType.weatherWarning:
        return 'weatherWarning';
      case NewsType.agriculturalNews:
        return 'agriculturalNews';
    }
  }

  // Get color based on news type
  Color getTypeColor() {
    switch (type) {
      case NewsType.foodPrice:
        return Colors.orange;
      case NewsType.weatherWarning:
        return Colors.red;
      case NewsType.agriculturalNews:
        return Colors.green;
    }
  }

  // Get icon based on news type
  IconData getTypeIcon() {
    switch (type) {
      case NewsType.foodPrice:
        return Icons.attach_money;
      case NewsType.weatherWarning:
        return Icons.warning_amber;
      case NewsType.agriculturalNews:
        return Icons.article;
    }
  }
}
