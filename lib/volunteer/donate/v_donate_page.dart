import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:food_donation_app/volunteer/donate/v_firebase_food_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:food_donation_app/volunteer/donate/get_location.dart';
import 'package:food_donation_app/widgets/text_fields.dart';
import 'package:food_donation_app/utils/routes.dart';

class VDonatePage extends StatefulWidget {
  const VDonatePage({super.key});

  @override
  State<VDonatePage> createState() => _VDonatePageState();
}

class _VDonatePageState extends State<VDonatePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  // Controllers
  final food_details = TextEditingController();
  final address_details = TextEditingController();
  final zip_details = TextEditingController();

  // State variables
  double maxValue = 2;
  bool useCurrentLocation = false;
  bool isLocationLoading = false;
  String? latitude;
  String? longitude;
  TimeOfDay _timeOfDay = TimeOfDay.now();

  @override
  void dispose() {
    food_details.dispose();
    address_details.dispose();
    zip_details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Create New Post",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () => _postRequest(),
                child: authController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Post",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              _buildUserInfo(),
              const SizedBox(height: 24),

              // Food details section
              _buildFoodDetailsSection(),
              const SizedBox(height: 24),

              // Quantity section
              _buildQuantitySection(),
              const SizedBox(height: 24),

              // Cooking time section
              _buildCookingTimeSection(),
              const SizedBox(height: 24),

              // Address section
              _buildAddressSection(),
              const SizedBox(height: 32),

              // Post button
              _buildPostButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Obx(() {
      final user = authController.userModel.value;
      if (user == null) {
        return const Row(
          children: [
            CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 10),
            Text("Loading user..."),
          ],
        );
      }

      return Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.isNotEmpty ? user.username : 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFoodDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Food Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: food_details,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Describe the food you want to donate...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe the food details';
            }
            if (value.trim().length < 10) {
              return 'Please provide more detailed description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Food Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    intl.NumberFormat.decimalPatternDigits(decimalDigits: 0)
                        .format(maxValue),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    maxValue == 1 ? "person" : "people",
                    style: TextStyle(color: Colors.deepPurple.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.deepPurple,
            thumbColor: Colors.deepPurple,
            overlayColor: Colors.deepPurple.withOpacity(0.2),
          ),
          child: Slider(
            min: 1,
            max: 100,
            divisions: 99,
            value: maxValue,
            onChanged: (value) {
              setState(() {
                maxValue = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCookingTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pickup Time",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showTimePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  _timeOfDay.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  "Tap to change",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pickup Address",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Current location checkbox
        Row(
          children: [
            Checkbox(
              value: useCurrentLocation,
              onChanged: isLocationLoading
                  ? null
                  : (checked) async {
                      if (checked == true) {
                        await _getCurrentLocation();
                      } else {
                        setState(() {
                          useCurrentLocation = false;
                          address_details.clear();
                          zip_details.clear();
                          latitude = null;
                          longitude = null;
                        });
                      }
                    },
              activeColor: Colors.deepPurple,
            ),
            Expanded(
              child: Text(
                'Use my current location',
                style: TextStyle(
                  fontSize: 14,
                  color: isLocationLoading ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            if (isLocationLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Address field
        TextFormField(
          controller: address_details,
          enabled: !isLocationLoading,
          decoration: InputDecoration(
            labelText: "Pickup Address",
            hintText: "Enter your pickup address",
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter pickup address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Zip code field
        TextFormField(
          controller: zip_details,
          enabled: !isLocationLoading,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Zip Code",
            hintText: "Enter zip code",
            prefixIcon: const Icon(Icons.pin_drop),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter zip code';
            }
            if (value.trim().length < 5) {
              return 'Please enter valid zip code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPostButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authController.isLoading.value ? null : _postRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: authController.isLoading.value
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Posting..."),
                    ],
                  )
                : const Text(
                    "Post Food Donation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: _timeOfDay,
    ).then((value) {
      if (value != null) {
        setState(() {
          _timeOfDay = value;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLocationLoading = true;
      });

      final locationService = GetLocatinState();
      final data = await locationService.getAddress();

      if (data != null && mounted) {
        setState(() {
          useCurrentLocation = true;
          address_details.text =
              "${data['locality'] ?? ''}, ${data['country'] ?? ''}";
          zip_details.text = data['zip_code']?.toString() ?? '';
          latitude = data['lattitude']?.toString();
          longitude = data['longitude']?.toString();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to get location data');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        useCurrentLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _postRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = authController.userModel.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Set loading state in auth controller
      authController.isLoading.value = true;

      // Use Firebase service instead of API
      final firebaseFoodService = FirebaseFoodService.instance;

      final success = await firebaseFoodService.insertFoodPostData(
        userUid: user.uid,
        foodDetails: food_details.text.trim(),
        quantity: maxValue.toString(),
        pickupTime: _timeOfDay.format(context),
        address: address_details.text.trim(),
        zipCode: zip_details.text.trim(),
        longitude: longitude ?? '0.0',
        latitude: latitude ?? '0.0',
        status: 'available',
      );

      // if (!mounted) return;

      if (success) {
        // Clear form after successful post
        _clearForm();

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'Food Donation Posted!',
          desc: 'Thank you for donating food to help others in need',
          btnOkOnPress: () {
            Get.back(); // Go back to main page
          },
        ).show();
      } else {
        throw Exception('Failed to post food donation');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting donation: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        authController.isLoading.value = false;
      }
    }
  }

  void _clearForm() {
    food_details.clear();
    address_details.clear();
    zip_details.clear();
    setState(() {
      maxValue = 2;
      useCurrentLocation = false;
      latitude = null;
      longitude = null;
      _timeOfDay = TimeOfDay.now();
    });
  }
}
