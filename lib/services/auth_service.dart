import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_user_model.dart';
import '../models/customer_model.dart';
import '../models/admin_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
// EmailService removed in favor of direct Firebase Link

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Register new user
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String preferredLanguage = 'en',
  }) async {
    try {
      print('🚀 Starting registration for: $email');

      // 1. Hash the password for local storage
      final hashedPassword = _hashPassword(password);

      // 2. Create user in Firebase Authentication
      UserCredential authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password, // Firebase Auth handles its own hashing
      );

      final userId = authResult.user!.uid;
      print('✅ Firebase user created: $userId');

      // 2. Create AppUser object
      AppUser appUser;
      if (role == 'customer') {
        appUser = Customer(
          userId: userId,
          name: name,
          email: email,
          password: hashedPassword, // Store hashed password
          preferredLanguage: preferredLanguage,
        );
      } else if (role == 'admin') {
        appUser = Admin(
          userId: userId,
          name: name,
          email: email,
          password: hashedPassword,
        );
      } else if (role == 'delivery_driver') {
        appUser = RegularUser(
          userId: userId,
          name: name,
          email: email,
          password: hashedPassword,
          role: 'delivery_driver',
        );
      } else {
        appUser = RegularUser(
          userId: userId,
          name: name,
          email: email,
          password: hashedPassword,
          role: role,
        );
      }

      // 3. Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(appUser.toMap());

      // 4. Send email verification
      await authResult.user?.sendEmailVerification();
      print('📧 Verification email sent to: $email');

      print('✅ User saved to Firestore: ${appUser.name}');
      return appUser;

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return null;
    }
  }

  // Sign in user
  Future<AppUser?> signInUser(String email, String password) async {
    try {
      print('🔐 Signing in: $email');

      UserCredential authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = authResult.user!.uid;
      print('✅ Signed in: $userId');

      // Get user data from Firestore
      return await getUserData(userId);

    } on FirebaseAuthException catch (e) {
      print('❌ Sign in Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return null;
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure userId is present in data, fallback to document ID
        if (data['userId'] == null) {
          data['userId'] = doc.id;
        }
        return AppUser.fromMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Get current logged in user
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return await getUserData(firebaseUser.uid);
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    print('✅ User signed out');
  }

  // Update user profile
  Future<void> updateProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.userId)
          .update(user.toMap());
      print('✅ Profile updated');
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send verification email
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('📧 Password reset email sent to: $email');
    } catch (e) {
      print('❌ Error sending reset email: $e');
      rethrow;
    }
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // --- Security & OTP Helpers ---

  // SHA-256 Password Hashing
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- Sign-in Link Logic ---

  Future<void> sendSignInLink(String email) async {
    try {
      var acs = ActionCodeSettings(
        url: 'https://majet-fd164.firebaseapp.com/finishSignUp?email=$email',
        handleCodeInApp: true,
        androidPackageName: 'com.example.maj3t',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      await _auth.sendSignInLinkToEmail(
        email: email, 
        actionCodeSettings: acs
      );
      print('📧 Sign-in link sent to: $email');
    } catch (e) {
      print('❌ Error sending sign-in link: $e');
      rethrow;
    }
  }

  Future<bool> isSignInWithEmailLink(String link) async {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<UserCredential> signInWithEmailLink(String email, String link) async {
    return await _auth.signInWithEmailLink(email: email, emailLink: link);
  }
}