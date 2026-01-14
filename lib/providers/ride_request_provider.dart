import 'package:flutter/material.dart';
import 'package:ride_share_app/models/ride_request.dart';
import 'package:ride_share_app/models/ride.dart';
import 'package:ride_share_app/data/ride_request_repository.dart';
import 'package:ride_share_app/data/ride_repository.dart';

class RideRequestProvider extends ChangeNotifier {
  final RideRequestRepository _repository;
  final RideRepository _rideRepository;

  RideRequestProvider(this._repository, this._rideRepository);

  Future<bool> sendRequest(RideRequest request) async {
    try {
      // Check if already requested
      final existing = await _repository.getRequestForRideAndPassenger(request.rideId, request.passengerId);
      if (existing != null) {
        return false;
      }

      // Check ride availability
      final ride = await _rideRepository.getRideById(request.rideId);
      if (ride == null || ride.seats < 1 || ride.status != RideStatus.open) {
        return false;
      }

      await _repository.sendRequest(request);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> acceptRequest(RideRequest request) async {
    await _rideRepository.decrementSeats(request.rideId);
    await _repository.updateRequestStatus(request.id, RideRequestStatus.accepted);
  }

  Future<void> rejectRequest(String requestId) async {
    await _repository.updateRequestStatus(requestId, RideRequestStatus.rejected);
  }

  Stream<List<RideRequest>> getIncomingRequests(String userId) {
    return _repository.getRequestsForHost(userId);
  }

  Future<RideRequestStatus?> getRequestStatus(String rideId, String userId) async {
    final request = await _repository.getRequestForRideAndPassenger(rideId, userId);
    return request?.status;
  }
}
