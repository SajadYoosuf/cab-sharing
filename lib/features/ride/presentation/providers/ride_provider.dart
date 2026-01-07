import 'package:flutter/material.dart';
import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _repository;
  
  List<RideEntity> _availableRides = [];
  List<RideEntity> _myRides = [];
  bool _isLoading = false;
  String? _error;

  List<RideEntity> get availableRides => _availableRides;
  List<RideEntity> get myRides => _myRides;
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

  Future<bool> createRide(RideEntity ride) async {
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
