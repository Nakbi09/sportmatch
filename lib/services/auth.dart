import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get changes => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Log/propager l’erreur si tu as un logger
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
