import 'package:cloud_firestore/cloud_firestore.dart';

class SavedGuideModel {
  final String? id;
  final String userId;
  final String seedName;
  final String guide;
  final DateTime createdAt;

  SavedGuideModel({
    this.id,
    required this.userId,
    required this.seedName,
    required this.guide,
    required this.createdAt,
  });

  factory SavedGuideModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedGuideModel(
      id: id,
      userId: map['userId'] ?? '',
      seedName: map['seedName'] ?? '',
      guide: map['guide'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'seedName': seedName,
      'guide': guide,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 