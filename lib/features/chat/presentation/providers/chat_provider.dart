import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository);

  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _repository.getMessages(rideId);
  }

  Future<void> sendMessage(String rideId, String senderId, String senderName, String text) async {
    await _repository.sendMessage(rideId, senderId, senderName, text);
  }
}
