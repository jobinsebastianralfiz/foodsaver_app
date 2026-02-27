import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String city;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.address,
  });
}

class LocationService {
  /// Check and request location permissions, then get current position.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get current location with reverse-geocoded address and city.
  Future<LocationResult> getCurrentLocation() async {
    final position = await getCurrentPosition();

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String city = '';
    String address = '';

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
      address = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      address: address,
    );
  }

  /// Reverse geocode coordinates to get city and address.
  Future<LocationResult> reverseGeocode(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);

    String city = '';
    String address = '';

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
      address = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return LocationResult(
      latitude: lat,
      longitude: lng,
      city: city,
      address: address,
    );
  }

  /// Calculate distance in km between two coordinates using Haversine formula.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
