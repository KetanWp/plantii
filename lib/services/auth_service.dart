import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase Authentication with anonymous sign-in persistence.
/// On first launch, signs the user in anonymously and preserves the session
/// across app restarts.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();

  final FirebaseAuth? _customAuth;

  AuthService({FirebaseAuth? auth}) : _customAuth = auth;

  /// Visible for testing to inject mock AuthService
  static void setMockInstance(AuthService mock) {
    _instance = mock;
  }

  /// Safely resolves the active FirebaseAuth instance, returning null if Firebase
  /// is not initialized (e.g. in standalone unit or widget tests).
  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Current signed-in Firebase user
  User? get currentUser => _auth?.currentUser;

  /// Current user's unique identifier (UID)
  String? get userId => _auth?.currentUser?.uid;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Whether a user is currently signed in
  bool get isSignedIn => _auth?.currentUser != null;

  /// Initializes authentication on app launch.
  /// If no session exists, signs in anonymously to establish an anonymous session.
  /// If the device is offline, catches the error so the app continues to function offline.
  Future<User?> initializeAuth() async {
    final auth = _auth;
    if (auth == null) {
      debugPrint('AuthService: FirebaseAuth is not initialized in this environment.');
      return null;
    }

    try {
      if (auth.currentUser != null) {
        debugPrint('AuthService: Existing anonymous session restored for UID: ${auth.currentUser!.uid}');
        return auth.currentUser;
      }

      debugPrint('AuthService: First launch or no session found. Signing in anonymously...');
      final userCredential = await auth.signInAnonymously();
      debugPrint('AuthService: Successfully signed in anonymously with UID: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException during anonymous sign-in: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AuthService: Unexpected error during anonymous sign-in: $e');
      return null;
    }
  }

  /// Retrieves a valid Firebase ID token for authenticating Cloud Function API requests.
  /// If the user is not yet signed in (e.g. was offline during first launch), attempts to sign in.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final auth = _auth;
    if (auth == null) return null;

    try {
      User? user = auth.currentUser;
      user ??= await initializeAuth();
      if (user == null) {
        return null;
      }
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('AuthService: Failed to retrieve ID token: $e');
      return null;
    }
  }

  /// Signs out the current user session
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      debugPrint('AuthService: User signed out successfully.');
    } catch (e) {
      debugPrint('AuthService: Error during sign out: $e');
    }
  }
}
