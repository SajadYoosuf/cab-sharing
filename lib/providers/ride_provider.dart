import 'package:flutter/material.dart';
import 'package:ride_share_app/models/ride.dart';
import 'package:ride_share_app/data/ride_repository.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _repository;
  
  List<Ride> _availableRides = [];
  List<Ride> _myRides = [];
  List<Ride> _requestedRides = [];
  bool _isLoading = false;
  String? _error;

  List<Ride> get availableRides => _availableRides;
  List<Ride> get myRides => _myRides;
  List<Ride> get requestedRides => _requestedRides;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RideProvider(this._repository);

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableRides = await _repository.getAvailableRides();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyRides(String userId) async {
    _error = null;
    try {
      _myRides = await _repository.getUserRides(userId);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadRequestedRides(String userId) async {
    _error = null;
    try {
      _requestedRides = await _repository.getRequestedRides(userId);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAcceptedPassengers(String rideId) async {
    try {
      return await _repository.getAcceptedPassengers(rideId);
    } catch (e) {
      return [];
    }
  }

  double get totalCo2Saved {
    double totalDistanceKm = 0;
    for (var ride in _myRides) {
      if (ride.status == RideStatus.completed) {
         double latDiff = (ride.from.latitude - ride.to.latitude).abs();
         double lonDiff = (ride.from.longitude - ride.to.longitude).abs();
         totalDistanceKm += (latDiff + lonDiff) * 100;
      }
    }
    return totalDistanceKm * 0.2; 
  }

  Future<bool> createRide(Ride ride) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.createRide(ride);
      _isLoading = false;
      await loadAvailableRides();
      await loadMyRides(ride.hostId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateRideStatus(String rideId, RideStatus status, String userId) async {
    try {
      await _repository.updateRideStatus(rideId, status);
      await loadAvailableRides();
      await loadMyRides(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLiveTracking(String rideId, bool isLive, String userId) async {
    try {
      // We need a way to update just the isLive field. 
      // For now, I'll direct update via firestore in repository or add method to repo.
      // I'll add method to repository for better abstraction.
      await _repository.updateLiveStatus(rideId, isLive);
      await loadMyRides(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHostLocation(String rideId, double lat, double lng) async {
    try {
      await _repository.updateHostLocation(rideId, lat, lng);
    } catch (e) {
      _error = e.toString();
    }
  }
}
