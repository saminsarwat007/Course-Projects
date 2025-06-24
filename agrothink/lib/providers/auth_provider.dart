import 'dart:io'; // Added for File type
import 'package:flutter/material.dart';
import 'package:agrothink/models/user_model.dart';
import 'package:agrothink/config/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added for FirebaseStorage

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isGovernmentUser => _user?.isGovernment ?? false;

  // Constructor
  AuthProvider() {
    // Check if user is already logged in
    checkCurrentUser();
  }

  // Check for existing user session
  Future<void> checkCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _getUserData(currentUser.uid);
        _status = AuthStatus.authenticated;
      } catch (e) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Get user data from Firestore
  Future<void> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        // Convert Firestore Timestamp to DateTime
        final createdAt = (userData['createdAt'] as Timestamp).toDate();
        final lastLogin = (userData['lastLogin'] as Timestamp).toDate();

        _user = UserModel(
          uid: uid,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          photoUrl: userData['photoUrl'] as String?, // Added photoUrl
          isGovernment: userData['isGovernment'] ?? false,
          createdAt: createdAt,
          lastLogin: lastLogin,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch user data: ${e.toString()}';
      throw e;
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check for government credentials
      if (email.contains(AppConstants.governmentEmailDomain) &&
          password == AppConstants.governmentPassword) {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update the government status to true
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
              'isGovernment': true,
              'lastLogin': FieldValue.serverTimestamp(),
            });

        await _getUserData(userCredential.user!.uid);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      // Regular sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _getUserData(userCredential.user!.uid);

      // Update last login time
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastLogin': FieldValue.serverTimestamp()},
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password';
      } else {
        _errorMessage = 'Login failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name in Firebase Auth profile
      await userCredential.user?.updateDisplayName(name);

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      // Check if this is a government email and set the flag accordingly
      final isGovernment = email.contains(AppConstants.governmentEmailDomain);

      // Store user data in Firestore
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': null, // Initialize photoUrl as null
        'isGovernment': isGovernment,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);

      // Get the data back with server timestamps
      await _getUserData(uid);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'This email is already registered';
      } else {
        _errorMessage = 'Registration failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign up: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found with this email';
      } else {
        _errorMessage = 'Password reset failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _auth.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
    }
  }

  // Clear any auth errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update User Display Name
  Future<bool> updateUserDisplayName(String newName) async {
    if (_user == null || _auth.currentUser == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _auth.currentUser!.updateDisplayName(newName);
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': newName,
      });
      // Update local user model
      _user = _user!.copyWith(name: newName);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update display name: ${e.toString()}";
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Update User Email (requires re-authentication)
  Future<bool> updateUserEmail(String newEmail, String currentPassword) async {
    if (_user == null || _auth.currentUser == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth
      await _auth.currentUser!.updateEmail(newEmail);
      // Update email in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'email': newEmail,
      });
      // Update local user model
      _user = _user!.copyWith(email: newEmail);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _errorMessage = "Incorrect current password.";
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = "This email is already in use by another account.";
      } else {
        _errorMessage = "Failed to update email: ${e.message}";
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Failed to update email: ${e.toString()}";
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Update User Profile Picture
  Future<bool> updateUserProfilePicture(File imageFile) async {
    if (_user == null || _auth.currentUser == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // Determine file extension
      final String fileExtension = imageFile.path.split('.').last;
      // Create a reference to Firebase Storage with a nested path
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_pictures') // Main directory
          .child(_user!.uid) // User-specific directory
          .child(
            'profile_picture.$fileExtension',
          ); // Standardized file name with extension

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update photoURL in Firebase Auth
      await _auth.currentUser!.updatePhotoURL(downloadUrl);
      // Update photoUrl in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'photoUrl': downloadUrl,
      });
      // Update local user model
      _user = _user!.copyWith(photoUrl: downloadUrl);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update profile picture: ${e.toString()}";
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // A private helper method to delete all user-related data from Firestore
  Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();

    // 1. Delete saved guides
    final savedGuidesQuery =
        _firestore.collection('saved_guides').where('userId', isEqualTo: uid);
    final savedGuidesSnapshot = await savedGuidesQuery.get();
    for (final doc in savedGuidesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete todos
    final todosQuery =
        _firestore.collection('todos').where('userId', isEqualTo: uid);
    final todosSnapshot = await todosQuery.get();
    for (final doc in todosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete chat messages
    final chatMessagesQuery =
        _firestore.collection('chat_messages').where('userId', isEqualTo: uid);
    final chatMessagesSnapshot = await chatMessagesQuery.get();
    for (final doc in chatMessagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete the user document itself
    final userDocRef = _firestore.collection('users').doc(uid);
    batch.delete(userDocRef);

    // Commit the batch
    await batch.commit();
  }

  // Delete User Account (requires re-authentication)
  Future<bool> deleteUserAccount(String currentPassword) async {
    if (_user == null || _auth.currentUser == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      final uid = _user!.uid;

      // Delete all user data from Firestore and other services
      await _deleteUserData(uid);

      // Delete user from Firebase Auth
      await _auth.currentUser!.delete();

      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _errorMessage = "Incorrect current password.";
      } else {
        _errorMessage = "Failed to delete account: ${e.message}";
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Failed to delete account: ${e.toString()}";
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
}
