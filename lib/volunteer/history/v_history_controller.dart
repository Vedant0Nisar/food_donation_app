import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_donation_app/volunteer/history/v_history_firebase.dart';
import 'package:food_donation_app/volunteer/history/v_model.dart';
import 'package:get/get.dart';

class FoodPostController extends GetxController {
  final HistoryService _historyService = HistoryService.instance;

  // Observable lists
  final RxList<FoodPostModel> myPosts = <FoodPostModel>[].obs;
  final RxList<FoodPostModel> availablePosts = <FoodPostModel>[].obs;
  final RxList<FoodPostModel> claimedPosts = <FoodPostModel>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isMyPostsLoading = true.obs;
  final RxBool isAvailablePostsLoading = true.obs;
  final RxBool isClaimedPostsLoading = true.obs;
  final RxMap<String, int> userStats = <String, int>{}.obs;

  // Stream subscriptions
  StreamSubscription? _myPostsSubscription;
  StreamSubscription? _availablePostsSubscription;
  StreamSubscription? _claimedPostsSubscription;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    print('🟢 Controller onInit - currentUid: $currentUid');
    if (currentUid.isNotEmpty) {
      setupAllListeners();
      _loadStats();
    } else {
      print('❌ No user logged in');
    }
  }

  @override
  void onClose() {
    print('🔴 Controller onClose - disposing subscriptions');
    _disposeAllListeners();
    super.onClose();
  }

  void _disposeAllListeners() {
    _myPostsSubscription?.cancel();
    _availablePostsSubscription?.cancel();
    _claimedPostsSubscription?.cancel();
  }

  void setupAllListeners() {
    print('🔧 Setting up ALL listeners');
    _setupMyPostsListener();
    _setupAvailablePostsListener();
    _setupClaimedPostsListener();
  }

  void _setupMyPostsListener() {
    print('📡 Setting up MY POSTS listener');
    _myPostsSubscription?.cancel();
    isMyPostsLoading.value = true;

    _myPostsSubscription =
        _historyService.getUserFoodHistory(currentUid).listen(
      (snapshot) {
        print('📥 MY POSTS stream update: ${snapshot.docs.length} docs');
        myPosts.value =
            snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
        isMyPostsLoading.value = false;
        print('✅ My posts updated: ${myPosts.length}');
      },
      onError: (e) {
        print('❌ My posts stream error: $e');
        isMyPostsLoading.value = false;
      },
    );
  }

  void _setupAvailablePostsListener() {
    print('📡 Setting up AVAILABLE POSTS listener');
    _availablePostsSubscription?.cancel();
    isAvailablePostsLoading.value = true;

    _availablePostsSubscription =
        _historyService.getAvailableFoodPosts().listen(
      (snapshot) {
        print('📥 AVAILABLE POSTS stream update: ${snapshot.docs.length} docs');
        // Filter out current user's posts
        availablePosts.value = snapshot.docs
            .map((doc) => FoodPostModel.fromDoc(doc))
            // .where((post) => post.userUid != currentUid)
            .toList();
        isAvailablePostsLoading.value = false;
        print('✅ Available posts updated: ${availablePosts.length}');
      },
      onError: (e) {
        print('❌ Available posts stream error: $e');
        isAvailablePostsLoading.value = false;
      },
    );
  }

  void _setupClaimedPostsListener() {
    print('📡 Setting up CLAIMED POSTS listener');
    _claimedPostsSubscription?.cancel();
    isClaimedPostsLoading.value = true;

    _claimedPostsSubscription =
        _historyService.getClaimedFoodPosts(currentUid).listen(
      (snapshot) {
        print('📥 CLAIMED POSTS stream update: ${snapshot.docs.length} docs');
        claimedPosts.value =
            snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
        isClaimedPostsLoading.value = false;
        print('✅ Claimed posts updated: ${claimedPosts.length}');
      },
      onError: (e) {
        print('❌ Claimed posts stream error: $e');
        isClaimedPostsLoading.value = false;
      },
    );
  }

  Future<void> _loadStats() async {
    try {
      print('📊 Loading stats...');
      final stats = await _historyService.getUserStats(currentUid);
      userStats.value = stats;
      print('✅ Stats loaded: $stats');
    } catch (e) {
      print("❌ Stats error: $e");
    }
  }

  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');

    // Re-setup all listeners to force refresh
    setupAllListeners();
    await _loadStats();

    Get.snackbar(
      "",
      "",
      titleText: const SizedBox.shrink(),
      messageText: const Text(
        "Refreshed!",
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.green.withOpacity(0.8),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(10),
    );
  }

  Future<void> deletePost(String id) async {
    try {
      isLoading.value = true;
      print('🗑️ Deleting post: $id');

      await _historyService.deleteFoodPost(id, currentUid);

      Get.snackbar(
        "Success",
        "Post deleted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
      );

      // Refresh all data
      await _loadStats();
      _setupMyPostsListener();
    } catch (e) {
      print("❌ Delete error: $e");
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> claimPost(String postId) async {
    try {
      isLoading.value = true;
      print('🤝 Claiming post: $postId');

      await _historyService.claimFoodPost(postId, currentUid);

      Get.snackbar(
        "Success",
        "Post claimed successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
      );

      // Force refresh all listeners
      print('🔄 Refreshing all listeners after claim');
      await _loadStats();
      _setupAvailablePostsListener();
      _setupClaimedPostsListener();
    } catch (e) {
      print("❌ Claim error: $e");
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completePost(String postId) async {
    try {
      isLoading.value = true;
      print('✔️ Completing post: $postId');

      await _historyService.completeFoodPost(postId, currentUid);

      Get.snackbar(
        "Success",
        "Post marked as completed!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
      );

      // Force refresh all listeners
      print('🔄 Refreshing all listeners after complete');
      await _loadStats();
      _setupClaimedPostsListener();
      _setupMyPostsListener();
    } catch (e) {
      print("❌ Complete error: $e");
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelClaim(String postId) async {
    try {
      isLoading.value = true;
      print('❌ Cancelling claim: $postId');

      await _historyService.cancelClaim(postId);

      Get.snackbar(
        "Success",
        "Claim cancelled successfully!",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
      );

      // Force refresh all listeners
      print('🔄 Refreshing all listeners after cancel');
      await _loadStats();
      _setupClaimedPostsListener();
      _setupAvailablePostsListener();
    } catch (e) {
      print("❌ Cancel error: $e");
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'claimed':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}











// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:food_donation_app/volunteer/history/v_history_firebase.dart';
// import 'package:food_donation_app/volunteer/history/v_model.dart';
// import 'package:get/get.dart';

// class FoodPostController extends GetxController {
//   final HistoryService _historyService = HistoryService.instance;

//   // Observable lists
//   final RxList<FoodPostModel> myPosts = <FoodPostModel>[].obs;
//   final RxList<FoodPostModel> availablePosts = <FoodPostModel>[].obs;
//   final RxList<FoodPostModel> claimedPosts = <FoodPostModel>[].obs;

//   final RxBool isLoading = false.obs;
//   final RxMap<String, int> userStats = <String, int>{}.obs;

//   // Stream subscriptions
//   StreamSubscription? _myPostsSubscription;
//   StreamSubscription? _availablePostsSubscription;
//   StreamSubscription? _claimedPostsSubscription;

//   String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

//   @override
//   void onInit() {
//     super.onInit();
//     print('🟢 Controller onInit - currentUid: $currentUid');
//     if (currentUid.isNotEmpty) {
//       _setupListeners();
//       _loadStats();
//     } else {
//       print('❌ No user logged in');
//     }
//   }

//   @override
//   void onClose() {
//     print('🔴 Controller onClose - disposing subscriptions');
//     _myPostsSubscription?.cancel();
//     _availablePostsSubscription?.cancel();
//     _claimedPostsSubscription?.cancel();
//     super.onClose();
//   }

//   void _setupListeners() {
//     print('🔧 Setting up listeners');

//     // Listen to my posts
//     _myPostsSubscription?.cancel();
//     _myPostsSubscription =
//         _historyService.getUserFoodHistory(currentUid).listen(
//       (snapshot) {
//         myPosts.value =
//             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
//         print('✅ My posts: ${myPosts.length}');
//       },
//       onError: (e) => print('❌ My posts error: $e'),
//     );

//     // Listen to available posts (exclude my own posts)
//     _availablePostsSubscription?.cancel();
//     _availablePostsSubscription =
//         _historyService.getAvailableFoodPosts().listen(
//       (snapshot) {
//         // Filter out posts created by current user
//         availablePosts.value = snapshot.docs
//             .map((doc) => FoodPostModel.fromDoc(doc))
//             .where((post) => post.userUid != currentUid)
//             .toList();
//         print('✅ Available posts: ${availablePosts.length}');
//       },
//       onError: (e) => print('❌ Available posts error: $e'),
//     );

//     // Listen to claimed posts
//     _claimedPostsSubscription?.cancel();
//     _claimedPostsSubscription =
//         _historyService.getClaimedFoodPosts(currentUid).listen(
//       (snapshot) {
//         claimedPosts.value =
//             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
//         print('✅ Claimed posts: ${claimedPosts.length}');
//       },
//       onError: (e) => print('❌ Claimed posts error: $e'),
//     );
//   }

//   Future<void> _loadStats() async {
//     try {
//       final stats = await _historyService.getUserStats(currentUid);
//       userStats.value = stats;
//       print('✅ Stats loaded: $stats');
//     } catch (e) {
//       print("❌ Stats error: $e");
//     }
//   }

//   Future<void> refreshData() async {
//     print('🔄 Refreshing data');
//     await _loadStats();
//   }

//   Future<void> deletePost(String id) async {
//     if (isLoading.value) return;

//     try {
//       isLoading.value = true;
//       print('🗑️ Deleting post: $id');

//       await _historyService.deleteFoodPost(id, currentUid);

//       Get.snackbar(
//         "Success",
//         "Post deleted successfully",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 2),
//       );

//       await _loadStats();
//     } catch (e) {
//       print("❌ Delete error: $e");
//       Get.snackbar(
//         "Error",
//         e.toString().replaceAll('Exception: ', ''),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 3),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> claimPost(String postId) async {
//     if (isLoading.value) return;

//     try {
//       isLoading.value = true;
//       print('🤝 Claiming post: $postId');

//       await _historyService.claimFoodPost(postId, currentUid);

//       Get.snackbar(
//         "Success",
//         "Post claimed successfully!",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 2),
//       );

//       await _loadStats();
//     } catch (e) {
//       print("❌ Claim error: $e");
//       Get.snackbar(
//         "Error",
//         e.toString().replaceAll('Exception: ', ''),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 3),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> completePost(String postId) async {
//     if (isLoading.value) return;

//     try {
//       isLoading.value = true;
//       print('✔️ Completing post: $postId');

//       await _historyService.completeFoodPost(postId, currentUid);

//       Get.snackbar(
//         "Success",
//         "Post marked as completed!",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 2),
//       );

//       await _loadStats();
//     } catch (e) {
//       print("❌ Complete error: $e");
//       Get.snackbar(
//         "Error",
//         e.toString().replaceAll('Exception: ', ''),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 3),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> cancelClaim(String postId) async {
//     if (isLoading.value) return;

//     try {
//       isLoading.value = true;
//       print('❌ Cancelling claim: $postId');

//       await _historyService.cancelClaim(postId);

//       Get.snackbar(
//         "Success",
//         "Claim cancelled successfully!",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 2),
//       );

//       await _loadStats();
//     } catch (e) {
//       print("❌ Cancel error: $e");
//       Get.snackbar(
//         "Error",
//         e.toString().replaceAll('Exception: ', ''),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         duration: const Duration(seconds: 3),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Color getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'available':
//         return Colors.green;
//       case 'claimed':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       case 'expired':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }

// // import 'dart:async';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:food_donation_app/volunteer/history/v_history_firebase.dart';
// // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // import 'package:get/get.dart';

// // class FoodPostController extends GetxController {
// //   final HistoryService _historyService = HistoryService.instance;

// //   // Observable lists for different types of posts
// //   final RxList<FoodPostModel> myPosts = <FoodPostModel>[].obs;
// //   final RxList<FoodPostModel> availablePosts = <FoodPostModel>[].obs;
// //   final RxList<FoodPostModel> claimedPosts = <FoodPostModel>[].obs;

// //   final RxBool isLoading = false.obs;
// //   final RxMap<String, int> userStats = <String, int>{}.obs;

// //   // Stream subscriptions for proper disposal
// //   StreamSubscription? _myPostsSubscription;
// //   StreamSubscription? _availablePostsSubscription;
// //   StreamSubscription? _claimedPostsSubscription;

// //   String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

// //   @override
// //   void onInit() {
// //     super.onInit();
// //     if (currentUid.isNotEmpty) {
// //       initializeListeners();
// //       fetchUserStats();
// //     }
// //   }

// //   @override
// //   void onClose() {
// //     // Clean up subscriptions to prevent memory leaks
// //     _myPostsSubscription?.cancel();
// //     _availablePostsSubscription?.cancel();
// //     _claimedPostsSubscription?.cancel();
// //     super.onClose();
// //   }

// //   /// Initialize all listeners once
// //   void initializeListeners() {
// //     _listenToMyPosts();
// //     _listenToAvailablePosts();
// //     _listenToClaimedPosts();
// //   }

// //   /// Listen to posts created by current user
// //   void _listenToMyPosts() {
// //     _myPostsSubscription?.cancel();
// //     _myPostsSubscription =
// //         _historyService.getUserFoodHistory(currentUid).listen(
// //       (snapshot) {
// //         myPosts.value =
// //             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// //         print('✅ My posts updated: ${myPosts.length} posts');
// //       },
// //       onError: (error) {
// //         print('❌ Error listening to my posts: $error');
// //         _showError("Failed to load your posts");
// //       },
// //     );
// //   }

// //   /// Listen to available posts (for claiming)
// //   void _listenToAvailablePosts() {
// //     _availablePostsSubscription?.cancel();
// //     _availablePostsSubscription =
// //         _historyService.getAvailableFoodPosts().listen(
// //       (snapshot) {
// //         availablePosts.value =
// //             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// //         print('✅ Available posts updated: ${availablePosts.length} posts');
// //       },
// //       onError: (error) {
// //         print('❌ Error listening to available posts: $error');
// //         _showError("Failed to load available posts");
// //       },
// //     );
// //   }

// //   /// Listen to posts claimed by current user
// //   void _listenToClaimedPosts() {
// //     _claimedPostsSubscription?.cancel();
// //     _claimedPostsSubscription =
// //         _historyService.getClaimedFoodPosts(currentUid).listen(
// //       (snapshot) {
// //         claimedPosts.value =
// //             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// //         print('✅ Claimed posts updated: ${claimedPosts.length} posts');
// //       },
// //       onError: (error) {
// //         print('❌ Error listening to claimed posts: $error');
// //         _showError("Failed to load claimed posts");
// //       },
// //     );
// //   }

// //   /// Fetch user statistics
// //   Future<void> fetchUserStats() async {
// //     try {
// //       final stats = await _historyService.getUserStats(currentUid);
// //       userStats.value = stats;
// //       print('✅ Stats updated: $stats');
// //     } catch (e) {
// //       print("❌ Error fetching user stats: $e");
// //       // Don't show error to user for stats - not critical
// //     }
// //   }

// //   /// Delete a post (only if user is the owner)
// //   Future<void> deletePost(String id) async {
// //     try {
// //       isLoading.value = true;

// //       final success = await _historyService.deleteFoodPost(id, currentUid);

// //       if (success) {
// //         _showSuccess("Post deleted successfully");
// //         await fetchUserStats();
// //         initializeListeners(); // Refresh all lists
// //       }
// //     } catch (e) {
// //       print("❌ deletePost error: $e");
// //       _showError("Failed to delete post: ${e.toString()}");
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

// //   /// Claim an available post
// //   Future<void> claimPost(String postId) async {
// //     try {
// //       isLoading.value = true;

// //       final success = await _historyService.claimFoodPost(postId, currentUid);

// //       if (success) {
// //         _showSuccess("Food post claimed successfully!");
// //         await fetchUserStats();
// //         initializeListeners(); // Refresh all lists
// //       }
// //     } catch (e) {
// //       print("❌ claimPost error: $e");
// //       _showError("Failed to claim post: ${e.toString()}");
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

// //   /// Mark a claimed post as completed
// //   Future<void> completePost(String postId) async {
// //     try {
// //       isLoading.value = true;

// //       final success =
// //           await _historyService.completeFoodPost(postId, currentUid);

// //       if (success) {
// //         _showSuccess("Food post marked as completed!");
// //         await fetchUserStats();
// //         initializeListeners(); // Refresh all lists
// //       }
// //     } catch (e) {
// //       print("❌ completePost error: $e");
// //       _showError("Failed to complete post: ${e.toString()}");
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

// //   /// Cancel claim on a post
// //   Future<void> cancelClaim(String postId) async {
// //     try {
// //       isLoading.value = true;

// //       final success = await _historyService.cancelClaim(postId);

// //       if (success) {
// //         _showSuccess("Claim cancelled successfully!");
// //         await fetchUserStats();
// //         initializeListeners(); // Refresh all lists
// //       }
// //     } catch (e) {
// //       print("❌ cancelClaim error: $e");
// //       _showError("Failed to cancel claim: ${e.toString()}");
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

// //   /// Helper methods for UI
// //   Color getStatusColor(String status) {
// //     switch (status.toLowerCase()) {
// //       case 'available':
// //         return Colors.green;
// //       case 'claimed':
// //         return Colors.orange;
// //       case 'completed':
// //         return Colors.blue;
// //       case 'expired':
// //         return Colors.red;
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   IconData getStatusIcon(String status) {
// //     switch (status.toLowerCase()) {
// //       case 'available':
// //         return Icons.check_circle;
// //       case 'claimed':
// //         return Icons.shopping_cart;
// //       case 'completed':
// //         return Icons.verified;
// //       case 'expired':
// //         return Icons.error;
// //       default:
// //         return Icons.help;
// //     }
// //   }

// //   // Snackbar helpers
// //   void _showSuccess(String message) {
// //     Get.snackbar(
// //       "Success",
// //       message,
// //       backgroundColor: Colors.green.withOpacity(0.8),
// //       colorText: Colors.white,
// //       snackPosition: SnackPosition.BOTTOM,
// //       duration: const Duration(seconds: 2),
// //     );
// //   }

// //   void _showError(String message) {
// //     Get.snackbar(
// //       "Error",
// //       message,
// //       backgroundColor: Colors.red.withOpacity(0.8),
// //       colorText: Colors.white,
// //       snackPosition: SnackPosition.BOTTOM,
// //       duration: const Duration(seconds: 3),
// //     );
// //   }
// // }

// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:food_donation_app/volunteer/history/v_history_firebase.dart';
// // // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // // import 'package:get/get.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:get_storage/get_storage.dart';

// // // class FoodPostController extends GetxController {
// // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// // //   final GetStorage _storage = GetStorage();
// // //   final HistoryService _historyService = HistoryService.instance;

// // //   // Observable lists for different types of posts
// // //   RxList<FoodPostModel> myPosts = <FoodPostModel>[].obs;
// // //   RxList<FoodPostModel> availablePosts = <FoodPostModel>[].obs;
// // //   RxList<FoodPostModel> claimedPosts = <FoodPostModel>[].obs;

// // //   RxBool isLoading = false.obs;
// // //   RxMap<String, int> userStats = <String, int>{}.obs;

// // //   final user = FirebaseAuth.instance.currentUser;
// // //   var currentUid = "".obs;
// // //   // Add these new Rx variables
// // //   @override
// // //   void onInit() {
// // //     super.onInit();
// // //     currentUid.value = FirebaseAuth.instance.currentUser?.uid ?? '';

// // //     if (currentUid.value.isNotEmpty) {
// // //       initializeHistory();
// // //       // Add a delay to see initial state
// // //     }
// // //   }

// // //   /// Replace your existing initialization with this
// // //   void initializeHistory() {
// // //     fetchUserStats();
// // //     listenToMyPosts();
// // //     listenToAvailablePosts();
// // //     listenToClaimedPosts();
// // //   }

// // //   /// Fetch user statistics
// // //   Future<void> fetchUserStats() async {
// // //     try {
// // //       final stats = await _historyService.getUserStats(currentUid.value);
// // //       userStats.value = stats;
// // //     } catch (e) {
// // //       print("❌ Error fetching user stats: $e");
// // //     }
// // //   }

// // //   void listenToMyPosts() {
// // //     _historyService.getUserFoodHistory(currentUid.value).listen(
// // //       (snapshot) {
// // //         myPosts.value =
// // //             snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// // //       },
// // //       onError: (error) {
// // //         print('❌ listenToMyPosts error: $error');
// // //         Get.snackbar("Error", "Failed to load your posts: $error");
// // //       },
// // //     );
// // //   }

// // //   /// Listen to available posts (for claiming)
// // //   /// Listen to available posts (for claiming)
// // //   void listenToAvailablePosts() {
// // //     _historyService.getAvailableFoodPosts().listen((snapshot) {
// // //       print("📢 Available posts updated: ${snapshot.docs.length} posts");
// // //       availablePosts.value =
// // //           snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// // //     }, onError: (error) {
// // //       print("❌ Error listening to available posts: $error");
// // //     });
// // //   }

// // //   /// Listen to posts claimed by current user
// // //   void listenToClaimedPosts() {
// // //     _historyService.getClaimedFoodPosts(currentUid.value).listen((snapshot) {
// // //       print("📢 Claimed posts updated: ${snapshot.docs.length} posts");
// // //       claimedPosts.value =
// // //           snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// // //     }, onError: (error) {
// // //       print("❌ Error listening to claimed posts: $error");
// // //     });
// // //   }

// // //   /// Fetch all food posts for current user (one-time fetch)
// // //   Future<void> fetchUserPosts(String userUid) async {
// // //     try {
// // //       isLoading.value = true;
// // //       print("📦 Fetching posts for userUid: $userUid");

// // //       final snapshot = await _firestore
// // //           .collection('food_posts')
// // //           .where('userUid', isEqualTo: userUid)
// // //           .orderBy('createdAt', descending: true)
// // //           .get();

// // //       print("✅ Found ${snapshot.docs.length} posts");

// // //       myPosts.value =
// // //           snapshot.docs.map((doc) => FoodPostModel.fromDoc(doc)).toList();
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to load posts: $e");
// // //       print("❌ fetchUserPosts error: $e");
// // //     } finally {
// // //       isLoading.value = false;
// // //     }
// // //   }

// // //   /// Add a new food post
// // //   Future<void> addFoodPost(FoodPostModel post) async {
// // //     try {
// // //       await _firestore.collection('food_posts').add(post.toMap());
// // //       Get.snackbar("Success", "Food post added successfully!");
// // //       // Refresh stats
// // //       initializeHistory();
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to add post: $e");
// // //       print("❌ addFoodPost error: $e");
// // //     }
// // //   }

// // //   Future<void> deletePost(String id) async {
// // //     try {
// // //       isLoading.value = true;
// // //       final success =
// // //           await _historyService.deleteFoodPost(id, currentUid.value);
// // //       if (success) {
// // //         // Remove from all lists immediately
// // //         myPosts.removeWhere((post) => post.id == id);
// // //         availablePosts.removeWhere((post) => post.id == id);
// // //         claimedPosts.removeWhere((post) => post.id == id);

// // //         Get.snackbar("Deleted", "Post deleted successfully");
// // //         // Refresh stats
// // //         fetchUserStats();
// // //       }
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to delete: $e");
// // //       print("❌ deletePost error: $e");
// // //     } finally {
// // //       isLoading.value = false;
// // //     }
// // //   }

// // //   Future<void> claimPost(String postId) async {
// // //     try {
// // //       isLoading.value = true;
// // //       final success =
// // //           await _historyService.claimFoodPost(postId, currentUid.value);
// // //       if (success) {
// // //         Get.snackbar("Success", "Food post claimed successfully!");
// // //         // Remove from available posts immediately
// // //         availablePosts.removeWhere((post) => post.id == postId);
// // //         // Refresh stats
// // //         fetchUserStats();
// // //       }
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to claim post: $e");
// // //       print("❌ claimPost error: $e");
// // //     } finally {
// // //       isLoading.value = false;
// // //     }
// // //   }

// // //   Future<void> completePost(String postId) async {
// // //     try {
// // //       isLoading.value = true;
// // //       final success =
// // //           await _historyService.completeFoodPost(postId, currentUid.value);
// // //       if (success) {
// // //         Get.snackbar("Success", "Food post marked as completed!");
// // //         // Remove from claimed posts immediately
// // //         claimedPosts.removeWhere((post) => post.id == postId);
// // //         // Refresh stats
// // //         fetchUserStats();
// // //       }
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to complete post: $e");
// // //       print("❌ completePost error: $e");
// // //     } finally {
// // //       isLoading.value = false;
// // //     }
// // //   }

// // //   Future<void> cancelClaim(String postId) async {
// // //     try {
// // //       isLoading.value = true;
// // //       final success = await _historyService.cancelClaim(postId);
// // //       if (success) {
// // //         Get.snackbar("Success", "Claim cancelled successfully!");
// // //         await fetchUserStats();
// // //       }
// // //     } catch (e) {
// // //       Get.snackbar("Error", "Failed to cancel claim: $e");
// // //     } finally {
// // //       isLoading.value = false;
// // //     }
// // //   }

// // //   /// Add these helper methods for UI
// // //   Color getStatusColor(String status) {
// // //     switch (status.toLowerCase()) {
// // //       case 'available':
// // //         return Colors.green;
// // //       case 'claimed':
// // //         return Colors.orange;
// // //       case 'completed':
// // //         return Colors.blue;
// // //       case 'expired':
// // //         return Colors.red;
// // //       default:
// // //         return Colors.grey;
// // //     }
// // //   }

// // //   IconData getStatusIcon(String status) {
// // //     switch (status.toLowerCase()) {
// // //       case 'available':
// // //         return Icons.check_circle;
// // //       case 'claimed':
// // //         return Icons.shopping_cart;
// // //       case 'completed':
// // //         return Icons.verified;
// // //       case 'expired':
// // //         return Icons.error;
// // //       default:
// // //         return Icons.help;
// // //     }
// // //   }
// // // }
