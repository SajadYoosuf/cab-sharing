enum RideRequestStatus { pending, accepted, rejected, cancelled }

class RideRequestEntity {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String hostId;
  final RideRequestStatus status;
  final DateTime createdAt;

  RideRequestEntity({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.hostId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'hostId': hostId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RideRequestEntity.fromMap(String id, Map<String, dynamic> map) {
    return RideRequestEntity(
      id: id,
      rideId: map['rideId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      hostId: map['hostId'] ?? '',
      status: RideRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideRequestStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
