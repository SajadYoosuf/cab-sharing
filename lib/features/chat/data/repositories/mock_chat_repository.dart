import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [];

  @override
  Stream<List<ChatMessage>> getMessages(String rideId) {
    return Stream.value(_messages.where((m) => m.rideId == rideId).toList());
  }

  @override
  Future<void> sendMessage(String rideId, String senderId, String senderName, String text) async {
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    ));
  }
}
