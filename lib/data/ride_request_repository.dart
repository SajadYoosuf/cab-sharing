import 'package:ride_share_app/models/ride_request.dart';

abstract class RideRequestRepository {
  Future<void> sendRequest(RideRequest request);
  Future<void> updateRequestStatus(String requestId, RideRequestStatus status);
  Stream<List<RideRequest>> getRequestsForHost(String hostId);
  Stream<List<RideRequest>> getRequestsForPassenger(String passengerId);
  Future<RideRequest?> getRequestForRideAndPassenger(String rideId, String passengerId);
}
