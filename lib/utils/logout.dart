import 'package:food_donation_app/authenticate/login_page.dart';
import 'package:food_donation_app/utils/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart';

class LogOut {
  Future logOut(BuildContext context) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    sharedPreferences.remove("accountNo");
    sharedPreferences.remove("type");
    sharedPreferences.remove("username");
    UserType = null;
    UserAccountNo = null;
    UserUsername = null;
    // Navigator.pushReplacementNamed(context, Routes().loginRoute);
    Get.offAll(() => LoginPage());
  }
}
