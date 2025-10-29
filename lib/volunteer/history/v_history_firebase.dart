import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  static HistoryService? _instance;
  static HistoryService get instance => _instance ??= HistoryService._();
  HistoryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _foodPostsCollection =>
      _firestore.collection('food_posts');
  CollectionReference get _historyCollection =>
      _firestore.collection('food_history');

  /// Get posts created by user
  Stream<QuerySnapshot> getUserFoodHistory(String userUid) {
    print('📊 Streaming user posts for: $userUid');
    return _foodPostsCollection
        .where('userUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get available posts
  Stream<QuerySnapshot> getAvailableFoodPosts() {
    print('📊 Streaming available posts');
    return _foodPostsCollection
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get posts claimed by user
  Stream<QuerySnapshot> getClaimedFoodPosts(String userUid) {
    print('📊 Streaming claimed posts for: $userUid');
    return _foodPostsCollection
        .where('claimedBy', isEqualTo: userUid)
        .where('status', isEqualTo: 'claimed')
        .orderBy('claimedAt', descending: true)
        .snapshots();
  }

  /// Create history log
  Future<void> _logAction(String postId, String userUid, String action) async {
    try {
      await _historyCollection.add({
        'postId': postId,
        'userUid': userUid,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Logged action: $action');
    } catch (e) {
      print('⚠️ History log failed: $e');
    }
  }

  /// Claim a post
  Future<void> claimFoodPost(String postId, String userUid) async {
    print('🤝 Claiming post $postId by $userUid');

    try {
      // Get user data
      final userData = await _getUserData(userUid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Check post status
      final postDoc = await _foodPostsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final data = postDoc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'available') {
        throw Exception('Post is no longer available');
      }

      // Update post
      await _foodPostsCollection.doc(postId).update({
        'status': 'claimed',
        'claimedBy': userUid,
        'claimedByName': userData['name'] ?? 'Volunteer',
        'claimedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAction(postId, userUid, 'claimed');
      print('✅ Post claimed successfully');
    } catch (e) {
      print('❌ Claim failed: $e');
      rethrow;
    }
  }

  /// Complete a post
  Future<void> completeFoodPost(String postId, String userUid) async {
    print('✔️ Completing post $postId');

    try {
      final postDoc = await _foodPostsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final data = postDoc.data() as Map<String, dynamic>;

      if (data['claimedBy'] != userUid) {
        throw Exception('You can only complete posts you claimed');
      }

      if (data['status'] != 'claimed') {
        throw Exception('Post must be claimed to complete');
      }

      await _foodPostsCollection.doc(postId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAction(postId, userUid, 'completed');
      print('✅ Post completed successfully');
    } catch (e) {
      print('❌ Complete failed: $e');
      rethrow;
    }
  }

  /// Cancel claim
  Future<void> cancelClaim(String postId) async {
    print('❌ Cancelling claim for $postId');

    try {
      final userUid = _auth.currentUser?.uid;
      if (userUid == null) {
        throw Exception('User not authenticated');
      }

      final postDoc = await _foodPostsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final data = postDoc.data() as Map<String, dynamic>;

      if (data['claimedBy'] != userUid) {
        throw Exception('You can only cancel your own claims');
      }

      await _foodPostsCollection.doc(postId).update({
        'status': 'available',
        'claimedBy': FieldValue.delete(),
        'claimedByName': FieldValue.delete(),
        'claimedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAction(postId, userUid, 'cancelled');
      print('✅ Claim cancelled successfully');
    } catch (e) {
      print('❌ Cancel failed: $e');
      rethrow;
    }
  }

  /// Delete post
  Future<void> deleteFoodPost(String postId, String userUid) async {
    print('🗑️ Deleting post $postId');

    try {
      final postDoc = await _foodPostsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final data = postDoc.data() as Map<String, dynamic>;

      if (data['userUid'] != userUid) {
        throw Exception('You can only delete your own posts');
      }

      if (data['status'] == 'claimed') {
        throw Exception('Cannot delete a claimed post');
      }

      await _logAction(postId, userUid, 'deleted');
      await _foodPostsCollection.doc(postId).delete();
      print('✅ Post deleted successfully');
    } catch (e) {
      print('❌ Delete failed: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStats(String userUid) async {
    print('📊 Getting stats for $userUid');

    try {
      final myPostsSnapshot =
          await _foodPostsCollection.where('userUid', isEqualTo: userUid).get();

      final claimedByMeSnapshot = await _foodPostsCollection
          .where('claimedBy', isEqualTo: userUid)
          .get();

      int total = myPostsSnapshot.docs.length;
      int available = 0;
      int claimed = 0;
      int completed = 0;

      for (var doc in myPostsSnapshot.docs) {
        final status = (doc.data() as Map<String, dynamic>)['status'];
        if (status == 'available') available++;
        if (status == 'claimed') claimed++;
        if (status == 'completed') completed++;
      }

      int claimedFromOthers = claimedByMeSnapshot.docs.length;

      final stats = {
        'totalPosts': total,
        'availablePosts': available,
        'claimedPosts': claimed,
        'completedPosts': completed,
        'claimedFromOthers': claimedFromOthers,
      };

      print('✅ Stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Stats error: $e');
      return {
        'totalPosts': 0,
        'availablePosts': 0,
        'claimedPosts': 0,
        'completedPosts': 0,
        'claimedFromOthers': 0,
      };
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      var doc = await _firestore.collection('volunteers').doc(uid).get();
      if (doc.exists) return doc.data();

      doc = await _firestore.collection('ngos').doc(uid).get();
      if (doc.exists) return doc.data();

      return null;
    } catch (e) {
      print('❌ Get user data error: $e');
      return null;
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HistoryService {
//   static HistoryService? _instance;
//   static HistoryService get instance => _instance ??= HistoryService._();
//   HistoryService._();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Collection references
//   CollectionReference get _foodPostsCollection =>
//       _firestore.collection('food_posts');
//   CollectionReference get _historyCollection =>
//       _firestore.collection('food_history');

//   /// Get all food posts created by user
//   Stream<QuerySnapshot> getUserFoodHistory(String userUid) {
//     return _foodPostsCollection
//         .where('userUid', isEqualTo: userUid)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   /// Get available food posts (for claiming)
//   Stream<QuerySnapshot> getAvailableFoodPosts() {
//     return _foodPostsCollection
//         .where('status', isEqualTo: 'available')
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   /// Get posts claimed by current user
//   Stream<QuerySnapshot> getClaimedFoodPosts(String userUid) {
//     return _foodPostsCollection
//         .where('claimedBy', isEqualTo: userUid)
//         .where('status', isEqualTo: 'claimed')
//         .orderBy('claimedAt', descending: true)
//         .snapshots();
//   }

//   /// Create history record for tracking
//   Future<void> _createHistoryRecord(
//     String postId,
//     String userUid,
//     String action,
//   ) async {
//     try {
//       await _historyCollection.add({
//         'postId': postId,
//         'userUid': userUid,
//         'action': action, // claimed, completed, cancelled, deleted
//         'timestamp': FieldValue.serverTimestamp(),
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('⚠️ Error creating history record: $e');
//       // Non-critical error, don't throw
//     }
//   }

//   /// Claim a food post
//   Future<bool> claimFoodPost(String postId, String userUid) async {
//     try {
//       // Get user data first
//       final userData = await _getUserData(userUid);
//       if (userData == null) {
//         throw Exception('User data not found. Please log in again.');
//       }

//       // Check if post is still available
//       final postDoc = await _foodPostsCollection.doc(postId).get();
//       if (!postDoc.exists) {
//         throw Exception('Post not found');
//       }

//       final postData = postDoc.data() as Map<String, dynamic>;
//       if (postData['status'] != 'available') {
//         throw Exception('Post is no longer available');
//       }

//       // Update post status
//       await _foodPostsCollection.doc(postId).update({
//         'status': 'claimed',
//         'claimedBy': userUid,
//         'claimedByName': userData['name'] ?? 'Volunteer',
//         'claimedAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Create history record
//       await _createHistoryRecord(postId, userUid, 'claimed');

//       return true;
//     } catch (e) {
//       print("❌ claimFoodPost error: $e");
//       rethrow;
//     }
//   }

//   /// Complete a food post
//   Future<bool> completeFoodPost(String postId, String userUid) async {
//     try {
//       // Verify the post is claimed by this user
//       final postDoc = await _foodPostsCollection.doc(postId).get();
//       if (!postDoc.exists) {
//         throw Exception('Post not found');
//       }

//       final postData = postDoc.data() as Map<String, dynamic>;
//       if (postData['claimedBy'] != userUid) {
//         throw Exception('You can only complete posts you have claimed');
//       }

//       if (postData['status'] != 'claimed') {
//         throw Exception('Post must be claimed before completing');
//       }

//       // Update post to completed
//       await _foodPostsCollection.doc(postId).update({
//         'status': 'completed',
//         'completedAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Create history record
//       await _createHistoryRecord(postId, userUid, 'completed');

//       return true;
//     } catch (e) {
//       print("❌ completeFoodPost error: $e");
//       rethrow;
//     }
//   }

//   /// Cancel claim on a food post
//   Future<bool> cancelClaim(String postId) async {
//     try {
//       final userUid = _auth.currentUser?.uid;
//       if (userUid == null) {
//         throw Exception('User not authenticated');
//       }

//       // Verify the post is claimed by this user
//       final postDoc = await _foodPostsCollection.doc(postId).get();
//       if (!postDoc.exists) {
//         throw Exception('Post not found');
//       }

//       final postData = postDoc.data() as Map<String, dynamic>;
//       if (postData['claimedBy'] != userUid) {
//         throw Exception('You can only cancel your own claims');
//       }

//       // Reset post to available
//       await _foodPostsCollection.doc(postId).update({
//         'status': 'available',
//         'claimedBy': FieldValue.delete(),
//         'claimedByName': FieldValue.delete(),
//         'claimedAt': FieldValue.delete(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Create history record
//       await _createHistoryRecord(postId, userUid, 'cancelled');

//       return true;
//     } catch (e) {
//       print("❌ cancelClaim error: $e");
//       rethrow;
//     }
//   }

//   /// Delete food post (only by owner)
//   Future<bool> deleteFoodPost(String postId, String userUid) async {
//     try {
//       final postDoc = await _foodPostsCollection.doc(postId).get();

//       if (!postDoc.exists) {
//         throw Exception('Post not found');
//       }

//       final postData = postDoc.data() as Map<String, dynamic>;

//       // Verify ownership
//       if (postData['userUid'] != userUid) {
//         throw Exception('You can only delete your own posts');
//       }

//       // Check if post is claimed - optional: prevent deletion if claimed
//       if (postData['status'] == 'claimed') {
//         throw Exception(
//             'Cannot delete a claimed post. Please ask the volunteer to cancel first.');
//       }

//       // Create history record before deletion
//       await _createHistoryRecord(postId, userUid, 'deleted');

//       // Delete the post
//       await _foodPostsCollection.doc(postId).delete();

//       return true;
//     } catch (e) {
//       print("❌ deleteFoodPost error: $e");
//       rethrow;
//     }
//   }

//   /// Get user statistics
//   Future<Map<String, int>> getUserStats(String userUid) async {
//     try {
//       // Posts created by user
//       final myPostsSnapshot =
//           await _foodPostsCollection.where('userUid', isEqualTo: userUid).get();

//       // Posts claimed by user
//       final claimedByMeSnapshot = await _foodPostsCollection
//           .where('claimedBy', isEqualTo: userUid)
//           .get();

//       // Calculate stats for posts I created
//       int totalPostsCreated = myPostsSnapshot.docs.length;
//       int availablePosts = myPostsSnapshot.docs
//           .where((doc) =>
//               (doc.data() as Map<String, dynamic>)['status'] == 'available')
//           .length;
//       int myPostsClaimed = myPostsSnapshot.docs
//           .where((doc) =>
//               (doc.data() as Map<String, dynamic>)['status'] == 'claimed')
//           .length;
//       int myPostsCompleted = myPostsSnapshot.docs
//           .where((doc) =>
//               (doc.data() as Map<String, dynamic>)['status'] == 'completed')
//           .length;

//       // Posts I claimed from others
//       int postsIClaimedFromOthers = claimedByMeSnapshot.docs.length;
//       int postsICompleted = claimedByMeSnapshot.docs
//           .where((doc) =>
//               (doc.data() as Map<String, dynamic>)['status'] == 'completed')
//           .length;

//       return {
//         'totalPosts': totalPostsCreated,
//         'availablePosts': availablePosts,
//         'claimedPosts': myPostsClaimed,
//         'completedPosts': myPostsCompleted,
//         'postsIClaimedFromOthers': postsIClaimedFromOthers,
//         'postsICompleted': postsICompleted,
//       };
//     } catch (e) {
//       print("❌ getUserStats error: $e");
//       return {
//         'totalPosts': 0,
//         'availablePosts': 0,
//         'claimedPosts': 0,
//         'completedPosts': 0,
//         'postsIClaimedFromOthers': 0,
//         'postsICompleted': 0,
//       };
//     }
//   }

//   /// Get user data from volunteers or ngos collection
//   Future<Map<String, dynamic>?> _getUserData(String uid) async {
//     try {
//       // Try volunteers collection first
//       DocumentSnapshot volunteerDoc =
//           await _firestore.collection('volunteers').doc(uid).get();
//       if (volunteerDoc.exists) {
//         return volunteerDoc.data() as Map<String, dynamic>?;
//       }

//       // Try ngos collection
//       DocumentSnapshot ngoDoc =
//           await _firestore.collection('ngos').doc(uid).get();
//       if (ngoDoc.exists) {
//         return ngoDoc.data() as Map<String, dynamic>?;
//       }

//       return null;
//     } catch (e) {
//       print("❌ _getUserData error: $e");
//       return null;
//     }
//   }
// }




// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // import 'package:get_storage/get_storage.dart';

// // class HistoryService {
// //   static HistoryService? _instance;
// //   static HistoryService get instance => _instance ??= HistoryService._();
// //   HistoryService._();

// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final GetStorage _storage = GetStorage();

// //   // Collection references
// //   CollectionReference get _foodPostsCollection =>
// //       _firestore.collection('food_posts');
// //   CollectionReference get _historyCollection =>
// //       _firestore.collection('food_history');

// //   /// Get all food posts history for current user
// //   Stream<QuerySnapshot> getUserFoodHistory(String userUid) {
// //     return _foodPostsCollection
// //         .where('userUid', isEqualTo: userUid)
// //         .orderBy('createdAt', descending: true)
// //         .snapshots();
// //   }

// //   /// Get food history with additional details
// //   Stream<List<FoodPostModel>> getDetailedFoodHistory(String userUid) {
// //     return _foodPostsCollection
// //         .where('userUid', isEqualTo: userUid)
// //         .orderBy('createdAt', descending: true)
// //         .snapshots()
// //         .asyncMap((snapshot) async {
// //       List<FoodPostModel> posts = [];

// //       for (var doc in snapshot.docs) {
// //         try {
// //           final post = FoodPostModel.fromDoc(doc);
// //           posts.add(post);
// //         } catch (e) {
// //           print('Error parsing document ${doc.id}: $e');
// //         }
// //       }

// //       return posts;
// //     });
// //   }

// //   /// Get available food posts (for claiming)
// //   Stream<QuerySnapshot> getAvailableFoodPosts() {
// //     return _foodPostsCollection
// //         .where('status', isEqualTo: 'available')
// //         .orderBy('createdAt', descending: true)
// //         .snapshots();
// //   }

// //   /// Get claimed food posts by current user
// //   Stream<QuerySnapshot> getClaimedFoodPosts(String userUid) {
// //     return _foodPostsCollection
// //         .where('claimedBy', isEqualTo: userUid)
// //         .where('status', isEqualTo: 'claimed')
// //         .orderBy('claimedAt', descending: true)
// //         .snapshots();
// //   }

// //   /// Create history record for tracking
// //   Future<void> _createHistoryRecord(
// //       String postId, String userUid, String action) async {
// //     try {
// //       await _historyCollection.add({
// //         'postId': postId,
// //         'userUid': userUid,
// //         'action': action, // claimed, completed, etc.
// //         'timestamp': FieldValue.serverTimestamp(),
// //         'createdAt': FieldValue.serverTimestamp(),
// //       });
// //     } catch (e) {
// //       print('Error creating history record: $e');
// //     }
// //   }

// //   Future<bool> claimFoodPost(String postId, String userUid) async {
// //     try {
// //       final userData = await _getUserData(userUid);
// //       if (userData == null) throw Exception('User data not found');

// //       await _foodPostsCollection.doc(postId).update({
// //         'status': 'claimed',
// //         'claimedBy': userUid,
// //         'claimedByName': userData['name'] ?? 'Volunteer',
// //         'claimedAt': FieldValue.serverTimestamp(),
// //         'updatedAt': FieldValue.serverTimestamp(),
// //       });

// //       await _createHistoryRecord(postId, userUid, 'claimed'); // optional log
// //       return true;
// //     } catch (e) {
// //       print("❌ claimFoodPost error: $e");

// //       throw Exception('Failed to claim food post: ${e.toString()}');
// //     }
// //   }

// //   Future<bool> completeFoodPost(String postId, String userUid) async {
// //     try {
// //       await _foodPostsCollection.doc(postId).update({
// //         'status': 'completed',
// //         'completedAt': FieldValue.serverTimestamp(),
// //         'updatedAt': FieldValue.serverTimestamp(),
// //       });

// //       await _createHistoryRecord(postId, userUid, 'completed');
// //       return true;
// //     } catch (e) {
// //       print("❌ completeFoodPost error: $e");
// //       throw Exception('Failed to complete food post: ${e.toString()}');
// //     }
// //   }

// //   /// Cancel claim on a food post
// //   Future<bool> cancelClaim(String postId) async {
// //     try {
// //       await _foodPostsCollection.doc(postId).update({
// //         'status': 'available',
// //         'claimedBy': null,
// //         'claimedAt': null,
// //         'updatedAt': FieldValue.serverTimestamp(),
// //       });
// //       return true;
// //     } catch (e) {
// //       throw Exception('Failed to cancel claim: ${e.toString()}');
// //     }
// //   }

// //   /// Delete food post (with authorization check)
// //   Future<bool> deleteFoodPost(String postId, String userUid) async {
// //     try {
// //       DocumentSnapshot doc = await _foodPostsCollection.doc(postId).get();
// //       if (!doc.exists) throw Exception('Post not found');

// //       final data = doc.data() as Map<String, dynamic>;
// //       if (data['userUid'] != userUid) {
// //         throw Exception('Not authorized to delete this post');
// //       }

// //       await _foodPostsCollection.doc(postId).delete();
// //       return true;
// //     } catch (e) {
// //       throw Exception('Failed to delete post: ${e.toString()}');
// //     }
// //   }

// //   /// Get statistics for user
// //   Future<Map<String, int>> getUserStats(String userUid) async {
// //     try {
// //       final postsSnapshot =
// //           await _foodPostsCollection.where('userUid', isEqualTo: userUid).get();

// //       final claimedSnapshot = await _foodPostsCollection
// //           .where('claimedBy', isEqualTo: userUid)
// //           .get();

// //       int totalPosts = postsSnapshot.docs.length;
// //       int availablePosts = postsSnapshot.docs
// //           .where((doc) =>
// //               (doc.data() as Map<String, dynamic>)['status'] == 'available')
// //           .length;
// //       int claimedPosts = claimedSnapshot.docs.length;
// //       int completedPosts = postsSnapshot.docs
// //           .where((doc) =>
// //               (doc.data() as Map<String, dynamic>)['status'] == 'completed')
// //           .length;

// //       return {
// //         'totalPosts': totalPosts,
// //         'availablePosts': availablePosts,
// //         'claimedPosts': claimedPosts,
// //         'completedPosts': completedPosts,
// //       };
// //     } catch (e) {
// //       return {
// //         'totalPosts': 0,
// //         'availablePosts': 0,
// //         'claimedPosts': 0,
// //         'completedPosts': 0,
// //       };
// //     }
// //   }

// //   /// Get user data from volunteers or ngos collection
// //   Future<Map<String, dynamic>?> _getUserData(String uid) async {
// //     try {
// //       DocumentSnapshot volunteerDoc =
// //           await _firestore.collection('volunteers').doc(uid).get();
// //       if (volunteerDoc.exists)
// //         return volunteerDoc.data() as Map<String, dynamic>?;

// //       DocumentSnapshot ngoDoc =
// //           await _firestore.collection('ngos').doc(uid).get();
// //       if (ngoDoc.exists) return ngoDoc.data() as Map<String, dynamic>?;

// //       return null;
// //     } catch (e) {
// //       return null;
// //     }
// //   }
// // }
