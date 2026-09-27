import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:geolocator/geolocator.dart' as geo show Position;
import '../location/location_core.dart';
import 'package:google_fonts/google_fonts.dart';

enum MapMode {
  explore,        // Shows Lend/Give posts
  liveRequests,   // Shows urgent requests with radius circle
  locationPicker, // Full-screen drag pin for setting locations
}

class ShareNestMap extends StatefulWidget {
  final MapMode mode;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>)? onMarkerTapped;
  final Function(geo.Position)? onLocationSelected; // Used in picker mode
  final double? searchRadiusMeters;
  final geo.Position? initialCenter;

  const ShareNestMap({
    super.key,
    required this.mode,
    this.items = const [],
    this.onMarkerTapped,
    this.onLocationSelected,
    this.searchRadiusMeters,
    this.initialCenter,
  });

  @override
  State<ShareNestMap> createState() => _ShareNestMapState();
}

class _ShareNestMapState extends State<ShareNestMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  bool _isLocating = false;
  geo.Position? _currentPosition;
  bool _isMapReady = false;
  
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    if (widget.initialCenter != null) {
      _currentPosition = widget.initialCenter;
    } else {
      setState(() => _isLocating = true);
      final service = LocationService();
      final result = await service.getCurrentLocation();
      if (result.state == LocationState.ready) {
        _currentPosition = result.position;
      } else if (widget.items.isNotEmpty) {
        // Fallback to the first item's location if GPS fails (common on desktop web)
        final firstItem = widget.items.firstWhere(
            (item) => item['lat'] != null && item['lng'] != null,
            orElse: () => {});
        if (firstItem.isNotEmpty) {
           _currentPosition = geo.Position(
             latitude: firstItem['lat'] as double,
             longitude: firstItem['lng'] as double,
             timestamp: DateTime.now(),
             accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0
           );
        }
      }
      if (mounted) setState(() => _isLocating = false);
    }
    _moveToCurrentPosition();
  }

  void _moveToCurrentPosition() {
    if (_currentPosition != null && _isMapReady) {
      _animatedMapMove(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Basic fallback since flutter_map doesn't animate by default
    _mapController.move(destLocation, destZoom);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocating && _currentPosition == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    final initialTarget = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(19.0, 73.0);

    // Build Markers
    final List<Marker> markers = [];
    
    // My Location Marker (if we have a current position)
    if (_currentPosition != null && widget.mode != MapMode.locationPicker) {
      markers.add(
        Marker(
          width: 24,
          height: 24,
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
        ),
      );
    }

    // Item Markers
    for (final item in widget.items) {
      if (item['lat'] != null && item['lng'] != null) {
        Color markerColor = Colors.grey;
        
        if (widget.mode == MapMode.liveRequests) {
           if (item['urgency'] == 'now') markerColor = const Color(0xFFFF4B4B); // Red
           else if (item['urgency'] == 'soon') markerColor = const Color(0xFFFF9500); // Orange
           else markerColor = const Color(0xFF34C759); // Green
        } else {
           if (item['type'] == 'give') markerColor = const Color(0xFFFF9500); // Orange
           else if (item['type'] == 'lend') markerColor = const Color(0xFF34C759); // Green
           else markerColor = const Color(0xFF3498DB); // Blue
        }

        markers.add(
          Marker(
            width: 32,
            height: 32,
            point: LatLng(item['lat'] as double, item['lng'] as double),
            child: GestureDetector(
              onTap: () {
                if (widget.onMarkerTapped != null) widget.onMarkerTapped!(item);
                _animatedMapMove(LatLng(item['lat'] as double, item['lng'] as double), 16.0);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: markerColor.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.circle, size: 12, color: Colors.white), // Optional inner dot
              ),
            ),
          ),
        );
      }
    }

    // Build Circles (For Live Radar Radius)
    final List<CircleMarker> circles = [];
    if (widget.mode == MapMode.liveRequests && widget.searchRadiusMeters != null && _currentPosition != null) {
      circles.add(
        CircleMarker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          color: const Color(0x26FF4B4B), // 15% opacity red
          borderColor: const Color(0xFFFF4B4B),
          borderStrokeWidth: 2,
          radius: widget.searchRadiusMeters!, // flutter_map radius is in meters by default if useRadiusInMeter is true
          useRadiusInMeter: true,
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialTarget,
            initialZoom: 14.0,
            onMapReady: () {
              _isMapReady = true;
              if (_currentPosition != null) {
                _moveToCurrentPosition();
              }
            },
            onMapEvent: (MapEvent event) {
              if (event is MapEventMoveEnd && widget.mode == MapMode.locationPicker) {
                final center = event.camera.center;
                if (widget.onLocationSelected != null) {
                  widget.onLocationSelected!(geo.Position(
                    latitude: center.latitude,
                    longitude: center.longitude,
                    timestamp: DateTime.now(),
                    accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
                  ));
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: _isSatellite
                  ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                  : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.sharenest.app',
            ),
            if (circles.isNotEmpty) CircleLayer(circles: circles),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Map Controls (Satellite, Recenter & Zoom)
        Positioned(
          bottom: 96,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In
              GestureDetector(
                onTap: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 12),
              // Zoom Out
              GestureDetector(
                onTap: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.remove, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 12),
              // Satellite Toggle
              GestureDetector(
                onTap: () {
                  setState(() => _isSatellite = !_isSatellite);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Icon(
                    _isSatellite ? Icons.map : Icons.satellite_alt, 
                    color: const Color(0xFF1E293B)
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Recenter Button
              GestureDetector(
                onTap: _loadInitialLocation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        ),

        // Location Picker Overlay Pin
        if (widget.mode == MapMode.locationPicker)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Icon(Icons.location_on, size: 40, color: Color(0xFF10B981)),
            ),
          ),
      ],
    );
  }
}
