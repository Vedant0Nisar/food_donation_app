import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:food_donation_app/authenticate/model.dart';
import 'package:food_donation_app/authenticate/email_verification.dart';
import 'package:food_donation_app/intro/welcome_page.dart';
import 'package:food_donation_app/ngo/n_main_page.dart';
import 'package:food_donation_app/volunteer/v_main_page.dart';

enum UserType { volunteer, ngo }

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  // Observable variables
  var isLoading = false.obs;
  var currentUser = Rxn<User>();
  var userModel = Rxn<UserModel>();
  var userType = Rxn<UserType>();
  var otpSent = false.obs;

  StreamSubscription<User?>? _authStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      if (user != null && user.emailVerified) {
        loadUserData(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  void _clearUserData() {
    userModel.value = null;
    userType.value = null;
  }

  Future<void> loadUserData(String uid) async {
    if (userType.value != null) return; // Already loaded

    try {
      isLoading.value = true;

      // Check NGOs collection first
      DocumentSnapshot ngoDoc = await _firestore
          .collection('ngos')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (ngoDoc.exists && ngoDoc.data() != null) {
        userModel.value =
            NgoModel.fromMap(ngoDoc.data() as Map<String, dynamic>);
        userType.value = UserType.ngo;
        _storage.write('userType', 'ngo');
        return;
      }

      // Check volunteers collection
      DocumentSnapshot volunteerDoc = await _firestore
          .collection('volunteers')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (volunteerDoc.exists && volunteerDoc.data() != null) {
        userModel.value =
            UserModel.fromMap(volunteerDoc.data() as Map<String, dynamic>);
        userType.value = UserType.volunteer;
        _storage.write('userType', 'volunteer');
        return;
      }

      // No user data found
      print('No user data found for UID: $uid');
      await signOut();
    } on TimeoutException {
      print('Timeout loading user data');
      // Don't sign out on timeout, let user retry
    } catch (e) {
      print('Error loading user data: $e');
      showErrorSnackbar('Failed to load user data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpVolunteer({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Create user account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Save volunteer data to Firestore
      await _firestore.collection('volunteers').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'username': username,
        'email': email,
        'phone': phone,
        'userType': 'volunteer',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
      });

      // Send verification email
      await credential.user!.sendEmailVerification();

      // Set user type for navigation
      userType.value = UserType.volunteer;

      showSuccessSnackbar('Verification email sent! Please check your inbox.');
      Get.to(() => EmailVerificationScreen());
    } on FirebaseAuthException catch (e) {
      showErrorSnackbar(_handleAuthError(e));
    } catch (e) {
      showErrorSnackbar('Registration failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpNgo({
    required String ngoName,
    required String ngoId,
    required String ngoType,
    required String email,
    required String phone,
    required String address,
    required String pincode,
    required String username,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Create user account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Save NGO data to Firestore
      await _firestore.collection('ngos').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'ngoName': ngoName,
        'ngoId': ngoId,
        'ngoType': ngoType,
        'email': email,
        'phone': phone,
        'address': address,
        'pincode': pincode,
        'username': username,
        'userType': 'ngo',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': false,
        'emailVerified': false,
      });

      // Send verification email
      await credential.user!.sendEmailVerification();

      // Set user type for navigation
      userType.value = UserType.ngo;

      showSuccessSnackbar('Verification email sent! Please check your inbox.');
      Get.to(() => EmailVerificationScreen());
    } on FirebaseAuthException catch (e) {
      showErrorSnackbar(_handleAuthError(e));
    } catch (e) {
      showErrorSnackbar('Registration failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;

      if (user == null) {
        showErrorSnackbar('No user found. Please sign up again.');
        Get.offAll(() => WelcomePage());
        return;
      }

      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        // Update Firestore email verification status
        String collection =
            userType.value == UserType.ngo ? 'ngos' : 'volunteers';
        await _firestore.collection(collection).doc(user.uid).update({
          'emailVerified': true,
        });

        await loadUserData(user.uid);
        showSuccessSnackbar('Email verified successfully!');

        // Navigate based on user type
        if (userType.value == UserType.volunteer) {
          Get.offAll(() => VMainPage());
        } else if (userType.value == UserType.ngo) {
          Get.offAll(() => NMain());
        }
      } else {
        showErrorSnackbar('Email not verified yet. Please check your inbox.');
      }
    } catch (e) {
      showErrorSnackbar('Verification check failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        showSuccessSnackbar('Verification email sent again!');
      } else if (user == null) {
        showErrorSnackbar('No user found. Please sign up again.');
      } else {
        showErrorSnackbar('Email already verified.');
      }
    } catch (e) {
      showErrorSnackbar('Failed to resend verification email');
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Login failed');
      }

      if (credential.user!.emailVerified) {
        await loadUserData(credential.user!.uid);
        showSuccessSnackbar('Login successful');
        print(credential.user!.uid);
        print(
            "uuuuuiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiddddddddddddddddddd");

        _storage.write('currentUserUid', credential.user!.uid.toString());

        var uid_1 = _storage.read('currentUserUid');
        print(uid_1);
        print(
            "uuuuuiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiddddddddddddddddddd");

        String uid_2 = FirebaseAuth.instance.currentUser!.uid;
        _storage.write('currentUserUid', uid_2);

        var uid_3 = _storage.read('currentUserUid');
        print(uid_3);

        print(
            "uuuuuiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiddddddddddddddddddd");
        if (userType.value == UserType.volunteer) {
          Get.off(() => VMainPage()); // Send to volunteer dashboard
        } else if (userType.value == UserType.ngo) {
          Get.off(() => NMain()); // Send to NGO dashboard
        }
        // handle navigation after ti vmainpage or nmaipage
      } else {
        showErrorSnackbar('Please verify your email before logging in');
        // Set user type for email verification screen
        await _determineUserTypeFromEmail(email);
      }
    } on FirebaseAuthException catch (e) {
      showErrorSnackbar(_handleAuthError(e));
    } catch (e) {
      showErrorSnackbar('Login failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _determineUserTypeFromEmail(String email) async {
    try {
      // Check in NGOs collection
      QuerySnapshot ngoQuery = await _firestore
          .collection('ngos')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (ngoQuery.docs.isNotEmpty) {
        userType.value = UserType.ngo;
        return;
      }

      // Check in volunteers collection
      QuerySnapshot volunteerQuery = await _firestore
          .collection('volunteers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (volunteerQuery.docs.isNotEmpty) {
        userType.value = UserType.volunteer;
        return;
      }
    } catch (e) {
      print('Error determining user type: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _clearUserData();
      _storage.remove('userType');
      Get.offAll(() => WelcomePage());
    } catch (e) {
      showErrorSnackbar('Sign out failed');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showSuccessSnackbar('Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      showErrorSnackbar(_handleAuthError(e));
    } catch (e) {
      showErrorSnackbar('Failed to send reset email');
    }
  }

  // Validation methods
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      // Check volunteers collection
      QuerySnapshot volunteerQuery = await _firestore
          .collection('volunteers')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (volunteerQuery.docs.isNotEmpty) return false;

      // Check NGOs collection
      QuerySnapshot ngoQuery = await _firestore
          .collection('ngos')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return ngoQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  Future<bool> checkPhoneAvailability(String phone) async {
    try {
      // Check volunteers collection
      QuerySnapshot volunteerQuery = await _firestore
          .collection('volunteers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (volunteerQuery.docs.isNotEmpty) return false;

      // Check NGOs collection
      QuerySnapshot ngoQuery = await _firestore
          .collection('ngos')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      return ngoQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking phone availability: $e');
      return false;
    }
  }

  Future<bool> checkNgoIdAvailability(String ngoId) async {
    try {
      QuerySnapshot ngoQuery = await _firestore
          .collection('ngos')
          .where('ngoId', isEqualTo: ngoId)
          .limit(1)
          .get();

      return ngoQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking NGO ID availability: $e');
      return false;
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }

  void showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
