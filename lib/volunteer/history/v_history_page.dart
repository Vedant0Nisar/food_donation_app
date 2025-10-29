import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
import 'package:food_donation_app/volunteer/history/v_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FoodPostHistoryView extends StatelessWidget {
  FoodPostHistoryView({super.key});

  final controller = Get.put(FoodPostController(), permanent: false);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Food Posts History'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.refreshData,
              tooltip: 'Refresh',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: 'My Posts'),
              Tab(icon: Icon(Icons.explore), text: 'Available'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildMyPostsTab(),
                _buildAvailablePostsTab(),
                _buildClaimedPostsTab(),
              ],
            ),
            // Global loading overlay
            Obx(() => controller.isLoading.value
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

  Widget _buildMyPostsTab() {
    return Column(
      children: [
        _buildStatsCard(),
        Expanded(
          child: Obx(() {
            // Show loader while loading
            if (controller.isMyPostsLoading.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your posts...'),
                  ],
                ),
              );
            }

            // Show empty state
            if (controller.myPosts.isEmpty) {
              return _buildEmptyState(
                'No posts created yet',
                Icons.restaurant_menu,
                'Create a post to donate food',
              );
            }

            // Show posts list
            return RefreshIndicator(
              onRefresh: controller.refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.myPosts.length,
                itemBuilder: (_, i) => FoodPostCard(
                  post: controller.myPosts[i],
                  showDelete: true,
                  onDelete: () => _confirmDelete(controller.myPosts[i]),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAvailablePostsTab() {
    return Obx(() {
      // Show loader while loading
      if (controller.isAvailablePostsLoading.value) {
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

      // Show empty state
      if (controller.availablePosts.isEmpty) {
        return _buildEmptyState(
          'No available posts',
          Icons.inbox_outlined,
          'Check back later for new donations',
        );
      }

      // Show posts list
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.availablePosts.length,
          itemBuilder: (_, i) {
            final post = controller.availablePosts[i];
            final isMyPost = post.userUid == controller.currentUid;

            return FoodPostCard(
              post: post,
              showClaim: !isMyPost, // Only show claim if NOT my post
              showInfo: isMyPost, // Show info badge if it's my post
              onClaim: !isMyPost ? () => controller.claimPost(post.id) : null,
            );
          },
        ),
      );
    });
  }

  Widget _buildClaimedPostsTab() {
    return Obx(() {
      // Show loader while loading
      if (controller.isClaimedPostsLoading.value) {
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

      // Show empty state
      if (controller.claimedPosts.isEmpty) {
        return _buildEmptyState(
          'No claimed posts',
          Icons.shopping_cart_outlined,
          'Claim available posts to help donate',
        );
      }

      // Show posts list
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.claimedPosts.length,
          itemBuilder: (_, i) => FoodPostCard(
            post: controller.claimedPosts[i],
            showComplete: true,
            showCancel: true,
            onComplete: () =>
                controller.completePost(controller.claimedPosts[i].id),
            onCancel: () =>
                controller.cancelClaim(controller.claimedPosts[i].id),
          ),
        ),
      );
    });
  }

  Widget _buildStatsCard() {
    return Obx(() => Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Total', controller.userStats['totalPosts'] ?? 0,
                        Icons.restaurant),
                    _buildStat(
                        'Available',
                        controller.userStats['availablePosts'] ?? 0,
                        Icons.check_circle),
                    _buildStat(
                        'Claimed',
                        controller.userStats['claimedPosts'] ?? 0,
                        Icons.shopping_cart),
                    _buildStat(
                        'Done',
                        controller.userStats['completedPosts'] ?? 0,
                        Icons.verified),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 22),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FoodPostModel post) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Post'),
        content: Text(
            'Are you sure you want to delete this post?\n\n"${post.foodDetails}"'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deletePost(post.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class FoodPostCard extends StatelessWidget {
  final FoodPostModel post;
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

                  if (post.claimedBy != null && post.claimedBy!.isNotEmpty) ...[
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
                            'Claimed from ${post.userName}',
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


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
// import 'package:food_donation_app/volunteer/history/v_model.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class FoodPostHistoryView extends StatelessWidget {
//   FoodPostHistoryView({super.key});

//   final controller = Get.put(FoodPostController(), permanent: false);

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Food Posts History'),
//           backgroundColor: Colors.green,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: controller.refreshData,
//               tooltip: 'Refresh',
//             ),
//           ],
//           bottom: const TabBar(
//             tabs: [
//               Tab(icon: Icon(Icons.restaurant), text: 'My Posts'),
//               Tab(icon: Icon(Icons.explore), text: 'Available'),
//               Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
//             ],
//           ),
//         ),
//         body: Stack(
//           children: [
//             TabBarView(
//               children: [
//                 _buildMyPostsTab(),
//                 _buildAvailablePostsTab(),
//                 _buildClaimedPostsTab(),
//               ],
//             ),
//             // Global loading overlay
//             Obx(() => controller.isLoading.value
//                 ? Container(
//                     color: Colors.black26,
//                     child: const Center(
//                       child: Card(
//                         child: Padding(
//                           padding: EdgeInsets.all(20),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               CircularProgressIndicator(),
//                               SizedBox(height: 16),
//                               Text('Processing...'),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   )
//                 : const SizedBox.shrink()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMyPostsTab() {
//     return Column(
//       children: [
//         _buildStatsCard(),
//         Expanded(
//           child: Obx(() {
//             // Show loader while loading
//             if (controller.isMyPostsLoading.value) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Loading your posts...'),
//                   ],
//                 ),
//               );
//             }

//             // Show empty state
//             if (controller.myPosts.isEmpty) {
//               return _buildEmptyState(
//                 'No posts created yet',
//                 Icons.restaurant_menu,
//                 'Create a post to donate food',
//               );
//             }

//             // Show posts list
//             return RefreshIndicator(
//               onRefresh: controller.refreshData,
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: controller.myPosts.length,
//                 itemBuilder: (_, i) => FoodPostCard(
//                   post: controller.myPosts[i],
//                   showDelete: true,
//                   onDelete: () => _confirmDelete(controller.myPosts[i]),
//                 ),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }

//   Widget _buildAvailablePostsTab() {
//     return Obx(() {
//       // Show loader while loading
//       if (controller.isAvailablePostsLoading.value) {
//         return const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Loading available posts...'),
//             ],
//           ),
//         );
//       }

//       // Show empty state
//       if (controller.availablePosts.isEmpty) {
//         return _buildEmptyState(
//           'No available posts',
//           Icons.inbox_outlined,
//           'Check back later for new donations',
//         );
//       }

//       // Show posts list
//       return RefreshIndicator(
//         onRefresh: controller.refreshData,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: controller.availablePosts.length,
//           itemBuilder: (_, i) => FoodPostCard(
//             post: controller.availablePosts[i],
//             showClaim: true,
//             onClaim: () =>
//                 controller.claimPost(controller.availablePosts[i].id),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildClaimedPostsTab() {
//     return Obx(() {
//       // Show loader while loading
//       if (controller.isClaimedPostsLoading.value) {
//         return const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Loading claimed posts...'),
//             ],
//           ),
//         );
//       }

//       // Show empty state
//       if (controller.claimedPosts.isEmpty) {
//         return _buildEmptyState(
//           'No claimed posts',
//           Icons.shopping_cart_outlined,
//           'Claim available posts to help donate',
//         );
//       }

//       // Show posts list
//       return RefreshIndicator(
//         onRefresh: controller.refreshData,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: controller.claimedPosts.length,
//           itemBuilder: (_, i) => FoodPostCard(
//             post: controller.claimedPosts[i],
//             showComplete: true,
//             showCancel: true,
//             onComplete: () =>
//                 controller.completePost(controller.claimedPosts[i].id),
//             onCancel: () =>
//                 controller.cancelClaim(controller.claimedPosts[i].id),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildStatsCard() {
//     return Obx(() => Card(
//           margin: const EdgeInsets.all(12),
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Statistics',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildStat('Total', controller.userStats['totalPosts'] ?? 0,
//                         Icons.restaurant),
//                     _buildStat(
//                         'Available',
//                         controller.userStats['availablePosts'] ?? 0,
//                         Icons.check_circle),
//                     _buildStat(
//                         'Claimed',
//                         controller.userStats['claimedPosts'] ?? 0,
//                         Icons.shopping_cart),
//                     _buildStat(
//                         'Done',
//                         controller.userStats['completedPosts'] ?? 0,
//                         Icons.verified),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ));
//   }

//   Widget _buildStat(String label, int count, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.green, size: 22),
//         const SizedBox(height: 4),
//         Text(
//           '$count',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 10,
//             color: Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState(String message, IconData icon, String subtitle) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 80, color: Colors.grey[300]),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 13,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmDelete(FoodPostModel post) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Delete Post'),
//         content: Text(
//             'Are you sure you want to delete this post?\n\n"${post.foodDetails}"'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               controller.deletePost(post.id);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class FoodPostCard extends StatelessWidget {
//   final FoodPostModel post;
//   final bool showDelete;
//   final bool showClaim;
//   final bool showComplete;
//   final bool showCancel;
//   final VoidCallback? onDelete;
//   final VoidCallback? onClaim;
//   final VoidCallback? onComplete;
//   final VoidCallback? onCancel;

//   const FoodPostCard({
//     super.key,
//     required this.post,
//     this.showDelete = false,
//     this.showClaim = false,
//     this.showComplete = false,
//     this.showCancel = false,
//     this.onDelete,
//     this.onClaim,
//     this.onComplete,
//     this.onCancel,
//   });

//   static final _images = [
//     "assets/images/nHome1.png",
//     "assets/images/nHome2.png",
//     "assets/images/nHome3.png",
//     "assets/images/nHome4.jpg",
//     "assets/images/nHome5.jpg",
//     "assets/images/nHome6.jpg",
//     "assets/images/nHome7.jpg",
//     "assets/images/nHome8.jpg",
//     "assets/images/nHome9.jpg",
//     "assets/images/nHome10.jpg",
//   ];

//   String _getImage() {
//     final index = post.id.hashCode.abs() % _images.length;
//     return _images[index];
//   }

//   Color _getStatusColor() {
//     switch (post.status.toLowerCase()) {
//       case 'available':
//         return Colors.green;
//       case 'claimed':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return '';
//     final date = timestamp.toDate();
//     final diff = DateTime.now().difference(date);
//     if (diff.inDays == 0) return 'Today ${DateFormat('HH:mm').format(date)}';
//     if (diff.inDays == 1) return 'Yesterday';
//     if (diff.inDays < 7) return '${diff.inDays} days ago';
//     return DateFormat('MMM dd').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       clipBehavior: Clip.antiAlias,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Image with status badge overlay
//           Stack(
//             children: [
//               Image.asset(
//                 _getImage(),
//                 height: 140,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Container(
//                   height: 140,
//                   color: Colors.grey[200],
//                   child:
//                       const Icon(Icons.fastfood, size: 50, color: Colors.grey),
//                 ),
//               ),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     post.status.toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // Content
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   post.foodDetails,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildInfoRow(Icons.location_on, post.address, Colors.red),
//                 const SizedBox(height: 4),
//                 _buildInfoRow(Icons.access_time, 'Pickup: ${post.pickupTime}',
//                     Colors.blue),
//                 const SizedBox(height: 4),
//                 _buildInfoRow(Icons.fastfood, 'Quantity: ${post.quantity}',
//                     Colors.orange),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Text(
//                       _formatTime(post.createdAt),
//                       style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//                 if (post.claimedBy != null && post.claimedBy!.isNotEmpty) ...[
//                   const SizedBox(height: 6),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.orange.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.person,
//                             size: 14, color: Colors.orange),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Claimed by ${post.claimedBy}',
//                           style: const TextStyle(
//                             fontSize: 11,
//                             color: Colors.orange,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           // Actions
//           if (showDelete || showClaim || showComplete || showCancel)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   if (showDelete && onDelete != null)
//                     IconButton(
//                       onPressed: onDelete,
//                       icon: const Icon(Icons.delete_outline),
//                       color: Colors.red,
//                       tooltip: 'Delete',
//                     ),
//                   if (showClaim && onClaim != null)
//                     ElevatedButton.icon(
//                       onPressed: onClaim,
//                       icon: const Icon(Icons.volunteer_activism, size: 16),
//                       label: const Text('Claim'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                       ),
//                     ),
//                   if (showCancel && onCancel != null) ...[
//                     TextButton(
//                       onPressed: onCancel,
//                       child: const Text(
//                         'Cancel',
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                   ],
//                   if (showComplete && onComplete != null)
//                     ElevatedButton.icon(
//                       onPressed: onComplete,
//                       icon: const Icon(Icons.check_circle, size: 16),
//                       label: const Text('Complete'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text, Color color) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(fontSize: 12, color: Colors.black87),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
// }
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
// // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // import 'package:get/get.dart';
// // import 'package:intl/intl.dart';

// // class FoodPostHistoryView extends StatelessWidget {
// //   FoodPostHistoryView({super.key});

// //   final controller = Get.put(FoodPostController(), permanent: false);

// //   @override
// //   Widget build(BuildContext context) {
// //     return DefaultTabController(
// //       length: 3,
// //       child: Scaffold(
// //         appBar: AppBar(
// //           title: const Text('Food Posts History'),
// //           backgroundColor: Colors.green,
// //           bottom: const TabBar(
// //             tabs: [
// //               Tab(icon: Icon(Icons.restaurant), text: 'My Posts'),
// //               Tab(icon: Icon(Icons.explore), text: 'Available'),
// //               Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
// //             ],
// //           ),
// //         ),
// //         body: TabBarView(
// //           children: [
// //             _buildMyPostsTab(),
// //             _buildAvailablePostsTab(),
// //             _buildClaimedPostsTab(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMyPostsTab() {
// //     return Column(
// //       children: [
// //         _buildStatsCard(),
// //         Expanded(
// //           child: Obx(() {
// //             if (controller.myPosts.isEmpty) {
// //               return _buildEmptyState(
// //                 'No posts created yet',
// //                 Icons.restaurant_menu,
// //               );
// //             }
// //             return RefreshIndicator(
// //               onRefresh: controller.refreshData,
// //               child: ListView.builder(
// //                 padding: const EdgeInsets.all(12),
// //                 itemCount: controller.myPosts.length,
// //                 itemBuilder: (_, i) => FoodPostCard(
// //                   post: controller.myPosts[i],
// //                   showDelete: true,
// //                   onDelete: () => _confirmDelete(controller.myPosts[i]),
// //                 ),
// //               ),
// //             );
// //           }),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildAvailablePostsTab() {
// //     return Obx(() {
// //       if (controller.availablePosts.isEmpty) {
// //         return _buildEmptyState(
// //           'No available posts',
// //           Icons.inbox_outlined,
// //         );
// //       }
// //       return RefreshIndicator(
// //         onRefresh: controller.refreshData,
// //         child: ListView.builder(
// //           padding: const EdgeInsets.all(12),
// //           itemCount: controller.availablePosts.length,
// //           itemBuilder: (_, i) => FoodPostCard(
// //             post: controller.availablePosts[i],
// //             showClaim: true,
// //             onClaim: () =>
// //                 controller.claimPost(controller.availablePosts[i].id),
// //           ),
// //         ),
// //       );
// //     });
// //   }

// //   Widget _buildClaimedPostsTab() {
// //     return Obx(() {
// //       if (controller.claimedPosts.isEmpty) {
// //         return _buildEmptyState(
// //           'No claimed posts',
// //           Icons.shopping_cart_outlined,
// //         );
// //       }
// //       return RefreshIndicator(
// //         onRefresh: controller.refreshData,
// //         child: ListView.builder(
// //           padding: const EdgeInsets.all(12),
// //           itemCount: controller.claimedPosts.length,
// //           itemBuilder: (_, i) => FoodPostCard(
// //             post: controller.claimedPosts[i],
// //             showComplete: true,
// //             showCancel: true,
// //             onComplete: () =>
// //                 controller.completePost(controller.claimedPosts[i].id),
// //             onCancel: () =>
// //                 controller.cancelClaim(controller.claimedPosts[i].id),
// //           ),
// //         ),
// //       );
// //     });
// //   }

// //   Widget _buildStatsCard() {
// //     return Obx(() => Card(
// //           margin: const EdgeInsets.all(12),
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceAround,
// //               children: [
// //                 _buildStat('Total', controller.userStats['totalPosts'] ?? 0,
// //                     Icons.restaurant),
// //                 _buildStat(
// //                     'Available',
// //                     controller.userStats['availablePosts'] ?? 0,
// //                     Icons.check_circle),
// //                 _buildStat('Claimed', controller.userStats['claimedPosts'] ?? 0,
// //                     Icons.shopping_cart),
// //                 _buildStat('Done', controller.userStats['completedPosts'] ?? 0,
// //                     Icons.verified),
// //               ],
// //             ),
// //           ),
// //         ));
// //   }

// //   Widget _buildStat(String label, int count, IconData icon) {
// //     return Column(
// //       children: [
// //         Icon(icon, color: Colors.green, size: 24),
// //         const SizedBox(height: 4),
// //         Text('$count',
// //             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //         Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
// //       ],
// //     );
// //   }

// //   Widget _buildEmptyState(String message, IconData icon) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(icon, size: 80, color: Colors.grey[300]),
// //           const SizedBox(height: 16),
// //           Text(message,
// //               style: const TextStyle(color: Colors.grey, fontSize: 16)),
// //         ],
// //       ),
// //     );
// //   }

// //   void _confirmDelete(FoodPostModel post) {
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('Delete Post'),
// //         content: Text('Delete "${post.foodDetails}"?'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('Cancel'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deletePost(post.id);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('Delete'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class FoodPostCard extends StatelessWidget {
// //   final FoodPostModel post;
// //   final bool showDelete;
// //   final bool showClaim;
// //   final bool showComplete;
// //   final bool showCancel;
// //   final VoidCallback? onDelete;
// //   final VoidCallback? onClaim;
// //   final VoidCallback? onComplete;
// //   final VoidCallback? onCancel;

// //   const FoodPostCard({
// //     super.key,
// //     required this.post,
// //     this.showDelete = false,
// //     this.showClaim = false,
// //     this.showComplete = false,
// //     this.showCancel = false,
// //     this.onDelete,
// //     this.onClaim,
// //     this.onComplete,
// //     this.onCancel,
// //   });

// //   static final _images = [
// //     "assets/images/nHome1.png",
// //     "assets/images/nHome2.png",
// //     "assets/images/nHome3.png",
// //     "assets/images/nHome4.jpg",
// //     "assets/images/nHome5.jpg",
// //     "assets/images/nHome6.jpg",
// //     "assets/images/nHome7.jpg",
// //     "assets/images/nHome8.jpg",
// //     "assets/images/nHome9.jpg",
// //     "assets/images/nHome10.jpg",
// //   ];

// //   String _getImage() {
// //     final index = post.id.hashCode.abs() % _images.length;
// //     return _images[index];
// //   }

// //   Color _getStatusColor() {
// //     switch (post.status.toLowerCase()) {
// //       case 'available':
// //         return Colors.green;
// //       case 'claimed':
// //         return Colors.orange;
// //       case 'completed':
// //         return Colors.blue;
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   String _formatTime(Timestamp? timestamp) {
// //     if (timestamp == null) return '';
// //     final date = timestamp.toDate();
// //     final diff = DateTime.now().difference(date);
// //     if (diff.inDays == 0) return 'Today ${DateFormat('HH:mm').format(date)}';
// //     if (diff.inDays == 1) return 'Yesterday';
// //     if (diff.inDays < 7) return '${diff.inDays} days ago';
// //     return DateFormat('MMM dd').format(date);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       margin: const EdgeInsets.only(bottom: 12),
// //       clipBehavior: Clip.antiAlias,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Image
// //           Image.asset(
// //             _getImage(),
// //             height: 140,
// //             width: double.infinity,
// //             fit: BoxFit.cover,
// //             errorBuilder: (_, __, ___) => Container(
// //               height: 140,
// //               color: Colors.grey[200],
// //               child: const Icon(Icons.fastfood, size: 50),
// //             ),
// //           ),

// //           // Content
// //           Padding(
// //             padding: const EdgeInsets.all(12),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   post.foodDetails,
// //                   style: const TextStyle(
// //                       fontSize: 16, fontWeight: FontWeight.bold),
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 const SizedBox(height: 8),
// //                 _buildInfoRow(Icons.location_on, post.address, Colors.red),
// //                 const SizedBox(height: 4),
// //                 _buildInfoRow(Icons.access_time, 'Pickup: ${post.pickupTime}',
// //                     Colors.grey),
// //                 const SizedBox(height: 4),
// //                 _buildInfoRow(
// //                     Icons.fastfood, 'Qty: ${post.quantity}', Colors.brown),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(
// //                           horizontal: 10, vertical: 4),
// //                       decoration: BoxDecoration(
// //                         color: _getStatusColor().withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(12),
// //                         border: Border.all(color: _getStatusColor()),
// //                       ),
// //                       child: Text(
// //                         post.status.toUpperCase(),
// //                         style: TextStyle(
// //                           color: _getStatusColor(),
// //                           fontSize: 11,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                     const Spacer(),
// //                     Text(
// //                       _formatTime(post.createdAt),
// //                       style: const TextStyle(fontSize: 11, color: Colors.grey),
// //                     ),
// //                   ],
// //                 ),
// //                 if (post.claimedBy != null && post.claimedBy!.isNotEmpty) ...[
// //                   const SizedBox(height: 6),
// //                   Text(
// //                     '🙋‍♂️ Claimed by ${post.claimedBy}',
// //                     style: const TextStyle(fontSize: 12, color: Colors.orange),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           ),

// //           // Actions
// //           if (showDelete || showClaim || showComplete || showCancel)
// //             Padding(
// //               padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.end,
// //                 children: [
// //                   if (showDelete && onDelete != null)
// //                     IconButton(
// //                       onPressed: onDelete,
// //                       icon: const Icon(Icons.delete_outline, color: Colors.red),
// //                     ),
// //                   if (showClaim && onClaim != null)
// //                     ElevatedButton.icon(
// //                       onPressed: onClaim,
// //                       icon: const Icon(Icons.volunteer_activism, size: 16),
// //                       label: const Text('Claim'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.orange,
// //                         foregroundColor: Colors.white,
// //                       ),
// //                     ),
// //                   if (showCancel && onCancel != null)
// //                     TextButton(
// //                       onPressed: onCancel,
// //                       child: const Text('Cancel',
// //                           style: TextStyle(color: Colors.red)),
// //                     ),
// //                   if (showCancel && showComplete) const SizedBox(width: 8),
// //                   if (showComplete && onComplete != null)
// //                     ElevatedButton.icon(
// //                       onPressed: onComplete,
// //                       icon: const Icon(Icons.check_circle, size: 16),
// //                       label: const Text('Complete'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.blue,
// //                         foregroundColor: Colors.white,
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildInfoRow(IconData icon, String text, Color color) {
// //     return Row(
// //       children: [
// //         Icon(icon, size: 14, color: color),
// //         const SizedBox(width: 6),
// //         Expanded(
// //           child: Text(
// //             text,
// //             style: const TextStyle(fontSize: 12),
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }


// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
// // // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // // import 'package:get/get.dart';
// // // import 'package:intl/intl.dart';

// // // class FoodPostHistoryView extends GetView<FoodPostController> {
// // //   FoodPostHistoryView({super.key});

// // //   final controller = Get.put(FoodPostController());

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return DefaultTabController(
// // //       length: 3,
// // //       child: Scaffold(
// // //         appBar: AppBar(
// // //           title: const Text('Food Posts History'),
// // //           backgroundColor: Colors.green,
// // //           elevation: 2,
// // //           bottom: const TabBar(
// // //             indicatorColor: Colors.white,
// // //             indicatorWeight: 3,
// // //             tabs: [
// // //               Tab(icon: Icon(Icons.restaurant), text: 'My Posts'),
// // //               Tab(icon: Icon(Icons.explore), text: 'Available'),
// // //               Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
// // //             ],
// // //           ),
// // //         ),
// // //         body: TabBarView(
// // //           children: [
// // //             _buildMyPostsTab(),
// // //             _buildAvailablePostsTab(),
// // //             _buildClaimedPostsTab(),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   // MY POSTS TAB (Posts created by me)
// // //   Widget _buildMyPostsTab() {
// // //     return Column(
// // //       children: [
// // //         Obx(() => _buildStatsCard()),
// // //         Expanded(
// // //           child: Obx(() {
// // //             if (controller.isLoading.value && controller.myPosts.isEmpty) {
// // //               return const Center(child: CircularProgressIndicator());
// // //             }

// // //             if (controller.myPosts.isEmpty) {
// // //               return _buildEmptyState(
// // //                 icon: Icons.restaurant_menu,
// // //                 message: "No food posts yet",
// // //                 subtitle: "Create a post to donate food",
// // //               );
// // //             }

// // //             return RefreshIndicator(
// // //               onRefresh: () async {
// // //                 await controller.fetchUserStats();
// // //                 controller.initializeListeners();
// // //               },
// // //               child: ListView.builder(
// // //                 itemCount: controller.myPosts.length,
// // //                 padding: const EdgeInsets.all(12),
// // //                 itemBuilder: (context, index) {
// // //                   final post = controller.myPosts[index];
// // //                   return FoodPostCard(
// // //                     post: post,
// // //                     onDelete: () => _confirmDelete(post),
// // //                     isMyPost: true,
// // //                   );
// // //                 },
// // //               ),
// // //             );
// // //           }),
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   // AVAILABLE POSTS TAB (Posts I can claim)
// // //   Widget _buildAvailablePostsTab() {
// // //     return Obx(() {
// // //       if (controller.isLoading.value && controller.availablePosts.isEmpty) {
// // //         return const Center(child: CircularProgressIndicator());
// // //       }

// // //       if (controller.availablePosts.isEmpty) {
// // //         return _buildEmptyState(
// // //           icon: Icons.inbox,
// // //           message: "No available food posts",
// // //           subtitle: "Check back later for donations",
// // //         );
// // //       }

// // //       return RefreshIndicator(
// // //         onRefresh: () async {
// // //           await controller.fetchUserStats();
// // //         },
// // //         child: ListView.builder(
// // //           itemCount: controller.availablePosts.length,
// // //           padding: const EdgeInsets.all(12),
// // //           itemBuilder: (context, index) {
// // //             final post = controller.availablePosts[index];
// // //             return FoodPostCard(
// // //               post: post,
// // //               onClaim: () => controller.claimPost(post.id),
// // //               isAvailable: true,
// // //             );
// // //           },
// // //         ),
// // //       );
// // //     });
// // //   }

// // //   // CLAIMED POSTS TAB (Posts I have claimed)
// // //   Widget _buildClaimedPostsTab() {
// // //     return Obx(() {
// // //       if (controller.isLoading.value && controller.claimedPosts.isEmpty) {
// // //         return const Center(child: CircularProgressIndicator());
// // //       }

// // //       if (controller.claimedPosts.isEmpty) {
// // //         return _buildEmptyState(
// // //           icon: Icons.shopping_cart_outlined,
// // //           message: "No claimed food posts",
// // //           subtitle: "Claim posts from the Available tab",
// // //         );
// // //       }

// // //       return RefreshIndicator(
// // //         onRefresh: () async {
// // //           await controller.fetchUserStats();
// // //         },
// // //         child: ListView.builder(
// // //           itemCount: controller.claimedPosts.length,
// // //           padding: const EdgeInsets.all(12),
// // //           itemBuilder: (context, index) {
// // //             final post = controller.claimedPosts[index];
// // //             return FoodPostCard(
// // //               post: post,
// // //               onComplete: () => controller.completePost(post.id),
// // //               onCancelClaim: () => controller.cancelClaim(post.id),
// // //               isClaimed: true,
// // //             );
// // //           },
// // //         ),
// // //       );
// // //     });
// // //   }

// // //   // STATS CARD
// // //   Widget _buildStatsCard() {
// // //     return Card(
// // //       margin: const EdgeInsets.all(12),
// // //       elevation: 3,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             const Text(
// // //               'My Statistics',
// // //               style: TextStyle(
// // //                 fontSize: 16,
// // //                 fontWeight: FontWeight.bold,
// // //                 color: Colors.green,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             Row(
// // //               mainAxisAlignment: MainAxisAlignment.spaceAround,
// // //               children: [
// // //                 _buildStatItem(
// // //                   'Total',
// // //                   controller.userStats['totalPosts'] ?? 0,
// // //                   Icons.restaurant,
// // //                 ),
// // //                 _buildStatItem(
// // //                   'Available',
// // //                   controller.userStats['availablePosts'] ?? 0,
// // //                   Icons.check_circle,
// // //                 ),
// // //                 _buildStatItem(
// // //                   'Claimed',
// // //                   controller.userStats['claimedPosts'] ?? 0,
// // //                   Icons.shopping_cart,
// // //                 ),
// // //                 _buildStatItem(
// // //                   'Completed',
// // //                   controller.userStats['completedPosts'] ?? 0,
// // //                   Icons.verified,
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildStatItem(String label, int count, IconData icon) {
// // //     return Column(
// // //       children: [
// // //         Icon(icon, color: Colors.green, size: 24),
// // //         const SizedBox(height: 4),
// // //         Text(
// // //           '$count',
// // //           style: const TextStyle(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //             color: Colors.green,
// // //           ),
// // //         ),
// // //         Text(
// // //           label,
// // //           style: const TextStyle(
// // //             fontSize: 11,
// // //             color: Colors.grey,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   // EMPTY STATE
// // //   Widget _buildEmptyState({
// // //     required IconData icon,
// // //     required String message,
// // //     required String subtitle,
// // //   }) {
// // //     return Center(
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           Icon(icon, size: 80, color: Colors.grey[300]),
// // //           const SizedBox(height: 16),
// // //           Text(
// // //             message,
// // //             style: const TextStyle(
// // //               fontSize: 18,
// // //               fontWeight: FontWeight.w500,
// // //               color: Colors.grey,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Text(
// // //             subtitle,
// // //             style: TextStyle(
// // //               fontSize: 14,
// // //               color: Colors.grey[600],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   // CONFIRM DELETE DIALOG
// // //   void _confirmDelete(FoodPostModel post) {
// // //     Get.dialog(
// // //       AlertDialog(
// // //         title: const Text("Delete Post"),
// // //         content: Text(
// // //           "Are you sure you want to delete this food post?\n\n${post.foodDetails}",
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Get.back(),
// // //             child: const Text("Cancel"),
// // //           ),
// // //           TextButton(
// // //             onPressed: () {
// // //               Get.back();
// // //               controller.deletePost(post.id);
// // //             },
// // //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// // //             child: const Text("Delete"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ==================== FOOD POST CARD ====================
// // // class FoodPostCard extends StatelessWidget {
// // //   final FoodPostModel post;
// // //   final VoidCallback? onDelete;
// // //   final VoidCallback? onClaim;
// // //   final VoidCallback? onComplete;
// // //   final VoidCallback? onCancelClaim;
// // //   final bool isMyPost;
// // //   final bool isAvailable;
// // //   final bool isClaimed;

// // //   // Pre-defined image list (won't change on rebuild)
// // //   static final List<String> _imagePool = [
// // //     "assets/images/nHome1.png",
// // //     "assets/images/nHome2.png",
// // //     "assets/images/nHome3.png",
// // //     "assets/images/nHome4.jpg",
// // //     "assets/images/nHome5.jpg",
// // //     "assets/images/nHome6.jpg",
// // //     "assets/images/nHome7.jpg",
// // //     "assets/images/nHome8.jpg",
// // //     "assets/images/nHome9.jpg",
// // //     "assets/images/nHome10.jpg",
// // //   ];

// // //   const FoodPostCard({
// // //     super.key,
// // //     required this.post,
// // //     this.onDelete,
// // //     this.onClaim,
// // //     this.onComplete,
// // //     this.onCancelClaim,
// // //     this.isMyPost = false,
// // //     this.isAvailable = false,
// // //     this.isClaimed = false,
// // //   });

// // //   // Get consistent image based on post ID (won't change on rebuild)
// // //   String _getImageForPost() {
// // //     final hash = post.id.hashCode.abs();
// // //     return _imagePool[hash % _imagePool.length];
// // //   }

// // //   Color _getStatusColor() {
// // //     switch (post.status.toLowerCase()) {
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

// // //   String _formatDate(Timestamp timestamp) {
// // //     final date = timestamp.toDate();
// // //     final now = DateTime.now();
// // //     final difference = now.difference(date);

// // //     if (difference.inDays == 0) {
// // //       return 'Today ${DateFormat('HH:mm').format(date)}';
// // //     } else if (difference.inDays == 1) {
// // //       return 'Yesterday ${DateFormat('HH:mm').format(date)}';
// // //     } else if (difference.inDays < 7) {
// // //       return '${difference.inDays} days ago';
// // //     } else {
// // //       return DateFormat('MMM dd, yyyy').format(date);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Card(
// // //       elevation: 3,
// // //       margin: const EdgeInsets.only(bottom: 12),
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // //       clipBehavior: Clip.hardEdge,
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Image Header
// // //           Image.asset(
// // //             _getImageForPost(),
// // //             height: 150,
// // //             width: double.infinity,
// // //             fit: BoxFit.cover,
// // //             errorBuilder: (context, error, stackTrace) {
// // //               return Container(
// // //                 height: 150,
// // //                 color: Colors.grey[300],
// // //                 child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
// // //               );
// // //             },
// // //           ),

// // //           // Content
// // //           Padding(
// // //             padding: const EdgeInsets.all(12),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 // Food Details
// // //                 Text(
// // //                   post.foodDetails,
// // //                   style: const TextStyle(
// // //                     fontSize: 17,
// // //                     fontWeight: FontWeight.w600,
// // //                     color: Colors.deepPurple,
// // //                   ),
// // //                   maxLines: 2,
// // //                   overflow: TextOverflow.ellipsis,
// // //                 ),
// // //                 const SizedBox(height: 8),

// // //                 // Location
// // //                 _buildInfoRow(
// // //                   Icons.location_on,
// // //                   post.address,
// // //                   Colors.redAccent,
// // //                 ),
// // //                 const SizedBox(height: 4),

// // //                 // Pickup Time
// // //                 _buildInfoRow(
// // //                   Icons.access_time,
// // //                   "Pickup: ${post.pickupTime}",
// // //                   Colors.grey,
// // //                 ),
// // //                 const SizedBox(height: 4),

// // //                 // Quantity
// // //                 _buildInfoRow(
// // //                   Icons.fastfood,
// // //                   "Quantity: ${post.quantity}",
// // //                   Colors.brown,
// // //                 ),
// // //                 const SizedBox(height: 8),

// // //                 // Status Badge
// // //                 Container(
// // //                   padding:
// // //                       const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// // //                   decoration: BoxDecoration(
// // //                     color: _getStatusColor().withOpacity(0.1),
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     border: Border.all(color: _getStatusColor(), width: 1),
// // //                   ),
// // //                   child: Text(
// // //                     post.status.toUpperCase(),
// // //                     style: TextStyle(
// // //                       fontWeight: FontWeight.bold,
// // //                       color: _getStatusColor(),
// // //                       fontSize: 12,
// // //                     ),
// // //                   ),
// // //                 ),

// // //                 // Claimed By Info
// // //                 if (post.claimedBy != null && post.claimedBy!.isNotEmpty) ...[
// // //                   const SizedBox(height: 6),
// // //                   Text(
// // //                     "🙋‍♂️ Claimed by: ${post.claimedBy}",
// // //                     style: const TextStyle(
// // //                       color: Colors.orange,
// // //                       fontWeight: FontWeight.w500,
// // //                       fontSize: 13,
// // //                     ),
// // //                   ),
// // //                 ],

// // //                 const SizedBox(height: 8),

// // //                 // Date Posted
// // //                 Text(
// // //                   "📅 Posted: ${_formatDate(post.createdAt)}",
// // //                   style: const TextStyle(fontSize: 11, color: Colors.grey),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),

// // //           // Action Buttons
// // //           _buildActionButtons(context),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
// // //     return Row(
// // //       children: [
// // //         Icon(icon, color: iconColor, size: 16),
// // //         const SizedBox(width: 6),
// // //         Expanded(
// // //           child: Text(
// // //             text,
// // //             style: const TextStyle(fontSize: 13, color: Colors.black87),
// // //             maxLines: 2,
// // //             overflow: TextOverflow.ellipsis,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   Widget _buildActionButtons(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.all(12),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.end,
// // //         children: [
// // //           // Delete button (for my posts)
// // //           if (isMyPost && onDelete != null)
// // //             IconButton(
// // //               onPressed: onDelete,
// // //               icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
// // //               tooltip: "Delete Post",
// // //             ),

// // //           // Claim button (for available posts)
// // //           if (isAvailable && onClaim != null)
// // //             ElevatedButton.icon(
// // //               onPressed: onClaim,
// // //               icon: const Icon(Icons.volunteer_activism, size: 18),
// // //               label: const Text("Claim"),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: Colors.orange,
// // //                 foregroundColor: Colors.white,
// // //                 shape: RoundedRectangleBorder(
// // //                   borderRadius: BorderRadius.circular(8),
// // //                 ),
// // //               ),
// // //             ),

// // //           // Complete & Cancel buttons (for claimed posts)
// // //           if (isClaimed) ...[
// // //             if (onCancelClaim != null)
// // //               TextButton(
// // //                 onPressed: onCancelClaim,
// // //                 child: const Text(
// // //                   "Cancel",
// // //                   style: TextStyle(color: Colors.red),
// // //                 ),
// // //               ),
// // //             const SizedBox(width: 8),
// // //             if (onComplete != null)
// // //               ElevatedButton.icon(
// // //                 onPressed: onComplete,
// // //                 icon: const Icon(Icons.check_circle, size: 18),
// // //                 label: const Text("Complete"),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: Colors.blue,
// // //                   foregroundColor: Colors.white,
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(8),
// // //                   ),
// // //                 ),
// // //               ),
// // //           ],
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }


// // // // import 'package:flutter/material.dart';
// // // // import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
// // // // import 'package:food_donation_app/volunteer/history/v_model.dart';
// // // // import 'package:get/get.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';

// // // // class FoodPostHistoryView extends StatelessWidget {
// // // //   FoodPostHistoryView({super.key});
// // // //   final controller = Get.put(FoodPostController());
// // // //   final user = FirebaseAuth.instance.currentUser;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     controller.initializeHistory();
// // // //     return DefaultTabController(
// // // //       length: 3,
// // // //       child: Scaffold(
// // // //         appBar: AppBar(
// // // //           title: const Text('Food Posts History'),
// // // //           backgroundColor: Colors.green,
// // // //           bottom: TabBar(
// // // //             tabs: [
// // // //               Tab(icon: Icon(Icons.restaurant), text: 'My Posts'),
// // // //               Tab(icon: Icon(Icons.explore), text: 'Available'),
// // // //               Tab(icon: Icon(Icons.shopping_cart), text: 'Claimed'),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         body: TabBarView(
// // // //           children: [
// // // //             _buildMyPostsTab(),
// // // //             _buildAvailablePostsTab(),
// // // //             _buildClaimedPostsTab(),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildMyPostsTab() {
// // // //     return Column(
// // // //       children: [
// // // //         Obx(() => _buildStatsCard()),
// // // //         Expanded(
// // // //           child: Obx(() {
// // // //             if (controller.isLoading.value) {
// // // //               return const Center(child: CircularProgressIndicator());
// // // //             }

// // // //             if (controller.myPosts.isEmpty) {
// // // //               return const Center(
// // // //                 child: Text("No food posts yet 🍱",
// // // //                     style: TextStyle(color: Colors.grey)),
// // // //               );
// // // //             }

// // // //             return ListView.builder(
// // // //               itemCount: controller.myPosts.length,
// // // //               padding: const EdgeInsets.all(12),
// // // //               itemBuilder: (context, index) {
// // // //                 final post = controller.myPosts[index];
// // // //                 return _buildPostCard(post, isMyPost: true);
// // // //               },
// // // //             );
// // // //           }),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildAvailablePostsTab() {
// // // //     return Obx(() {
// // // //       if (controller.isLoading.value) {
// // // //         return const Center(child: CircularProgressIndicator());
// // // //       }

// // // //       if (controller.availablePosts.isEmpty) {
// // // //         return const Center(
// // // //           child: Text("No available food posts 🍱",
// // // //               style: TextStyle(color: Colors.grey)),
// // // //         );
// // // //       }

// // // //       return ListView.builder(
// // // //         itemCount: controller.availablePosts.length,
// // // //         padding: const EdgeInsets.all(12),
// // // //         itemBuilder: (context, index) {
// // // //           final post = controller.availablePosts[index];
// // // //           return _buildPostCard(post, isAvailable: true);
// // // //         },
// // // //       );
// // // //     });
// // // //   }

// // // //   Widget _buildClaimedPostsTab() {
// // // //     return Obx(() {
// // // //       if (controller.isLoading.value) {
// // // //         return const Center(child: CircularProgressIndicator());
// // // //       }

// // // //       if (controller.claimedPosts.isEmpty) {
// // // //         return const Center(
// // // //           child: Text("No claimed food posts 🍱",
// // // //               style: TextStyle(color: Colors.grey)),
// // // //         );
// // // //       }

// // // //       return ListView.builder(
// // // //         itemCount: controller.claimedPosts.length,
// // // //         padding: const EdgeInsets.all(12),
// // // //         itemBuilder: (context, index) {
// // // //           final post = controller.claimedPosts[index];
// // // //           return _buildPostCard(post, isClaimed: true);
// // // //         },
// // // //       );
// // // //     });
// // // //   }

// // // //   Widget _buildStatsCard() {
// // // //     return Card(
// // // //       margin: const EdgeInsets.all(12),
// // // //       child: Padding(
// // // //         padding: const EdgeInsets.all(16),
// // // //         child: Row(
// // // //           mainAxisAlignment: MainAxisAlignment.spaceAround,
// // // //           children: [
// // // //             _buildStatItem('Total', controller.userStats['totalPosts'] ?? 0),
// // // //             _buildStatItem(
// // // //                 'Available', controller.userStats['availablePosts'] ?? 0),
// // // //             _buildStatItem(
// // // //                 'Claimed', controller.userStats['claimedPosts'] ?? 0),
// // // //             _buildStatItem(
// // // //                 'Completed', controller.userStats['completedPosts'] ?? 0),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildStatItem(String label, int count) {
// // // //     return Column(
// // // //       children: [
// // // //         Text(
// // // //           '$count',
// // // //           style: const TextStyle(
// // // //             fontSize: 18,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: Colors.green,
// // // //           ),
// // // //         ),
// // // //         Text(
// // // //           label,
// // // //           style: const TextStyle(
// // // //             fontSize: 12,
// // // //             color: Colors.grey,
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildPostCard(
// // // //     FoodPostModel post, {
// // // //     bool isMyPost = false,
// // // //     bool isAvailable = false,
// // // //     bool isClaimed = false,
// // // //   }) {
// // // //     return SingleChildScrollView(
// // // //       child: Column(
// // // //         children: [
// // // //           FoodPostCard(
// // // //             post: post,
// // // //             onDelete: () => controller.deletePost(post.id),
// // // //             onClaim: () => controller.claimPost(post.id),
// // // //             onComplete: () => controller.completePost(post.id),
// // // //           )
// // // //         ],
// // // //       ),
// // // //     );

// // // //     // Card(
// // // //     //   elevation: 4,
// // // //     //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // //     //   margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
// // // //     //   child: Padding(
// // // //     //     padding: const EdgeInsets.all(12),
// // // //     //     child: Column(
// // // //     //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //     //       children: [
// // // //     //         Text(post.foodDetails,
// // // //     //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // // //     //         const SizedBox(height: 4),
// // // //     //         Text("📍 ${post.address}",
// // // //     //             style: TextStyle(color: Colors.grey[700])),
// // // //     //         Text("🕒 Pickup: ${post.pickupTime}"),
// // // //     //         Text("🍱 Quantity: ${post.quantity}"),
// // // //     //         Text("📦 Status: ${post.status.toUpperCase()}",
// // // //     //             style:
// // // //     //                 TextStyle(color: controller.getStatusColor(post.status))),
// // // //     //         if (post.claimedBy != null)
// // // //     //           Text("🙋‍♂️ Claimed by: ${post.claimedBy}",
// // // //     //               style: const TextStyle(color: Colors.orange)),
// // // //     //       ],
// // // //     //     ),
// // // //     //   ),
// // // //     // );
// // // //   }
// // // // }

// // // // class FoodPostCard extends StatelessWidget {
// // // //   final FoodPostModel post;
// // // //   final VoidCallback? onDelete;
// // // //   final VoidCallback? onClaim;
// // // //   final VoidCallback? onComplete;

// // // //   final List<String> randomImages = [
// // // //     "assets/images/nHome1.png",
// // // //     "assets/images/nHome2.png",
// // // //     "assets/images/nHome3.png",
// // // //     "assets/images/nHome4.jpg",
// // // //     "assets/images/nHome5.jpg",
// // // //     "assets/images/nHome6.jpg",
// // // //     "assets/images/nHome7.jpg",
// // // //     "assets/images/nHome8.jpg",
// // // //     "assets/images/nHome9.jpg",
// // // //     "assets/images/nHome10.jpg",
// // // //   ];
// // // //   final controller = Get.put(FoodPostController());
// // // //   final user = FirebaseAuth.instance.currentUser;

// // // //   FoodPostCard({
// // // //     super.key,
// // // //     required this.post,
// // // //     this.onDelete,
// // // //     this.onClaim,
// // // //     this.onComplete,
// // // //   });

// // // //   String getRandomImage() {
// // // //     randomImages.shuffle();
// // // //     return randomImages.first;
// // // //   }

// // // //   Color getStatusColor(String status) {
// // // //     switch (status.toLowerCase()) {
// // // //       case 'available':
// // // //         return Colors.green;
// // // //       case 'claimed':
// // // //         return Colors.orange;
// // // //       case 'completed':
// // // //         return Colors.blue;
// // // //       default:
// // // //         return Colors.grey;
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Card(
// // // //       elevation: 3,
// // // //       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // // //       clipBehavior: Clip.hardEdge,
// // // //       child: InkWell(
// // // //         onTap: onClaim ?? () {}, // Optional tap
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             // 🔹 Image Header
// // // //             ClipRRect(
// // // //               borderRadius:
// // // //                   const BorderRadius.vertical(top: Radius.circular(16)),
// // // //               child: Image.asset(
// // // //                 getRandomImage(),
// // // //                 height: 150,
// // // //                 width: double.infinity,
// // // //                 fit: BoxFit.cover,
// // // //               ),
// // // //             ),

// // // //             // 🔹 Food Details
// // // //             Padding(
// // // //               padding: const EdgeInsets.all(12),
// // // //               child: Column(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   Text(
// // // //                     post.foodDetails,
// // // //                     style: const TextStyle(
// // // //                       fontSize: 17,
// // // //                       fontWeight: FontWeight.w600,
// // // //                       color: Colors.deepPurple,
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(height: 6),
// // // //                   Row(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     children: [
// // // //                       const Icon(Icons.location_on,
// // // //                           color: Colors.redAccent, size: 16),
// // // //                       const SizedBox(width: 4),
// // // //                       Expanded(
// // // //                         child: Text(
// // // //                           post.address,
// // // //                           style: const TextStyle(
// // // //                               fontSize: 13, color: Colors.black87),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   const SizedBox(height: 4),
// // // //                   Row(
// // // //                     children: [
// // // //                       const Icon(Icons.timer, color: Colors.grey, size: 16),
// // // //                       const SizedBox(width: 4),
// // // //                       Text(
// // // //                         "Pickup: ${post.pickupTime}",
// // // //                         style: const TextStyle(fontSize: 13),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   const SizedBox(height: 4),
// // // //                   Row(
// // // //                     children: [
// // // //                       const Icon(Icons.fastfood, color: Colors.brown, size: 16),
// // // //                       const SizedBox(width: 4),
// // // //                       Text("Quantity: ${post.quantity}",
// // // //                           style: const TextStyle(fontSize: 13)),
// // // //                     ],
// // // //                   ),
// // // //                   const SizedBox(height: 6),
// // // //                   Text(
// // // //                     "Status: ${post.status.toUpperCase()}",
// // // //                     style: TextStyle(
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: getStatusColor(post.status),
// // // //                     ),
// // // //                   ),
// // // //                   if (post.claimedBy != null && post.claimedBy!.isNotEmpty) ...[
// // // //                     const SizedBox(height: 4),
// // // //                     Text(
// // // //                       "Claimed by: ${post.claimedBy}",
// // // //                       style: const TextStyle(
// // // //                         color: Colors.orange,
// // // //                         fontWeight: FontWeight.w500,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                   const SizedBox(height: 6),
// // // //                   Text(
// // // //                     "📅 Posted: ${post.createdAt.toDate()}",
// // // //                     style: const TextStyle(fontSize: 11, color: Colors.grey),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),

// // // //             // 🔹 Action Buttons
// // // //             Padding(
// // // //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // // //               child: Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                 children: [
// // // //                   _buildTrailingActions(
// // // //                     context,
// // // //                     post,
// // // //                     isMyPost: onDelete != null,
// // // //                     isAvailable: post.status == "available",
// // // //                     isClaimed: post.status == "claimed",
// // // //                   ),
// // // //                   if (onClaim != null && post.status == "available")
// // // //                     ElevatedButton.icon(
// // // //                       onPressed: onClaim,
// // // //                       icon: const Icon(Icons.volunteer_activism, size: 16),
// // // //                       label: const Text("Claim"),
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: Colors.orange,
// // // //                         foregroundColor: Colors.white,
// // // //                         shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(8)),
// // // //                       ),
// // // //                     ),
// // // //                   if (onComplete != null && post.status == "claimed")
// // // //                     ElevatedButton.icon(
// // // //                       onPressed: onComplete,
// // // //                       icon: const Icon(Icons.check_circle, size: 16),
// // // //                       label: const Text("Complete"),
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: Colors.blue,
// // // //                         foregroundColor: Colors.white,
// // // //                         shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(8)),
// // // //                       ),
// // // //                     ),
// // // //                   // if (onDelete != null)
// // // //                   //   IconButton(
// // // //                   //     onPressed: onDelete,
// // // //                   //     icon: const Icon(Icons.delete_outline,
// // // //                   //         color: Colors.redAccent),
// // // //                   //   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildTrailingActions(
// // // //     BuildContext context,
// // // //     FoodPostModel post, {
// // // //     bool isMyPost = false,
// // // //     bool isAvailable = false,
// // // //     bool isClaimed = false,
// // // //   }) {
// // // //     if (isMyPost) {
// // // //       return IconButton(
// // // //         icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
// // // //         onPressed: () {
// // // //           _showDeleteDialog(post, context);
// // // //         },
// // // //       );
// // // //     } else if (isAvailable) {
// // // //       return ElevatedButton(
// // // //         onPressed: () => controller.claimPost(post.id),
// // // //         style: ElevatedButton.styleFrom(
// // // //           backgroundColor: Colors.green,
// // // //           foregroundColor: Colors.white,
// // // //         ),
// // // //         child: const Text('Claim'),
// // // //       );
// // // //     } else if (isClaimed) {
// // // //       return Column(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           if (post.status == 'claimed')
// // // //             ElevatedButton(
// // // //               onPressed: () => controller.completePost(post.id),
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: Colors.blue,
// // // //                 foregroundColor: Colors.white,
// // // //               ),
// // // //               child: const Text('Complete'),
// // // //             ),
// // // //           if (post.status == 'claimed')
// // // //             TextButton(
// // // //               onPressed: () => controller.cancelClaim(post.id),
// // // //               child: const Text('Cancel', style: TextStyle(color: Colors.red)),
// // // //             ),
// // // //         ],
// // // //       );
// // // //     }

// // // //     return const SizedBox.shrink();
// // // //   }

// // // //   void _showDeleteDialog(FoodPostModel post, BuildContext context) {
// // // //     Get.dialog(
// // // //       AlertDialog(
// // // //         title: const Text("Delete Post"),
// // // //         content: const Text("Are you sure you want to delete this food post?"),
// // // //         actions: [
// // // //           TextButton(
// // // //             onPressed: () => Navigator.of(context).pop(),
// // // //             child: const Text("Cancel"),
// // // //           ),
// // // //           TextButton(
// // // //             onPressed: () {
// // // //               controller.deletePost(post.id);
// // // //               Navigator.of(context).pop();
// // // //             },
// // // //             child: const Text("Delete", style: TextStyle(color: Colors.red)),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
