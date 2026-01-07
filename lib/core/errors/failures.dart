abstract class Failure {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class FirestoreFailure extends Failure {
  FirestoreFailure(super.message);
}

class LocationFailure extends Failure {
  LocationFailure(super.message);
}
