import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_donation_app/ngo/ngo.dart';
import 'package:food_donation_app/ngo/ngo_main_tab_view.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/authenticate/email_verification.dart';
import 'package:food_donation_app/intro/splash_screen.dart';
import 'package:food_donation_app/intro/walkthrough.dart';
import 'package:food_donation_app/intro/welcome_page.dart';
import 'package:food_donation_app/volunteer/v_main_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize GetStorage
  await GetStorage.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 250, 250, 250),
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      home: GetBuilder<AuthController>(
        init: AuthController(),
        builder: (controller) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Show splash while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }

              return Obx(() => _buildInitialScreen(controller, snapshot.data));
            },
          );
        },
      ),
    );
  }

  Widget _buildInitialScreen(AuthController controller, User? user) {
    // Show splash while loading user data
    if (controller.isLoading.value) {
      return SplashScreen();
    }

    // User is logged in and email verified
    if (user != null && user.emailVerified) {
      if (controller.userType.value == UserType.volunteer) {
        return VMainPage();
      } else if (controller.userType.value == UserType.ngo) {
        return NGOMainTabView();
      } else {
        // User type not determined yet, trigger load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadUserData(user.uid);
        });
        return SplashScreen();
      }
    }

    // User needs email verification
    if (user != null && !user.emailVerified) {
      return EmailVerificationScreen();
    }

    // No user logged in - check walkthrough status
    final storage = GetStorage();
    bool walkthroughCompleted = storage.read('walkthroughCompleted') ?? false;

    if (!walkthroughCompleted) {
      return Walkthrough();
    }

    return WelcomePage();
  }
}
