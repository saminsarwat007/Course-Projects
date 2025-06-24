import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/models/user_model.dart';
import 'package:agrothink/providers/auth_provider.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthProvider? _authProvider;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AdminProvider(this._authProvider) {
    if (_authProvider?.user != null && _authProvider!.user!.isGovernment) {
      fetchAllUsers();
    }
  }

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (_authProvider?.user != null && _authProvider!.user!.isGovernment) {
      fetchAllUsers();
    } else {
      _users = [];
      notifyListeners();
    }
  }

  Future<void> fetchAllUsers() async {
    if (_authProvider?.user == null || !_authProvider!.user!.isGovernment) {
      _users = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs.map((doc) {
        try {
          return UserModel.fromMap(doc.data());
        } catch (e) {
          print('Failed to parse user document ${doc.id}: $e');
          return null;
        }
      }).whereType<UserModel>().where((user) => user.uid != _authProvider?.user?.uid) // Exclude self
          .toList();
    } catch (e) {
      print('Error fetching users collection: $e');
      // You might want to set an error state here
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    // This is a placeholder for now.
    // Deleting a Firebase Auth user requires a backend function for security.
    // For now, we can demonstrate by just deleting the Firestore record.
    try {
      await _firestore.collection('users').doc(userId).delete();
      _users.removeWhere((user) => user.uid == userId);
      notifyListeners();
    } catch (e) {
      print('Error deleting user from Firestore: $e');
      // Handle error appropriately
    }
  }
} 