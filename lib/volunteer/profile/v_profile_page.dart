import 'dart:convert';
import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/authenticate/model.dart';
import 'package:food_donation_app/firebase_services/auth_service.dart';
import 'package:food_donation_app/utils/globals.dart';
import 'package:food_donation_app/utils/routes.dart';
import 'package:food_donation_app/volunteer/profile/V_profile_service.dart';
import 'package:food_donation_app/volunteer/profile/v_edit_profile.dart';
import 'package:food_donation_app/widgets/dialogue_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:food_donation_app/authenticate/auth_controller.dart' as auth;

class VProfilePage extends StatefulWidget {
  const VProfilePage({super.key});

  @override
  State<VProfilePage> createState() => _VProfilePageState();
}

class _VProfilePageState extends State<VProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthController _authController = Get.find<AuthController>();

  String? name;
  String? email;
  String? address;
  String? phoneNo;
  bool data = false;
  String? errorMessage;

  @override
  void initState() {
    print('🔄 VProfilePage initState called');
    userProfile();
    super.initState();
  }

  Future userProfile() async {
    print('🔄 Starting userProfile fetch...');

    setState(() {
      data = false;
      errorMessage = null;
    });

    try {
      UserModel? userProfile = await _profileService.getUserProfile();

      print('🔄 Profile fetched: ${userProfile != null}');

      if (userProfile != null) {
        setState(() {
          name = userProfile.username;
          email = userProfile.email;
          phoneNo = userProfile.phone;

          if (userProfile is NgoModel) {
            address = userProfile.address.isNotEmpty
                ? "${userProfile.address} ${userProfile.pincode}"
                : null;
          } else {
            address = null;
          }

          data = true;
        });
        print('✅ Profile data loaded successfully');
      } else {
        setState(() {
          errorMessage = 'No profile data found';
          data = true; // Set to true to show error UI
        });
        print('❌ No profile data found');
      }
    } catch (e) {
      print('❌ Error in userProfile: $e');
      setState(() {
        errorMessage = 'Failed to load profile: $e';
        data = true; // Set to true to show error UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        resizeToAvoidBottomInset: true,
        body: !data
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $errorMessage'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          // onPressed: userProfile,
                          onPressed: AuthController().signOut,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // YOUR EXACT UI CODE HERE - KEEP EVERYTHING THE SAME
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 155, 110, 246),
                                Color.fromARGB(255, 116, 182, 247)
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 25),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'My Profile',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    IconButton(
                                        onPressed: (() {
                                          showDialog(
                                              context: context,
                                              builder: ((context) =>
                                                  MyDialogue()
                                                      .logotDialogue(context)));
                                        }),
                                        icon: const Icon(
                                          Icons.logout_outlined,
                                          color: Colors.white,
                                        ))
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(children: [
                                Stack(
                                  children: [
                                    Positioned(
                                      top: 200,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20)),
                                        ),
                                        height: 600,
                                        width: 400,
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 50,
                                            left: 10,
                                            right: 10,
                                            bottom: 30,
                                          ),
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            elevation: 5,
                                            child: Center(
                                                child: Column(
                                              children: [
                                                const SizedBox(height: 90),
                                                Text(
                                                  name ?? 'User',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  _authController
                                                              .userType.value ==
                                                          auth.UserType.ngo
                                                      ? 'NGO'
                                                      : 'VOLUNTEER',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey),
                                                ),
                                                const SizedBox(height: 30),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: const [],
                                                  ),
                                                )
                                              ],
                                            )),
                                          ),
                                        ),
                                        Stack(children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(80.0),
                                            child: const FadeInImage(
                                              placeholder: AssetImage(
                                                  'assets/images/avtar.png'),
                                              image: NetworkImage(
                                                  'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                                              height: 120,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                75, 75, 0, 0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurple,
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                              ),
                                              child: IconButton(
                                                color: Colors.white,
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  Get.offAll(
                                                          () => VEditProfile())
                                                      ?.then((_) {
                                                    setState(() {
                                                      userProfile();
                                                    });
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              ]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                child: SizedBox(
                                  width: 600,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: RichText(
                                          text: const TextSpan(children: [
                                            WidgetSpan(
                                              child: Icon(
                                                Icons.location_on_outlined,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            TextSpan(
                                              text: " Address",
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 16),
                                            ),
                                          ]),
                                        ),
                                      ),
                                      address != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 40),
                                              child: Text(
                                                '$address',
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            )
                                          : Center(
                                              child: Column(
                                                children: [
                                                  const SizedBox(height: 20),
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      Get.to(
                                                          () => VEditProfile());
                                                    },
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 24.0,
                                                    ),
                                                    label: const Text(
                                                        'add address'),
                                                  ),
                                                  const SizedBox(height: 30),
                                                ],
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Divider(thickness: 2),
                              const SizedBox(height: 10),
                              infoCard(
                                  ' Mobile',
                                  "+91-${phoneNo ?? 'Not provided'}",
                                  Icons.phone_outlined),
                              const SizedBox(height: 10),
                              const Divider(thickness: 2),
                              const SizedBox(height: 10),
                              infoCard(
                                  ' Email', "$email", Icons.email_outlined),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // Keep your existing infoCard and buildStat methods exactly the same
  Widget infoCard(String keyName, String valueName, IconData iconName) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        width: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: RichText(
                text: TextSpan(children: [
                  WidgetSpan(
                    child: Icon(
                      iconName,
                      color: Colors.grey,
                    ),
                  ),
                  TextSpan(
                    text: keyName,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: valueName,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget buildStat(String numberText, String titleText) {
    return Column(
      children: [
        Text(numberText,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        Text(titleText,
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
