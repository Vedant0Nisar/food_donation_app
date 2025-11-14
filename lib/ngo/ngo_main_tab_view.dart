import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/authenticate/login_page.dart';
import 'package:food_donation_app/ngo/home_view.dart';
import 'package:food_donation_app/ngo/ngo.dart';
import 'package:food_donation_app/volunteer/donate/v_donate_page.dart';
import 'package:food_donation_app/volunteer/history/v_history_controller.dart';
import 'package:food_donation_app/volunteer/history/v_history_page.dart';
import 'package:food_donation_app/volunteer/home/v_home_page.dart';
import 'package:food_donation_app/volunteer/profile/v_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class NGOMainTabView extends StatefulWidget {
  const NGOMainTabView({super.key});

  @override
  State<NGOMainTabView> createState() => _NGOMainTabViewState();
}

class _NGOMainTabViewState extends State<NGOMainTabView> {
  var _currentIndex = 0;
  List pages = [
    const NGOHomePage(),
    // const VDonatePage(),
    // FoodPostHistoryView(),
    NgoMainView(), VProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    // final AuthController authController = Get.put(AuthController());

    // Safety check - if user is not volunteer, redirect to login
    if (authController.userType.value != UserType.ngo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => LoginPage());
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: SalomonBottomBar(
            onTap: ((index) async {
              setState(() {});
              _currentIndex = index;
              // if (_currentIndex == 2) {
              //   // Refresh history page when navigated to

              //   var controller = Get.find<FoodPostController>();

              //   // await controller.loadStats();
              //   controller.refreshData();
              // }
            }),
            currentIndex: _currentIndex,
            items: [
              /// Home
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_outlined),
                title: const Text("Home"),
                selectedColor: Colors.purple,
              ),

              /// Likes
              // SalomonBottomBarItem(
              //   icon: const Icon(Icons.add_box_outlined, size: 30),
              //   title: const Text("Post"),
              //   selectedColor: Colors.red,
              // ),

              /// Search
              SalomonBottomBarItem(
                icon: const Icon(Icons.post_add_outlined),
                title: const Text("Posts"),
                selectedColor: Colors.orange,
              ),

              /// Profile
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                title: const Text("Profile"),
                selectedColor: Colors.teal,
              ),
            ]),
      ),
    );
  }
}
