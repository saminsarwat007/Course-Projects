import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/models/saved_guide_model.dart';
import 'package:agrothink/providers/auth_provider.dart';

class SavedGuidesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider? _authProvider;
  StreamSubscription? _guidesSubscription;

  List<SavedGuideModel> _guides = [];
  List<SavedGuideModel> get guides => _guides;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SavedGuidesProvider(this._authProvider) {
    if (_authProvider?.user != null) {
      fetchGuides();
    }
  }

  void fetchGuides() {
    if (_authProvider?.user == null) return;
    _isLoading = true;
    notifyListeners();

    _guidesSubscription?.cancel();
    _guidesSubscription = _firestore
        .collection('saved_guides')
        .where('userId', isEqualTo: _authProvider!.user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _guides = snapshot.docs
          .map((doc) => SavedGuideModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> deleteGuide(String guideId) async {
    if (_authProvider?.user == null) return;

    final WriteBatch batch = _firestore.batch();

    // 1. Delete the guide itself
    final guideRef = _firestore.collection('saved_guides').doc(guideId);
    batch.delete(guideRef);

    // 2. Find and delete all related todos
    final todosQuery = _firestore
        .collection('todos')
        .where('userId', isEqualTo: _authProvider!.user!.uid)
        .where('relatedGuideId', isEqualTo: guideId);

    final todosSnapshot = await todosQuery.get();
    for (final doc in todosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Commit the batch
    await batch.commit();
  }

  @override
  void dispose() {
    _guidesSubscription?.cancel();
    super.dispose();
  }
} 