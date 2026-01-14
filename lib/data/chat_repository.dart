import 'package:ride_share_app/models/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> getMessages(String rideId);
  Future<void> sendMessage(String rideId, String senderId, String senderName, String text);
}
