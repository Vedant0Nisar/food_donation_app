// services/profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_donation_app/authenticate/model.dart';
import 'package:get_storage/get_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  // String get _currentUid => _storage.read('currentUserUid') ?? '';
  // String get _userType => _storage.read('userType') ?? 'volunteer';

  // void clearUserUid() {

  //   _storage.remove('currentUserUid');
  // }
  var _currentUid = '';
  var _userType = 'volunteer';

  Future<UserModel?> getUserProfile() async {
    _currentUid = _storage.read('currentUserUid') ?? '';
    _userType = _storage.read('userType') ?? '';

    print('🔍 Starting getUserProfile...');
    print('🔍 Current UID: $_currentUid');
    print('🔍 User Type: $_userType');

    if (_currentUid.isEmpty) {
      print('❌ No UID found in storage!');
      return null;
    }

    try {
      String collection = _userType == 'ngo' ? 'ngos' : 'volunteers';
      print('🔍 Fetching from collection: $collection');

      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(_currentUid).get();

      print('🔍 Document exists: ${doc.exists}');

      if (doc.exists) {
        if (_userType == 'ngo') {
          print('✅ Returning NGO profile');
          return NgoModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          print('✅ Returning Volunteer profile');
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      } else {
        print('❌ No document found in Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? address,
    String? pincode,
  }) async {
    if (_currentUid.isEmpty) return false;

    try {
      String collection = _userType == 'ngo' ? 'ngos' : 'volunteers';
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_userType == 'volunteer') {
        if (firstName != null && lastName != null) {
          updateData['username'] = '$firstName $lastName';
        }
      } else {
        if (firstName != null) {
          updateData['ngoName'] = firstName;
        }
      }

      if (address != null) updateData['address'] = address;
      if (pincode != null) updateData['pincode'] = pincode;

      await _firestore
          .collection(collection)
          .doc(_currentUid)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
