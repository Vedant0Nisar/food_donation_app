// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoFoodPostModel {
  final String id;
  final String address;
  final String? claimedBy;
  final Timestamp? claimedAt;
  final Timestamp? completedAt;
  final Timestamp createdAt;
  final String foodDetails;
  final bool isActive;
  final int likes;
  final double latitude;
  final double longitude;
  final String pickupTime;
  final String quantity;
  final int quantityNumber;
  final List<String> searchKeywords;
  final String status;
  final Timestamp updatedAt;
  final String userEmail;
  final String userName;
  final String userPhone;
  final String userType;
  final String userUid;
  final int views;
  final String zipCode;

  NgoFoodPostModel({
    required this.id,
    required this.address,
    required this.claimedBy,
    required this.claimedAt,
    required this.completedAt,
    required this.createdAt,
    required this.foodDetails,
    required this.isActive,
    required this.likes,
    required this.latitude,
    required this.longitude,
    required this.pickupTime,
    required this.quantity,
    required this.quantityNumber,
    required this.searchKeywords,
    required this.status,
    required this.updatedAt,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.userType,
    required this.userUid,
    required this.views,
    required this.zipCode,
  });

  factory NgoFoodPostModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NgoFoodPostModel(
      id: doc.id,
      address: data['address'] ?? '',
      claimedBy: data['claimedBy'],
      claimedAt: data['claimedAt'],
      completedAt: data['completedAt'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      foodDetails: data['foodDetails'] ?? '',
      isActive: data['isActive'] ?? true,
      likes: data['likes'] ?? 0,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      pickupTime: data['pickupTime'] ?? '',
      quantity: data['quantity'] ?? '',
      quantityNumber: data['quantityNumber'] ?? 0,
      searchKeywords: (data['searchKeywords'] != null)
          ? List<String>.from(data['searchKeywords'])
          : [],
      status: data['status'] ?? 'available',
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userType: data['userType'] ?? '',
      userUid: data['userUid'] ?? '',
      views: data['views'] ?? 0,
      zipCode: data['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'claimedBy': claimedBy,
      'claimedAt': claimedAt,
      'completedAt': completedAt,
      'createdAt': createdAt,
      'foodDetails': foodDetails,
      'isActive': isActive,
      'likes': likes,
      'latitude': latitude,
      'longitude': longitude,
      'pickupTime': pickupTime,
      'quantity': quantity,
      'quantityNumber': quantityNumber,
      'searchKeywords': searchKeywords,
      'status': status,
      'updatedAt': updatedAt,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'userType': userType,
      'userUid': userUid,
      'views': views,
      'zipCode': zipCode,
    };
  }

  String toJson() => json.encode(toMap());
}
