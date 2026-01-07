import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/core/errors/failures.dart';
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
        'vehicleType': ride.vehicleType.toString().split('.').last,
        'note': ride.note,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('rides').add(rideData);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Database error: ${e.message}');
    } catch (e) {
      throw FirestoreFailure('Failed to create ride. Please try again.');
    }
  }

  @override
  Future<List<RideEntity>> getAvailableRides() async {
    try {
      // Fetch open rides. Sorting in Dart to avoid manifest/index requirement errors
      final snapshot = await _firestore
          .collection('rides')
          .where('status', whereIn: ['open', 'booked', 'ongoing']) // Include ongoing if needed
          .get();

      final rides = snapshot.docs.map((doc) => _mapDocToEntity(doc)).toList();
      
      // Sort by dateTime ascending
      rides.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      return rides;
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Database error: ${e.message}');
    } catch (e) {
      throw FirestoreFailure('Failed to fetch rides. Please try again.');
    }
  }

  @override
  Future<List<RideEntity>> getUserRides(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('hostId', isEqualTo: userId)
          .get();

      final rides = snapshot.docs.map((doc) => _mapDocToEntity(doc)).toList();
      
      // Sort by dateTime descending
      rides.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return rides;
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Database error: ${e.message}');
    } catch (e) {
      throw FirestoreFailure('Failed to fetch your rides.');
    }
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      throw FirestoreFailure('Failed to update ride status');
    }
  }

  @override
  Future<void> updateHostLocation(String rideId, double lat, double lng) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'hostLatitude': lat,
        'hostLongitude': lng,
      });
    } catch (e) {
      throw FirestoreFailure('Failed to update host location');
    }
  }

  @override
  Future<void> decrementSeats(String rideId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('rides').doc(rideId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw FirestoreFailure('Ride not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        int currentSeats = data['seats'] ?? 0;
        
        if (currentSeats > 0) {
          currentSeats--;
          final updates = <String, dynamic>{'seats': currentSeats};
          
          if (currentSeats == 0) {
            updates['status'] = 'booked';
          }
          
          transaction.update(docRef, updates);
        } else {
          throw FirestoreFailure('No seats available');
        }
      });
    } catch (e) {
      if (e is FirestoreFailure) rethrow;
      throw FirestoreFailure('Failed to update seats: $e');
    }
  }

  @override
  Future<RideEntity?> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (!doc.exists) return null;
      return _mapDocToEntity(doc);
    } catch (e) {
      throw FirestoreFailure('Failed to fetch ride details');
    }
  }


  RideEntity _mapDocToEntity(DocumentSnapshot doc) {
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
      vehicleType: _parseVehicleType(data['vehicleType']),
      note: data['note'] ?? '',
      hostLatitude: (data['hostLatitude'] as num?)?.toDouble(),
      hostLongitude: (data['hostLongitude'] as num?)?.toDouble(),
    );
  }

  VehicleType _parseVehicleType(String? typeStr) {
    return VehicleType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => VehicleType.car,
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
