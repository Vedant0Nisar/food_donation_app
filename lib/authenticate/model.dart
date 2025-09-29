// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_donation_app/authenticate/auth_controller.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String phone;
  final UserType userType;
  final bool emailVerified;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.phone,
    required this.userType,
    required this.emailVerified,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
      userType: data['userType'] == 'ngo' ? UserType.ngo : UserType.volunteer,
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'phone': phone,
      'userType': userType == UserType.ngo ? 'ngo' : 'volunteer',
      'emailVerified': emailVerified,
      'createdAt': createdAt,
    };
  }
}

class NgoModel extends UserModel {
  final String ngoName;
  final String ngoId;
  final String ngoType;
  final String address;
  final String pincode;
  final bool isVerified;

  NgoModel({
    required String uid,
    required String email,
    required String username,
    required String phone,
    required bool emailVerified,
    required DateTime createdAt,
    required this.ngoName,
    required this.ngoId,
    required this.ngoType,
    required this.address,
    required this.pincode,
    required this.isVerified,
  }) : super(
          uid: uid,
          email: email,
          username: username,
          phone: phone,
          userType: UserType.ngo,
          emailVerified: emailVerified,
          createdAt: createdAt,
        );

  factory NgoModel.fromMap(Map<String, dynamic> data) {
    return NgoModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      ngoName: data['ngoName'] ?? '',
      ngoId: data['ngoId'] ?? '',
      ngoType: data['ngoType'] ?? '',
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'phone': phone,
      'userType': 'ngo',
      'emailVerified': emailVerified,
      'createdAt': createdAt,
      'ngoName': ngoName,
      'ngoId': ngoId,
      'ngoType': ngoType,
      'address': address,
      'pincode': pincode,
      'isVerified': isVerified,
    };
  }
}
