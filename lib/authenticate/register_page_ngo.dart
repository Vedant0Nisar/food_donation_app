import 'package:flutter/material.dart';
import 'package:food_donation_app/authenticate/auth_controller.dart';
import 'package:get/get.dart';

class NgoRegistrationForm extends StatefulWidget {
  const NgoRegistrationForm({super.key});

  @override
  State<NgoRegistrationForm> createState() => _NgoRegistrationFormState();
}

class _NgoRegistrationFormState extends State<NgoRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  // Controllers
  final _ngoNameController = TextEditingController();
  final _ngoIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // NGO Type dropdown
  String? _selectedNgoType;
  final List<String> _ngoTypes = [
    'Private Sector Companies',
    'Registered Societies (Non-Govt)',
    'Trust (Non-Govt)',
    'Other Registered Entities (Non-Govt)',
    'Academic Institutions (Private)',
    'Academic Institutions (Govt)'
  ];
  // Add this helper function anywhere above your widget (e.g., top of file)
  String? validateStrongPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter password';
    }

    // Standard strong password regex
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&^#_\-])[A-Za-z\d@$!%*?&^#_\-]{8,}$',
    );

    if (!regex.hasMatch(password)) {
      return 'Password must include upper, lower, number & special character';
    }

    return null; // ✅ Valid
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // NGO Details Section
                    _buildSectionTitle('NGO Details'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _ngoNameController,
                      label: 'NGO Name',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter NGO name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _ngoIdController,
                      label: 'NGO Unique ID',
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter NGO unique ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildDropdownField(),
                    const SizedBox(height: 24),

                    // Contact Details Section
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (value.length != 10) {
                          return 'Please enter valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pincode';
                        }
                        if (value.length != 6) {
                          return 'Please enter valid 6-digit pincode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.home_outlined,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Account Details Section
                    _buildSectionTitle('Account Information'),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // _buildTextField(
                    //   controller: _passwordController,
                    //   label: 'Password',
                    //   icon: Icons.lock_outline,
                    //   obscureText: _obscurePassword,
                    //   suffixIcon: IconButton(
                    //     icon: Icon(
                    //       _obscurePassword
                    //           ? Icons.visibility_off
                    //           : Icons.visibility,
                    //       color: Colors.grey.shade600,
                    //     ),
                    //     onPressed: () {
                    //       setState(() {
                    //         _obscurePassword = !_obscurePassword;
                    //       });
                    //     },
                    //   ),
                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) {
                    //       return 'Please enter password';
                    //     }
                    //     if (value.length < 6) {
                    //       return 'Password must be at least 6 characters';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    // const SizedBox(height: 10),

                    // _buildTextField(
                    //   controller: _confirmPasswordController,
                    //   label: 'Confirm Password',
                    //   icon: Icons.lock_outline,
                    //   obscureText: _obscureConfirmPassword,
                    //   suffixIcon: IconButton(
                    //     icon: Icon(
                    //       _obscureConfirmPassword
                    //           ? Icons.visibility_off
                    //           : Icons.visibility,
                    //       color: Colors.grey.shade600,
                    //     ),
                    //     onPressed: () {
                    //       setState(() {
                    //         _obscureConfirmPassword = !_obscureConfirmPassword;
                    //       });
                    //     },
                    //   ),
                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) {
                    //       return 'Please confirm password';
                    //     }
                    //     if (value != _passwordController.text) {
                    //       return 'Passwords do not match';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator:
                          validateStrongPassword, // ✅ Replaced old inline logic
                    ),

                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed:
                      _authController.isLoading.value ? null : _registerNgo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _authController.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register NGO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelStyle: TextStyle(color: Colors.deepPurple, fontSize: 13),
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedNgoType,
      style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
      decoration: InputDecoration(
        labelText: 'NGO Type',
        labelStyle: TextStyle(color: Colors.deepPurple, fontSize: 13),
        prefixIcon:
            const Icon(Icons.card_travel_rounded, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _ngoTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedNgoType = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select NGO type';
        }
        return null;
      },
    );
  }

  void _registerNgo() async {
    if (_formKey.currentState!.validate()) {
      // Check NGO ID availability
      bool ngoIdAvailable =
          await _authController.checkNgoIdAvailability(_ngoIdController.text);
      if (!ngoIdAvailable) {
        _authController.showErrorSnackbar('NGO ID already exists');
        return;
      }

      // Check username availability
      bool usernameAvailable = await _authController
          .checkUsernameAvailability(_usernameController.text);
      if (!usernameAvailable) {
        _authController.showErrorSnackbar('Username already exists');
        return;
      }

      // // Check email availability
      // bool emailAvailable =
      //     await _authController.checkEmailAvailability(_emailController.text);
      // if (!emailAvailable) {
      //   _authController.showErrorSnackbar('Email already registered');
      //   return;
      // }

      // Check phone availability
      bool phoneAvailable =
          await _authController.checkPhoneAvailability(_phoneController.text);
      if (!phoneAvailable) {
        _authController.showErrorSnackbar('Phone number already registered');
        return;
      }

      // Register NGO
      await _authController.signUpNgo(
        ngoName: _ngoNameController.text.trim(),
        ngoId: _ngoIdController.text.trim(),
        ngoType: _selectedNgoType!,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        pincode: _pincodeController.text.trim(),
        address: _addressController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (_authController.otpSent.value) {
        Get.toNamed('/email-verification');
      }
    }
  }

  @override
  void dispose() {
    _ngoNameController.dispose();
    _ngoIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
