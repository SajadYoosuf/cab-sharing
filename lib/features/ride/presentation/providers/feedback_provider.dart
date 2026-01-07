import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/feedback_entity.dart';

class FeedbackProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> submitFeedback(FeedbackEntity feedback) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use set with a specific ID if we want to prevent duplicate feedback from same user for same ride
      // But for simplicity, we'll just add. 
      // Actually, let's use a unique ID: rideId_passengerId
      final docId = '${feedback.rideId}_${feedback.passengerId}';
      await _firestore.collection('feedbacks').doc(docId).set(feedback.toMap());
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> hasSubmittedFeedback(String rideId, String userId) async {
    final docId = '${rideId}_$userId';
    final doc = await _firestore.collection('feedbacks').doc(docId).get();
    return doc.exists;
  }

  Stream<List<FeedbackEntity>> getRideFeedbacks(String rideId) {
    return _firestore
        .collection('feedbacks')
        .where('rideId', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackEntity.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<FeedbackEntity>> getHostFeedbacks(String hostId) {
    return _firestore
        .collection('feedbacks')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackEntity.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<FeedbackEntity>> getAllFeedbacks() {
    return _firestore
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackEntity.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
}
