import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ride_request_entity.dart';
import '../../domain/repositories/ride_request_repository.dart';

class FirebaseRideRequestRepository implements RideRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendRequest(RideRequestEntity request) async {
    await _firestore.collection('ride_requests').add(request.toMap());
  }

  @override
  Future<void> updateRequestStatus(String requestId, RideRequestStatus status) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'status': status.name,
    });
  }

  @override
  Stream<List<RideRequestEntity>> getRequestsForHost(String hostId) {
    return _firestore
        .collection('ride_requests')
        .where('hostId', isEqualTo: hostId)
        .where('status', isEqualTo: RideRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequestEntity.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<RideRequestEntity>> getRequestsForPassenger(String passengerId) {
    return _firestore
        .collection('ride_requests')
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequestEntity.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<RideRequestEntity?> getRequestForRideAndPassenger(String rideId, String passengerId) async {
    final snapshot = await _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: passengerId)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return RideRequestEntity.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }
}
