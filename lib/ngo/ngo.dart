// =============================== NGO MODULE (Option A) ===============================
// Tabs: Available | Claimed | Completed
// Uses your existing FoodPostModel and the SAME FoodPostCard widget from
// volunteer history file. No model changes. Only Firebase + GetX logic.
//
// File layout in this single document (copy each block to its file path):
//  - lib/ngo/ngo_service.dart
//  - lib/ngo/ngo_food_controller.dart
//  - lib/ngo/views/ngo_main_view.dart
//  - lib/ngo/views/ngo_available_view.dart
//  - lib/ngo/views/ngo_claimed_view.dart
//  - lib/ngo/views/ngo_completed_view.dart
//  - lib/ngo/views/ngo_detail_page.dart
// -----------------------------------------------------------------------------------

// =============================== lib/ngo/ngo_service.dart ===============================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/ngo/ngo_model.dart';
import 'package:food_donation_app/volunteer/history/v_history_firebase.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class NgoService {
  NgoService._();
  static final NgoService instance = NgoService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('food_posts');

  // Stream: all available posts
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAvailable() {
    return _posts
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream: posts claimed by current NGO (still in progress)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchClaimedBy(String uid) {
    return _posts
        .where('claimedBy', isEqualTo: uid)
        .where('status', isEqualTo: 'claimed')
        .orderBy('claimedAt', descending: true)
        .snapshots();
  }

  // Stream: posts completed by current NGO
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCompletedBy(String uid) {
    return _posts
        .where('claimedBy', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }
}

// =============================== lib/ngo/ngo_food_controller.dart ===============================

class NgoFoodController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _ngoService = NgoService.instance;
  final _historyService =
      HistoryService.instance; // reuse claim/complete/cancel

  // Current NGO uid
  String get uid => _auth.currentUser?.uid ?? '';

  // Lists
  final available = <NgoFoodPostModel>[].obs;
  final claimed = <NgoFoodPostModel>[].obs;
  final completed = <NgoFoodPostModel>[].obs;

  // Loading
  final loadingAvailable = true.obs;
  final loadingClaimed = true.obs;
  final loadingCompleted = true.obs;
  final busy = false.obs; // global action overlay

  // Subscriptions
  StreamSubscription? _subA;
  StreamSubscription? _subC;
  StreamSubscription? _subD;

  final _storage = GetStorage();
  var ngoName = "".obs;

  @override
  void onInit() {
    super.onInit();
    // ngoName.value = _storage.read('userName') ?? 'NGO';

    if (uid.isEmpty) return;
    _bind();
  }

  void _bind() {
    // Available
    loadingAvailable.value = true;
    _subA?.cancel();
    _subA = _ngoService.watchAvailable().listen((snap) {
      available.value =
          snap.docs.map((d) => NgoFoodPostModel.fromDoc(d)).toList();
      loadingAvailable.value = false;
    }, onError: (_) => loadingAvailable.value = false);

    // Claimed by NGO
    loadingClaimed.value = true;
    _subC?.cancel();
    _subC = _ngoService.watchClaimedBy(uid).listen((snap) {
      claimed.value =
          snap.docs.map((d) => NgoFoodPostModel.fromDoc(d)).toList();
      loadingClaimed.value = false;
    }, onError: (_) => loadingClaimed.value = false);

    // Completed by NGO
    loadingCompleted.value = true;
    _subD?.cancel();
    _subD = _ngoService.watchCompletedBy(uid).listen((snap) {
      completed.value =
          snap.docs.map((d) => NgoFoodPostModel.fromDoc(d)).toList();
      loadingCompleted.value = false;
    }, onError: (_) => loadingCompleted.value = false);
  }

  Future<void> refreshAll() async {
    _bind();
    Get.snackbar('', '',
        titleText: const SizedBox.shrink(),
        messageText: const Text('Refreshed!',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        backgroundColor: Colors.green.withOpacity(0.85),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(10));
  }

  // ---- Actions (wrap HistoryService) ----
  Future<void> claim(String postId) async {
    try {
      busy.value = true;
      await _historyService.claimFoodPost(postId, uid, ngoName.value);
      Get.snackbar('Success', 'Post claimed successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> complete(String postId) async {
    try {
      busy.value = true;
      await _historyService.completeFoodPost(postId, uid);
      Get.snackbar('Success', 'Post marked as completed!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> cancel(String postId) async {
    try {
      busy.value = true;
      await _historyService.cancelClaim(postId);
      Get.snackbar('Success', 'Claim cancelled successfully!',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  @override
  void onClose() {
    _subA?.cancel();
    _subC?.cancel();
    _subD?.cancel();
    available.clear();
    claimed.clear();
    completed.clear();

    super.onClose();
  }
}

// =============================== lib/ngo/views/ngo_main_view.dart ===============================

class NgoMainView extends StatelessWidget {
  NgoMainView({super.key});
  final ctrl = Get.put(NgoFoodController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NGO – Food Posts'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
                // onPressed: ctrl.refreshAll,
                onPressed: () {
                  ctrl.completed.clear();
                  ctrl.claimed.clear();
                  ctrl.available.clear();
                  ctrl.refreshAll();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh'),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.explore), text: 'Available'),
              // Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
              Tab(icon: Icon(Icons.verified), text: 'Completed'),
            ],
          ),
        ),
        body: Stack(
          children: [
            const TabBarView(
              children: [
                NgoAvailableView(),
                // NgoClaimedView(),
                NgoCompletedView(),
              ],
            ),
            Obx(() => ctrl.busy.value
                ? Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// =============================== lib/ngo/views/ngo_available_view.dart ===============================

class NgoAvailableView extends StatelessWidget {
  const NgoAvailableView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NgoFoodController>();
    return Obx(() {
      if (ctrl.loadingAvailable.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading available posts...'),
            ],
          ),
        );
      }
      if (ctrl.available.isEmpty) {
        return _empty('No available posts', Icons.inbox_outlined,
            'Check back later for new donations');
      }
      return RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ctrl.available.length,
          itemBuilder: (_, i) {
            final post = ctrl.available[i];
            final isMyPost = post.userUid == ctrl.uid;
            return FoodPostCard(
              post: post,
              showClaim: !isMyPost,
              showInfo: isMyPost,
              onClaim: !isMyPost ? () => ctrl.claim(post.id) : null,
            );
          },
        ),
      );
    });
  }

  Widget _empty(String title, IconData icon, String sub) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(sub,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// =============================== lib/ngo/views/ngo_claimed_view.dart ===============================

class NgoClaimedView extends StatelessWidget {
  const NgoClaimedView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NgoFoodController>();
    return Obx(() {
      if (ctrl.loadingClaimed.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading claimed posts...'),
            ],
          ),
        );
      }
      if (ctrl.claimed.isEmpty) {
        return _empty('No claimed posts', Icons.shopping_cart_outlined,
            'Claim available posts to help donate');
      }
      return RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ctrl.claimed.length,
          itemBuilder: (_, i) {
            final post = ctrl.claimed[i];
            return FoodPostCard(
              post: post,
              showComplete: true,
              showCancel: true,
              onComplete: () => ctrl.complete(post.id),
              onCancel: () => ctrl.cancel(post.id),
            );
          },
        ),
      );
    });
  }

  Widget _empty(String title, IconData icon, String sub) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(sub,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// =============================== lib/ngo/views/ngo_completed_view.dart ===============================

class NgoCompletedView extends StatelessWidget {
  const NgoCompletedView({super.key});

  @override
  Widget build(BuildContext context) {
    var ctrl = Get.find<NgoFoodController>();
    return Obx(() {
      if (ctrl.loadingCompleted.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading completed posts...'),
            ],
          ),
        );
      }
      if (ctrl.completed.isEmpty) {
        return _empty('No completed posts', Icons.verified_outlined,
            'You have not completed any posts yet');
      }
      return RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ctrl.completed.length,
          itemBuilder: (_, i) {
            final post = ctrl.completed[i];
            return FoodPostCard(
              post: post,
              // read-only view
            );
          },
        ),
      );
    });
  }

  Widget _empty(String title, IconData icon, String sub) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(sub,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// =============================== lib/ngo/views/ngo_detail_page.dart ===============================
// Lightweight detail page that reuses the same card info style and provides
// actions based on status. This is optional because the card already exposes
// actions, but some teams prefer a deep-dive screen.

class NgoDetailPage extends StatelessWidget {
  final NgoFoodPostModel post;
  const NgoDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NgoFoodController>();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Post Detail'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.foodDetails,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _info('Address', post.address),
            _info('Pickup', post.pickupTime),
            _info('Quantity', post.quantity),
            _info('Zip', post.zipCode),
            const SizedBox(height: 24),
            Row(children: [
              if (post.status == 'available' && post.userUid != ctrl.uid)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ctrl.claim(post.id),
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text('Claim'),
                  ),
                ),
              if (post.status == 'claimed' && post.claimedBy == ctrl.uid) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ctrl.cancel(post.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ctrl.complete(post.id),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ])
          ],
        ),
      ),
    );
  }

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

class FoodPostCard extends StatelessWidget {
  final NgoFoodPostModel post;
  final bool showDelete;
  final bool showClaim;
  final bool showComplete;
  final bool showCancel;
  final bool showInfo;
  final VoidCallback? onDelete;
  final VoidCallback? onClaim;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const FoodPostCard({
    super.key,
    required this.post,
    this.showDelete = false,
    this.showClaim = false,
    this.showComplete = false,
    this.showCancel = false,
    this.showInfo = false,
    this.onDelete,
    this.onClaim,
    this.onComplete,
    this.onCancel,
  });

  static final _images = [
    "assets/images/nHome1.png",
    "assets/images/nHome2.png",
    "assets/images/nHome3.png",
    "assets/images/nHome4.jpg",
    "assets/images/nHome5.jpg",
    "assets/images/nHome6.jpg",
    "assets/images/nHome7.jpg",
    "assets/images/nHome8.jpg",
    "assets/images/nHome9.jpg",
    "assets/images/nHome10.jpg",
  ];

  String _getImage() {
    final index = post.id.hashCode.abs() % _images.length;
    return _images[index];
  }

  Color _getStatusColor() {
    switch (post.status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'claimed':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today ${DateFormat('HH:mm').format(date)}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay and status badge
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ).createShader(bounds),
                  blendMode: BlendMode.darken,
                  child: Image.asset(
                    _getImage(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                      ),
                      child: const Icon(Icons.fastfood,
                          size: 60, color: Colors.white70),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(),
                          _getStatusColor().withOpacity(0.8)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      post.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.foodDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Info cards
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent[500],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.location_on, post.address,
                            const Color(0xFFE63946)),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.schedule,
                            'Pickup: ${post.pickupTime}',
                            const Color(0xFF457B9D)),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.restaurant_menu,
                            'Quantity: ${post.quantity}',
                            const Color(0xFFF77F00)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time and claimed info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 5),
                            Text(
                              _formatTime(post.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (showDelete ||
                          showClaim ||
                          showComplete ||
                          showCancel ||
                          showInfo)
                        Container(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showInfo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.15),
                                        Colors.blue.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user,
                                          size: 18, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text(
                                        'Your Post',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (showDelete && onDelete != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: onDelete,
                                    icon: const Icon(Icons.delete_rounded),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                    iconSize: 22,
                                  ),
                                ),
                              if (showClaim && onClaim != null)
                                ElevatedButton.icon(
                                  onPressed: onClaim,
                                  icon: const Icon(Icons.volunteer_activism,
                                      size: 18),
                                  label: const Text('Claim Post',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              if (showCancel && onCancel != null) ...[
                                TextButton.icon(
                                  onPressed: onCancel,
                                  // icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Cancel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (showComplete && onComplete != null)
                                ElevatedButton.icon(
                                  onPressed: onComplete,
                                  icon: const Icon(Icons.check_circle_rounded,
                                      size: 18),
                                  label: const Text('Complete',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (post.claimedBy != null &&
                      post.claimedBy!.isNotEmpty &&
                      post.claimedBy == post.id) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.1),
                            Colors.orange.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                size: 16, color: Colors.orange),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Claimed from You',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D3142),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
