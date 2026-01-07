import '../entities/ride_entity.dart';

abstract class RideRepository {
  Future<void> createRide(RideEntity ride);
  Future<List<RideEntity>> getAvailableRides(); // For matching
  Future<List<RideEntity>> getUserRides(String userId); // For dashboard
  Future<void> updateRideStatus(String rideId, RideStatus status);
  Future<void> updateHostLocation(String rideId, double lat, double lng);
  Future<void> decrementSeats(String rideId);
  Future<RideEntity?> getRideById(String rideId);
}
