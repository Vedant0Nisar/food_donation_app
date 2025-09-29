import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/authenticate/login_page.dart';
import 'package:food_donation_app/volunteer/donate/v_donate_page.dart';
import 'package:food_donation_app/volunteer/history/v_history_page.dart';
import 'package:food_donation_app/volunteer/home/v_home_page.dart';
import 'package:food_donation_app/volunteer/profile/v_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class VMainPage extends StatefulWidget {
  const VMainPage({super.key});

  @override
  State<VMainPage> createState() => _VHomePageState();
}

class _VHomePageState extends State<VMainPage> {
  var _currentIndex = 0;
  List pages = [
    const VHomePage(),
    const VDonatePage(),
    const VHistory(),
    const VProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Safety check - if user is not volunteer, redirect to login
    if (authController.userType.value != UserType.volunteer) {
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
            onTap: ((index) {
              setState(() {});
              _currentIndex = index;
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
              SalomonBottomBarItem(
                icon: const Icon(Icons.add_box_outlined, size: 30),
                title: const Text("Post"),
                selectedColor: Colors.red,
              ),

              /// Search
              SalomonBottomBarItem(
                icon: const Icon(Icons.history),
                title: const Text("history"),
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
