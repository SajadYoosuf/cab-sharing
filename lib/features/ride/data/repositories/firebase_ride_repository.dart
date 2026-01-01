import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';

class FirebaseRideRepository implements RideRepository {
  final FirebaseFirestore _firestore;

  FirebaseRideRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createRide(RideEntity ride) async {
    try {
      // Create a map from the entity
      final rideData = {
        'hostId': ride.hostId,
        'hostName': ride.hostName,
        'type': ride.type.toString().split('.').last, // 'offer' or 'request'
        'from': {
          'name': ride.from.name,
          'latitude': ride.from.latitude,
          'longitude': ride.from.longitude,
        },
        'to': {
          'name': ride.to.name,
          'latitude': ride.to.latitude,
          'longitude': ride.to.longitude,
        },
        'dateTime': Timestamp.fromDate(ride.dateTime),
        'seats': ride.seats,
        'price': ride.price,
        'status': ride.status.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('rides').add(rideData);
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  @override
  Future<List<RideEntity>> getAvailableRides() async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'open')
          .orderBy('dateTime', descending: false)
          .get();

      return snapshot.docs.map((doc) => _mapDocToEntity(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rides: $e');
    }
  }

  @override
  Future<List<RideEntity>> getUserRides(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('hostId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs.map((doc) => _mapDocToEntity(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user rides: $e');
    }
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  RideEntity _mapDocToEntity(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RideEntity(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      type: _parseRideType(data['type']),
      from: _parseLocation(data['from']),
      to: _parseLocation(data['to']),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      seats: data['seats'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      status: _parseRideStatus(data['status']),
    );
  }

  RideType _parseRideType(String? typeStr) {
    return RideType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => RideType.offer,
    );
  }

  RideStatus _parseRideStatus(String? statusStr) {
    return RideStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => RideStatus.open,
    );
  }

  RideLocation _parseLocation(Map<String, dynamic>? data) {
    if (data == null) return const RideLocation(name: '');
    return RideLocation(
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }
}
