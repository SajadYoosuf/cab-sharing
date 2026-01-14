import 'package:ride_share_app/models/ride.dart';

abstract class RideRepository {
  Future<void> createRide(Ride ride);
  Future<List<Ride>> getAvailableRides(); // For matching
  Future<List<Ride>> getUserRides(String userId); // For dashboard
  Future<void> updateRideStatus(String rideId, RideStatus status);
  Future<void> updateHostLocation(String rideId, double lat, double lng);
  Future<void> updateLiveStatus(String rideId, bool isLive);
  Future<void> decrementSeats(String rideId);
  Future<Ride?> getRideById(String rideId);
}
