import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/models/todo_item_model.dart';
import 'package:agrothink/models/saved_guide_model.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum TodoGenerationStatus { initial, loading, success, error }

class TodoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _gemini = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyC1iVm3TcG4Hva7kgVBIDO36NYxKIBFy0w',
  );
  final AuthProvider? _authProvider;
  StreamSubscription? _todoSubscription;

  List<TodoItemModel> _todos = [];
  List<TodoItemModel> get todos => _todos;

  List<TodoItemModel> get filteredTodos {
    if (_selectedGuideId == null) {
      return _todos;
    }
    return _todos
        .where((todo) =>
            todo.relatedGuideId == _selectedGuideId ||
            todo.relatedGuideId == null)
        .toList();
  }

  String? _selectedGuideId;
  String? get selectedGuideId => _selectedGuideId;

  List<TodoItemModel> _generatedTasks = [];
  List<TodoItemModel> get generatedTasks => _generatedTasks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TodoGenerationStatus _generationStatus = TodoGenerationStatus.initial;
  TodoGenerationStatus get generationStatus => _generationStatus;
  String? _generationError;
  String? get generationError => _generationError;

  TodoProvider(this._authProvider) {
    if (_authProvider?.user != null) {
      fetchTodos();
    }
  }

  void fetchTodos() {
    if (_authProvider?.user == null) return;
    _isLoading = true;
    notifyListeners();

    _todoSubscription?.cancel();
    _todoSubscription = _firestore
        .collection('todos')
        .where('userId', isEqualTo: _authProvider!.user!.uid)
        // .orderBy('dueDate', descending: false)
        .snapshots()
        .listen((snapshot) {
      try {
        _todos = snapshot.docs.map((doc) {
          try {
            return TodoItemModel.fromMap(doc.data(), doc.id);
          } catch (e) {
            print('Error parsing todo item ${doc.id}: $e');
            return null;
          }
        }).whereType<TodoItemModel>().toList();
      } catch (e) {
        print('Error processing todos list: $e');
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print('Error fetching todos: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> generateTodosFromGuide(SavedGuideModel guide) async {
    if (_authProvider?.user == null) return;

    _generationStatus = TodoGenerationStatus.loading;
    _generatedTasks = [];
    notifyListeners();

    final prompt =
        'Given the following planting guide for "${guide.seedName}", create a structured to-do list for a farmer. The guide content is: ${guide.guide}. Respond ONLY in JSON format, as an array of objects. Each object must have exactly two keys: "title" (a string describing the task) and "due_date_offset_days" (an integer representing how many days from the start of planting this task should be due). Base the timings on the guide\'s timeline and tasks.';

    try {
      final response = await _gemini.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Received no response from AI.');
      }

      final cleanedJson =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decodedList = jsonDecode(cleanedJson) as List;

      final today = DateTime.now();
      _generatedTasks = decodedList.map((taskData) {
        return TodoItemModel(
          id: '',
          userId: _authProvider!.user!.uid,
          title: taskData['title'] ?? 'Untitled Task',
          dueDate: today.add(Duration(days: taskData['due_date_offset_days'] ?? 0)),
          relatedGuideId: guide.id,
        );
      }).toList();

      _generationStatus = TodoGenerationStatus.success;
    } catch (e) {
      _generationStatus = TodoGenerationStatus.error;
      _generationError = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void clearGeneratedTodos() {
    _generatedTasks = [];
    _generationStatus = TodoGenerationStatus.initial;
    notifyListeners();
  }

  Future<void> addMultipleTodos(List<TodoItemModel> todos) async {
    if (_authProvider?.user == null) return;

    final batch = _firestore.batch();
    for (final todo in todos) {
      final docRef = _firestore.collection('todos').doc();
      batch.set(docRef, todo.toMap());
    }
    await batch.commit();
    clearGeneratedTodos();
  }

  Future<void> addTodo(TodoItemModel todo) async {
    if (_authProvider?.user == null) return;
    await _firestore.collection('todos').add(todo.toMap());
  }

  Future<void> updateTodoStatus(String id, bool isCompleted) async {
    await _firestore
        .collection('todos')
        .doc(id)
        .update({'isCompleted': isCompleted});
  }

  Future<void> deleteTodo(String id) async {
    await _firestore.collection('todos').doc(id).delete();
  }

  void filterByGuide(String? guideId) {
    _selectedGuideId = guideId;
    notifyListeners();
  }

  @override
  void dispose() {
    _todoSubscription?.cancel();
    super.dispose();
  }
} 