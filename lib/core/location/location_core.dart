import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LocationState {
  unknown,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  approximate, // User granted approximate (mostly Android 12+)
  precise,     // User granted precise
  locating,    // Actively fetching
  ready,       // Location retrieved successfully
  error
}

class LocationResult {
  final LocationState state;
  final Position? position;
  final String? errorMessage;

  LocationResult({
    required this.state,
    this.position,
    this.errorMessage,
  });
}

class LocationService {
  Future<LocationState> checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationState.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationState.permissionDeniedForever;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationState.servicesDisabled;
    }

    // Determine precision (fallback to precise to avoid UnimplementedError on unsupported platforms)
    return LocationState.precise;
  }

  Future<LocationResult> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      final state = await checkAndRequestPermissions();
      if (state != LocationState.precise && state != LocationState.approximate) {
        return LocationResult(state: state, errorMessage: 'Permission issue');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationResult(state: LocationState.ready, position: position);
    } catch (e) {
      return LocationResult(state: LocationState.error, errorMessage: e.toString());
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
