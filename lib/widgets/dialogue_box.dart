import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/utils/logout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyDialogue {
  final AuthController authController = Get.find<AuthController>();
  // set up the AlertDialog
  logotDialogue(context) {
    return AlertDialog(
      title: const Text("Logout !"),
      content: const Text("Would you like to logout ?"),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              authController.signOut();
              Navigator.pop(context);
            }),
      ],
    );
  }
}
