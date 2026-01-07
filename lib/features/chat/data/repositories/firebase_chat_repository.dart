import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;

  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          rideId: rideId,
          senderId: data['senderId'],
          senderName: data['senderName'] ?? 'Unknown',
          text: data['text'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(String rideId, String senderId, String senderName, String text) async {
    try {
      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Database error: ${e.message}');
    } catch (e) {
      throw FirestoreFailure('Failed to send message.');
    }
  }
}
