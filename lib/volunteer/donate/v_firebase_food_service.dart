import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFoodService {
  static FirebaseFoodService? _instance;
  static FirebaseFoodService get instance =>
      _instance ??= FirebaseFoodService._();
  FirebaseFoodService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _foodPostsCollection =>
      _firestore.collection('food_posts');

  /// Insert food post data to Firestore
  Future<bool> insertFoodPostData({
    required String userUid,
    required String foodDetails,
    required String quantity,
    required String pickupTime,
    required String address,
    required String zipCode,
    required String longitude,
    required String latitude,
    String status = 'available',
  }) async {
    try {
      // Get current user info
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userUid) {
        throw Exception('User authentication error');
      }

      // Get user data from users collection (volunteers or ngos)
      Map<String, dynamic>? userData = await _getUserData(userUid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Create food post document
      DocumentReference docRef = await _foodPostsCollection.add({
        // User information
        'userUid': userUid,
        'userName': userData['username'] ?? 'Unknown',
        'userEmail': userData['email'] ?? '',
        'userPhone': userData['phone'] ?? '',
        'userType': userData['userType'] ?? 'volunteer',

        // Food information
        'foodDetails': foodDetails.trim(),
        'quantity': quantity,
        'quantityNumber': _parseQuantity(quantity),

        // Location and time
        'pickupTime': pickupTime,
        'address': address.trim(),
        'zipCode': zipCode.trim(),
        'location': {
          'latitude': _parseDouble(latitude),
          'longitude': _parseDouble(longitude),
        },

        // Status and metadata
        'status': status, // available, claimed, completed, expired
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Additional fields for functionality
        'isActive': true,
        'claimedBy': null,
        'claimedAt': null,
        'completedAt': null,
        'views': 0,
        'likes': 0,

        // Search and filter fields
        'searchKeywords': _generateSearchKeywords(foodDetails, address),
      });

      // Update user's post count
      await _updateUserPostCount(userUid, userData['userType']);

      print('Food post created with ID: ${docRef.id}');
      return true;
    } on FirebaseException catch (e) {
      print('Firebase error creating food post: ${e.code} - ${e.message}');
      throw Exception('Failed to create post: ${e.message}');
    } catch (e) {
      print('Error creating food post: $e');
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  /// Get user data from volunteers or ngos collection
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      // Check volunteers collection first
      DocumentSnapshot volunteerDoc =
          await _firestore.collection('volunteers').doc(uid).get();

      if (volunteerDoc.exists) {
        return volunteerDoc.data() as Map<String, dynamic>?;
      }

      // Check ngos collection
      DocumentSnapshot ngoDoc =
          await _firestore.collection('ngos').doc(uid).get();

      if (ngoDoc.exists) {
        return ngoDoc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user's total post count
  Future<void> _updateUserPostCount(String uid, String userType) async {
    try {
      String collection = userType == 'ngo' ? 'ngos' : 'volunteers';

      await _firestore.collection(collection).doc(uid).update({
        'totalPosts': FieldValue.increment(1),
        'lastPostAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user post count: $e');
      // Don't throw error here as post creation was successful
    }
  }

  /// Generate search keywords for better searchability
  List<String> _generateSearchKeywords(String foodDetails, String address) {
    Set<String> keywords = {};

    // Add words from food details
    keywords.addAll(foodDetails
        .toLowerCase()
        .split(' ')
        .where((word) => word.length > 2)
        .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
        .where((word) => word.isNotEmpty));

    // Add words from address
    keywords.addAll(address
        .toLowerCase()
        .split(' ')
        .where((word) => word.length > 2)
        .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
        .where((word) => word.isNotEmpty));

    return keywords.toList();
  }

  /// Parse quantity string to number
  int _parseQuantity(String quantity) {
    try {
      return int.parse(quantity);
    } catch (e) {
      return 1; // Default value
    }
  }

  /// Parse string to double for coordinates
  double _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0; // Default value
    }
  }

  /// Get food posts by user
  Stream<QuerySnapshot> getUserFoodPosts(String uid) {
    return _foodPostsCollection
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all available food posts
  Stream<QuerySnapshot> getAvailableFoodPosts() {
    return _foodPostsCollection
        .where('status', isEqualTo: 'available')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get food posts by location (nearby)
  Future<List<QueryDocumentSnapshot>> getFoodPostsByLocation(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    // Note: For proper geolocation queries, you'd want to use a package like geoflutterfire
    // This is a simplified version

    try {
      QuerySnapshot snapshot = await _foodPostsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter by distance (basic implementation)
      return snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic>? location = data['location'];

        if (location == null) return false;

        double docLat = location['latitude'] ?? 0.0;
        double docLng = location['longitude'] ?? 0.0;

        double distance =
            _calculateDistance(latitude, longitude, docLat, docLng);
        return distance <= radiusInKm;
      }).toList();
    } catch (e) {
      print('Error getting nearby food posts: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates (simplified)
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Simplified distance calculation - for production use a proper library
    double deltaLat = (lat2 - lat1) * 111;
    double deltaLng = (lng2 - lng1) * 111;
    return sqrt(deltaLat * deltaLat + deltaLng * deltaLng);
  }

  /// Search food posts
  Future<List<QueryDocumentSnapshot>> searchFoodPosts(String query) async {
    try {
      String searchQuery = query.toLowerCase().trim();

      QuerySnapshot snapshot = await _foodPostsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .where('searchKeywords', arrayContainsAny: searchQuery.split(' '))
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error searching food posts: $e');
      return [];
    }
  }

  /////////////////////////////////////////////////////////////////
  ///

  /// Stream posts created by a particular user (ordered newest first)
  Stream<QuerySnapshot> getUserFoodPostsStream(String uid) {
    return _foodPostsCollection
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// public helper to get a user document (from volunteers or ngos)
  Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      DocumentSnapshot vol =
          await _firestore.collection('volunteers').doc(uid).get();
      if (vol.exists) return vol.data() as Map<String, dynamic>;
      DocumentSnapshot ngo = await _firestore.collection('ngos').doc(uid).get();
      if (ngo.exists) return ngo.data() as Map<String, dynamic>;
      return null;
    } catch (e) {
      print('getUserById error: $e');
      return null;
    }
  }

  /// delete post (verifies ownership)
  Future<bool> deleteFoodPost(String postId, String userUid) async {
    try {
      DocumentSnapshot doc = await _foodPostsCollection.doc(postId).get();
      if (!doc.exists) throw Exception('Post not found');
      final data = doc.data() as Map<String, dynamic>;
      if (data['userUid'] != userUid) {
        throw Exception('Not authorized to delete this post');
      }
      await _foodPostsCollection.doc(postId).delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// update status
  Future<bool> updateFoodPostStatus(String postId, String status,
      {String? claimedByUid}) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'claimed' && claimedByUid != null) {
        updateData['claimedBy'] = claimedByUid;
        updateData['claimedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }
      await _foodPostsCollection.doc(postId).update(updateData);
      return true;
    } catch (e) {
      print('updateFoodPostStatus error: $e');
      return false;
    }
  }

  /// optional: fetch single doc
  Future<DocumentSnapshot?> getFoodPostById(String postId) async {
    try {
      final doc = await _foodPostsCollection.doc(postId).get();
      return doc;
    } catch (e) {
      print('getFoodPostById error: $e');
      return null;
    }
  }
}
