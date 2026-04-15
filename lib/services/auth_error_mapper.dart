import 'package:firebase_auth/firebase_auth.dart';

String mapFirebaseAuthErrorCode(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'invalid-credential':
      return 'The email or password is incorrect.';
    case 'user-not-found':
      return 'No account was found for this email.';
    case 'wrong-password':
      return 'The password is incorrect.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'email-already-in-use':
      return 'This email is already registered.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

String mapFirebaseAuthException(
  FirebaseAuthException error, {
  bool includeDebugDetails = false,
}) {
  final userMessage = mapFirebaseAuthErrorCode(error.code);
  if (!includeDebugDetails) {
    return userMessage;
  }

  final backendMessage = (error.message ?? '').trim();
  if (backendMessage.isEmpty) {
    return '$userMessage [code: ${error.code}]';
  }

  return '$userMessage [code: ${error.code}] $backendMessage';
}
