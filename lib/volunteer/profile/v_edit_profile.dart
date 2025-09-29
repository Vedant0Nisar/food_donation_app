import 'package:flutter/material.dart';
import 'package:food_donation_app/authenticate/model.dart';
import 'package:food_donation_app/volunteer/profile/V_profile_service.dart';
import 'package:get/get.dart';

class VEditProfile extends StatefulWidget {
  const VEditProfile({super.key});

  @override
  _VEditProfileState createState() => _VEditProfileState();
}

class _VEditProfileState extends State<VEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  final _c_firstName = TextEditingController();
  final _c_lastName = TextEditingController();
  final _c_address = TextEditingController();
  final _c_zipCode = TextEditingController();

  bool data = false;
  UserModel? _userProfile;

  @override
  void initState() {
    userProfile();
    super.initState();
  }

  Future userProfile() async {
    try {
      _userProfile = await _profileService.getUserProfile();

      setState(() {
        if (_userProfile != null) {
          // Split username into first and last name
          List<String> nameParts = _userProfile!.username.split(' ');
          _c_firstName.text = nameParts.isNotEmpty ? nameParts.first : '';
          _c_lastName.text =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // Handle address for NGO users
          if (_userProfile is NgoModel) {
            _c_address.text = (_userProfile as NgoModel).address;
            _c_zipCode.text = (_userProfile as NgoModel).pincode;
          }

          data = true;
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        data = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: const Text('Edit Profile'),
      ),
      body: data == false
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _c_firstName,
                        decoration:
                            const InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _c_lastName,
                        decoration:
                            const InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _c_address,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _c_zipCode,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Zip Code'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your zip code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                          child: SizedBox(
                        height: 50,
                        width: 360,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: ((context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }));

                              bool flag = await _profileService.updateProfile(
                                firstName: _c_firstName.text,
                                lastName: _c_lastName.text,
                                address: _c_address.text,
                                pincode: _c_zipCode.text,
                              );

                              if (flag == true) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text("Something went wrong"),
                                ));
                              }
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
