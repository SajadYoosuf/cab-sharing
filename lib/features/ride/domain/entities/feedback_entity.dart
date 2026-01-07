class FeedbackEntity {
  final String id;
  final String rideId;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final String passengerId;
  final String passengerName;
  final String? passengerPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  FeedbackEntity({
    required this.id,
    required this.rideId,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.passengerId,
    required this.passengerName,
    this.passengerPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhotoUrl': passengerPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackEntity.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackEntity(
      id: id,
      rideId: map['rideId'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      hostPhotoUrl: map['hostPhotoUrl'],
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhotoUrl: map['passengerPhotoUrl'],
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
