import '../entities/ride_request_entity.dart';

abstract class RideRequestRepository {
  Future<void> sendRequest(RideRequestEntity request);
  Future<void> updateRequestStatus(String requestId, RideRequestStatus status);
  Stream<List<RideRequestEntity>> getRequestsForHost(String hostId);
  Stream<List<RideRequestEntity>> getRequestsForPassenger(String passengerId);
  Future<RideRequestEntity?> getRequestForRideAndPassenger(String rideId, String passengerId);
}
