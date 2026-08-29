import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles authentication for ShopWise.
///
/// Supported authentication:
/// - Google Sign-In
/// - Firebase Authentication
///
/// This class is designed for google_sign_in 7.x APIs.
class AuthService {
  // ---------------------------------------------------------------------------
  // Firebase
  // ---------------------------------------------------------------------------

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // IMPORTANT:
  // This is the WEB OAuth 2.0 Client ID created from:
  //
  // Google Cloud Console
  // → Google Auth Platform
  // → Clients
  //
  // Do NOT use the Android OAuth client ID here.
  static const String _serverClientId =
      '879325429404-8p540cfs6omja24o3afe1pv75d5f7n05.apps.googleusercontent.com';

  // Prevents initialize() from being called multiple times.
  //
  // google_sign_in 7.x requires initialize() before authentication.
  // The package documentation also recommends initializing the singleton
  // before using other GoogleSignIn APIs.
  bool _googleInitialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes Google Sign-In.
  ///
  /// This method is safe to call multiple times.
  /// Actual initialization happens only once.
  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }

    try {
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );

      _googleInitialized = true;

      debugPrint('ShopWise: Google Sign-In initialized successfully.');
    } on GoogleSignInException catch (e) {
      debugPrint(
        'ShopWise: Google initialization failed.\n'
        'Code: ${e.code}\n'
        'Message: ${e.description}',
      );

      rethrow;
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected Google initialization error: $e',
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Signs the user in with Google and Firebase.
  ///
  /// Returns:
  /// - UserCredential when successful
  /// - null when sign-in fails or is cancelled
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // ---------------------------------------------------------------
      // 1. Initialize Google Sign-In
      // ---------------------------------------------------------------

      await _initializeGoogleSignIn();

      debugPrint('ShopWise: Starting Google Sign-In...');

      // ---------------------------------------------------------------
      // 2. Start Google authentication
      // ---------------------------------------------------------------

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      debugPrint(
        'ShopWise: Google account selected: ${googleUser.email}',
      );

      // ---------------------------------------------------------------
      // 3. Get Google authentication information
      // ---------------------------------------------------------------

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      // Firebase requires an ID token for this authentication flow.
      if (idToken == null || idToken.isEmpty) {
        debugPrint(
          'ShopWise: Google Sign-In succeeded, '
          'but Google returned a null/empty ID token.',
        );

        return null;
      }

      debugPrint('ShopWise: Google ID token received.');

      // ---------------------------------------------------------------
      // 4. Create Firebase credential
      // ---------------------------------------------------------------

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // ---------------------------------------------------------------
      // 5. Sign in to Firebase
      // ---------------------------------------------------------------

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user == null) {
        debugPrint(
          'ShopWise: Firebase sign-in completed '
          'but no Firebase user was returned.',
        );

        return null;
      }

      // ---------------------------------------------------------------
      // 6. Success information
      // ---------------------------------------------------------------

      debugPrint(
        'ShopWise: Firebase Google Sign-In successful.\n'
        'UID: ${user.uid}\n'
        'Name: ${user.displayName}\n'
        'Email: ${user.email}',
      );

      return userCredential;
    }

    // -------------------------------------------------------------------------
    // Google Sign-In errors
    // -------------------------------------------------------------------------

    on GoogleSignInException catch (e) {
      debugPrint(
        'ShopWise: Google Sign-In Error\n'
        'Code: ${e.code}\n'
        'Description: ${e.description}',
      );

      return null;
    }

    // -------------------------------------------------------------------------
    // Firebase Authentication errors
    // -------------------------------------------------------------------------

    on FirebaseAuthException catch (e) {
      debugPrint(
        'ShopWise: Firebase Authentication Error\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}',
      );

      return null;
    }

    // -------------------------------------------------------------------------
    // Unexpected errors
    // -------------------------------------------------------------------------

    catch (e, stackTrace) {
      debugPrint(
        'ShopWise: Unexpected Google Sign-In Error: $e',
      );

      debugPrint(
        'ShopWise StackTrace:\n$stackTrace',
      );

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Signs the current user out from:
  /// - Google
  /// - Firebase
  Future<void> signOut() async {
    try {
      await _initializeGoogleSignIn();

      await _googleSignIn.signOut();

      debugPrint('ShopWise: Google Sign-Out successful.');
    } on GoogleSignInException catch (e) {
      debugPrint(
        'ShopWise: Google Sign-Out Error\n'
        'Code: ${e.code}\n'
        'Description: ${e.description}',
      );
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected Google Sign-Out Error: $e',
      );
    }

    try {
      await _auth.signOut();

      debugPrint('ShopWise: Firebase Sign-Out successful.');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ShopWise: Firebase Sign-Out Error\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected Firebase Sign-Out Error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Disconnect Google Account
  // ---------------------------------------------------------------------------

  /// Disconnects the Google account from ShopWise.
  ///
  /// This is different from normal sign-out.
  /// Disconnect revokes the previously granted authorization.
  Future<void> disconnectGoogle() async {
    try {
      await _initializeGoogleSignIn();

      await _googleSignIn.disconnect();

      debugPrint(
        'ShopWise: Google account disconnected successfully.',
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        'ShopWise: Google Disconnect Error\n'
        'Code: ${e.code}\n'
        'Description: ${e.description}',
      );
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected Google Disconnect Error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Current Firebase User
  // ---------------------------------------------------------------------------

  /// Returns the currently signed-in Firebase user.
  User? get currentUser {
    return _auth.currentUser;
  }

  // ---------------------------------------------------------------------------
  // Authentication Status
  // ---------------------------------------------------------------------------

  /// Returns true when a Firebase user is currently signed in.
  bool get isSignedIn {
    return _auth.currentUser != null;
  }

  // ---------------------------------------------------------------------------
  // User Information Helpers
  // ---------------------------------------------------------------------------

  /// Current user's UID.
  String? get userId {
    return _auth.currentUser?.uid;
  }

  /// Current user's display name.
  String? get userName {
    return _auth.currentUser?.displayName;
  }

  /// Current user's email.
  String? get userEmail {
    return _auth.currentUser?.email;
  }

  /// Current user's profile photo URL.
  String? get userPhotoUrl {
    return _auth.currentUser?.photoURL;
  }

  /// Returns true if the current user's email is verified.
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ---------------------------------------------------------------------------
  // Auth State Stream
  // ---------------------------------------------------------------------------

  /// Listens for authentication changes.
  ///
  /// Useful for deciding whether the app should show:
  /// - Splash screen
  /// - Login screen
  /// - Home screen
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // ID Token
  // ---------------------------------------------------------------------------

  /// Gets the Firebase ID token of the current user.
  ///
  /// Useful later if ShopWise gets a backend/API.
  Future<String?> getIdToken() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        debugPrint(
          'ShopWise: Cannot get ID token because no user is signed in.',
        );

        return null;
      }

      final String? token = await user.getIdToken();

      return token;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ShopWise: Failed to get Firebase ID token.\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}',
      );

      return null;
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected ID token error: $e',
      );

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Reload Current User
  // ---------------------------------------------------------------------------

  /// Reloads the current Firebase user's information.
  Future<void> reloadUser() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return;
      }

      await user.reload();

      debugPrint(
        'ShopWise: Firebase user information reloaded.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ShopWise: Failed to reload user.\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'ShopWise: Unexpected reload error: $e',
      );
    }
  }
}