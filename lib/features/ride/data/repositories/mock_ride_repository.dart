import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';

class MockRideRepository implements RideRepository {
  final List<RideEntity> _rides = [
    RideEntity(
      id: '1',
      hostId: 'user2',
      hostName: 'Alice Green',
      type: RideType.offer,
      from: const RideLocation(name: 'Central Station'),
      to: const RideLocation(name: 'Tech Park'),
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      seats: 3,
      price: 5.0,
    ),
    RideEntity(
      id: '2',
      hostId: 'user3',
      hostName: 'Bob Eco',
      type: RideType.offer,
      from: const RideLocation(name: 'Airport'),
      to: const RideLocation(name: 'Downtown'),
      dateTime: DateTime.now().add(const Duration(days: 1)),
      seats: 2,
      price: 12.0,
    ),
  ];

  @override
  Future<void> createRide(RideEntity ride) async {
    await Future.delayed(const Duration(seconds: 1));
    _rides.add(ride);
  }

  @override
  Future<List<RideEntity>> getAvailableRides() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _rides.where((r) => r.status == RideStatus.open).toList();
  }

  @override
  Future<List<RideEntity>> getUserRides(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _rides.where((r) => r.hostId == userId).toList();
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
      // Find and update
      // Immutable update simulation
      // For now just ignore
  }
}
