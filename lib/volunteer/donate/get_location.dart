import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class GetLocatinState {
  loc.Location location = loc.Location();

  Future<Map<String, dynamic>?> getAddress() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is disabled');
        }
      }

      // Check location permission
      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }

      // Get current location
      loc.LocationData locationData =
          await location.getLocation().timeout(const Duration(seconds: 10));

      if (locationData.latitude == null || locationData.longitude == null) {
        throw Exception('Failed to get location coordinates');
      }

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isEmpty) {
        throw Exception('No address found for current location');
      }

      final placemark = placemarks.first;

      return {
        'lattitude': locationData.latitude,
        'longitude': locationData.longitude,
        'zip_code': placemark.postalCode ?? '',
        'locality': placemark.locality ?? placemark.subAdministrativeArea ?? '',
        'country': placemark.country ?? '',
        'street': placemark.street ?? '',
        'name': placemark.name ?? '',
        'subLocality': placemark.subLocality ?? '',
        'administrativeArea': placemark.administrativeArea ?? '',
      };
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  Future<bool> checkLocationPermission() async {
    try {
      loc.PermissionStatus permission = await location.hasPermission();
      return permission == loc.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      loc.PermissionStatus permission = await location.requestPermission();
      return permission == loc.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await location.serviceEnabled();
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationService() async {
    try {
      return await location.requestService();
    } catch (e) {
      return false;
    }
  }

  // Simple method to get just coordinates
  Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return null;
      }

      loc.LocationData locationData =
          await location.getLocation().timeout(const Duration(seconds: 10));

      if (locationData.latitude != null && locationData.longitude != null) {
        return {
          'latitude': locationData.latitude!,
          'longitude': locationData.longitude!,
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
