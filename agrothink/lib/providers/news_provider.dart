import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/models/news_model.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'dart:async';

enum NewsLoadingStatus { initial, loading, loaded, error }

class NewsProvider extends ChangeNotifier {
  NewsLoadingStatus _status = NewsLoadingStatus.initial;
  List<NewsModel> _news = [];
  String? _errorMessage;
  StreamSubscription? _newsSubscription;
  AuthProvider? _authProvider;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  NewsLoadingStatus get status => _status;
  List<NewsModel> get news => _news;
  String? get errorMessage => _errorMessage;

  // Filter by type
  List<NewsModel> getNewsByType(NewsType type) {
    return _news.where((item) => item.type == type).toList();
  }

  // Constructor
  NewsProvider() {
    fetchNews();
  }

  void updateAuth(AuthProvider authProvider) {
    // This provider no longer needs to be auth-aware,
    // as news is considered public content.
    // The link can be kept if some news items become user-specific in the future.
    _authProvider = authProvider;
  }

  @override
  void dispose() {
    _newsSubscription?.cancel();
    super.dispose();
  }

  // Fetch all news
  void fetchNews() {
    _status = NewsLoadingStatus.loading;
    notifyListeners();

    _newsSubscription?.cancel();
    _newsSubscription = _firestore
        .collection('news')
        .orderBy('publishedDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      _news = snapshot.docs
          .map((doc) =>
              NewsModel.fromMap(doc.data(), doc.id))
          .toList();
      _status = NewsLoadingStatus.loaded;
      notifyListeners();
    }, onError: (error) {
      _status = NewsLoadingStatus.error;
      _errorMessage = 'Failed to load news: ${error.toString()}';
      notifyListeners();
    });
  }

  // Add a new news item (for government users)
  Future<bool> addNews(NewsModel newsItem) async {
    try {
      await _firestore.collection('news').add(newsItem.toMap());
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add news: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Delete a news item (for government users)
  Future<bool> deleteNews(String newsId) async {
    try {
      await _firestore.collection('news').doc(newsId).delete();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete news: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear any errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
