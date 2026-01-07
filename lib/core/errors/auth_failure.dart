class AuthFailure {
  final String message;
  final String? code;

  AuthFailure(this.message, {this.code});

  factory AuthFailure.fromFirebase(String code) {
    switch (code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email.');
      case 'wrong-password':
        return AuthFailure('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return AuthFailure('This email is already registered.');
      case 'weak-password':
        return AuthFailure('The password is too weak.');
      case 'invalid-email':
        return AuthFailure('The email address is not valid.');
      case 'network-request-failed':
        return AuthFailure('Network error. Please check your connection.');
      case 'user-disabled':
        return AuthFailure('This user account has been disabled.');
      case 'too-many-requests':
        return AuthFailure('Too many failed attempts. Try again later.');
      default:
        return AuthFailure('Authentication failed. Please try again.');
    }
  }

  @override
  String toString() => message;
}
