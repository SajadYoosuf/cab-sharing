import 'package:flutter/material.dart';
import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _repository;
  
  List<RideEntity> _availableRides = [];
  List<RideEntity> _myRides = [];
  bool _isLoading = false;

  List<RideEntity> get availableRides => _availableRides;
  List<RideEntity> get myRides => _myRides;
  bool get isLoading => _isLoading;

  RideProvider(this._repository);

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    notifyListeners();
    _availableRides = await _repository.getAvailableRides();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyRides(String userId) async {
    _myRides = await _repository.getUserRides(userId);
    notifyListeners();
  }


  double get totalCo2Saved {
    double totalDistanceKm = 0;
    for (var ride in _myRides) {
      if (ride.status == RideStatus.completed) {
         // I'll take a rough estimate: (abs(lat_diff) + abs(long_diff)) * 100 km
         double latDiff = (ride.from.latitude - ride.to.latitude).abs();
         double lonDiff = (ride.from.longitude - ride.to.longitude).abs();
         
         totalDistanceKm += (latDiff + lonDiff) * 100;
      }
    }
    // 0.2kg per km
    return totalDistanceKm * 0.2; 
  }

  Future<void> createRide(RideEntity ride) async {
    await _repository.createRide(ride);
    await loadAvailableRides();
    await loadMyRides(ride.hostId);
  }
}
