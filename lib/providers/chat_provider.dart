import 'package:flutter/foundation.dart';
import 'package:ride_share_app/models/chat_message.dart';
import 'package:ride_share_app/data/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  String? _error;

  ChatProvider(this._repository);

  String? get error => _error;

  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _repository.getMessages(rideId);
  }

  Future<bool> sendMessage(String rideId, String senderId, String senderName, String text) async {
    _error = null;
    try {
      await _repository.sendMessage(rideId, senderId, senderName, text);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
