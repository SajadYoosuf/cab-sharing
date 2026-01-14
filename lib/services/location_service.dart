import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<String?> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled. Please enable them in settings.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permission denied. This app needs location to find nearby rides.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied. Please enable them in app settings.';
      } 

      return null; // Success
    } catch (e) {
      return 'Location permissions are not configured correctly in the manifest. Please restart the app.';
    }
  }

  Future<Position?> getCurrentLocation() async {
    final error = await checkAndRequestPermission();
    if (error != null) return null;
    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      // Handle error
    }
    return "Unknown Location";
  }

  Future<List<double>?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return [locations.first.latitude, locations.first.longitude];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
