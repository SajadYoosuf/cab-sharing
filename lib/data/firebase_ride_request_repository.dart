import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/models/ride_request.dart';
import 'package:ride_share_app/data/ride_request_repository.dart';

class FirebaseRideRequestRepository implements RideRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendRequest(RideRequest request) async {
    await _firestore.collection('ride_requests').add(request.toMap());
  }

  @override
  Future<void> updateRequestStatus(String requestId, RideRequestStatus status) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'status': status.name,
    });
  }

  @override
  Stream<List<RideRequest>> getRequestsForHost(String hostId) {
    return _firestore
        .collection('ride_requests')
        .where('hostId', isEqualTo: hostId)
        .where('status', isEqualTo: RideRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<RideRequest>> getRequestsForPassenger(String passengerId) {
    return _firestore
        .collection('ride_requests')
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<RideRequest?> getRequestForRideAndPassenger(String rideId, String passengerId) async {
    final snapshot = await _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: passengerId)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return RideRequest.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }
}
