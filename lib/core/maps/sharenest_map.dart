import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:geolocator/geolocator.dart' as geo show Position;
import '../location/location_core.dart';
import '../../core/theme/app_colors.dart';

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
  final Function(int)? onItemsInViewChanged;
  final VoidCallback? onMapTapped;
  final double? searchRadiusMeters;
  final geo.Position? initialCenter;
  final String? selectedItemId;

  const ShareNestMap({
    super.key,
    required this.mode,
    this.items = const [],
    this.onMarkerTapped,
    this.onLocationSelected,
    this.onItemsInViewChanged,
    this.onMapTapped,
    this.searchRadiusMeters,
    this.initialCenter,
    this.selectedItemId,
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  @override
  void didUpdateWidget(covariant ShareNestMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCenter != oldWidget.initialCenter && widget.initialCenter != null) {
      _animatedMapMove(LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude), 14.0);
    }
    if (widget.items != oldWidget.items && _isMapReady) {
      _calculateVisibleItems();
    }
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
      } else {
        if (result.state == LocationState.servicesDisabled && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location Disabled'),
              content: const Text('Please enable location services to view maps and nearby items properly.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Geolocator.openLocationSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }

        if (widget.items.isNotEmpty) {
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
    if (!_isMapReady) return;
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final animationController = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    final animation = CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic);

    animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
      } else if (status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  void _calculateVisibleItems() {
    if (!_isMapReady || widget.onItemsInViewChanged == null) return;
    
    int count = 0;
    try {
      final bounds = _mapController.camera.visibleBounds;
      for (final item in widget.items) {
        if (item['lat'] != null && item['lng'] != null) {
          final pt = LatLng(item['lat'] as double, item['lng'] as double);
          if (bounds.contains(pt)) count++;
        }
      }
    } catch (e) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onItemsInViewChanged != null) {
        widget.onItemsInViewChanged!(count);
      }
    });
  }

  IconData _getCategoryIcon(String? categoryId) {
    switch (categoryId) {
      case 'electronics': return Icons.laptop_mac;
      case 'cleaning_home': return Icons.chair;
      case 'books_games': return Icons.menu_book;
      case 'sports_fitness': return Icons.sports_basketball;
      case 'diy_power_tools': return Icons.handyman;
      case 'camping_outdoors': return Icons.park;
      case 'kitchen_party': return Icons.cake;
      default: return Icons.inventory_2_outlined;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocating && _currentPosition == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final initialTarget = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(19.0, 73.0);

    final List<Marker> mapMarkers = [];
    Marker? selectedMarker;
    
    if (_currentPosition != null && widget.mode != MapMode.locationPicker) {
      mapMarkers.add(
        Marker(
          width: 30, height: 30,
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOutSine,
            builder: (context, val, child) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Item Markers
    for (final item in widget.items) {
      if (item['lat'] != null && item['lng'] != null) {
        Color markerColor = Colors.grey;
        if (widget.mode == MapMode.liveRequests) {
           if (item['urgency'] == 'now') markerColor = const Color(0xFFFF4B4B); 
           else if (item['urgency'] == 'soon') markerColor = const Color(0xFFFF9500);
           else markerColor = const Color(0xFF34C759);
        } else {
           if (item['type'] == 'give') markerColor = AppColors.give;
           else if (item['type'] == 'lend') markerColor = AppColors.primary;
           else markerColor = Colors.blue;
        }

        final isSelected = widget.selectedItemId != null && widget.selectedItemId == item['id'];
        String? categoryId = item['categoryId'];
        if (categoryId == null && widget.mode != MapMode.liveRequests) {
          try {
            categoryId = item['wrapper']?.categoryId;
          } catch (_) {}
        }
        final catIcon = _getCategoryIcon(categoryId);

        final marker = Marker(
          width: isSelected ? 60 : 40,
          height: isSelected ? 60 : 40,
          point: LatLng(item['lat'] as double, item['lng'] as double),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.onMarkerTapped != null) widget.onMarkerTapped!(item);
              _animatedMapMove(LatLng((item['lat'] as double) - 0.005, item['lng'] as double), 15.0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: isSelected ? 0.6 : 0.4), 
                    blurRadius: isSelected ? 16 : 8, 
                    spreadRadius: isSelected ? 4 : 0,
                    offset: const Offset(0, 4)
                  ),
                ],
              ),
              child: Icon(catIcon, size: isSelected ? 24 : 16, color: Colors.white),
            ),
          ),
        );
        
        if (isSelected) {
          selectedMarker = marker; // Render selected marker on top
        } else {
          mapMarkers.add(marker);
        }
      }
    }
    
    if (selectedMarker != null) {
      mapMarkers.add(selectedMarker);
    }

    final List<CircleMarker> circles = [];
    if (widget.mode == MapMode.liveRequests && widget.searchRadiusMeters != null && _currentPosition != null) {
      circles.add(
        CircleMarker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          color: const Color(0x26FF4B4B),
          borderColor: const Color(0xFFFF4B4B),
          borderStrokeWidth: 2,
          radius: widget.searchRadiusMeters!,
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
              _calculateVisibleItems();
            },
            onTap: (_, __) {
              if (widget.onMapTapped != null) widget.onMapTapped!();
            },
            onMapEvent: (MapEvent event) {
              if (event is MapEventMoveEnd && widget.mode == MapMode.locationPicker) {
                final center = event.camera.center;
                if (widget.onLocationSelected != null) {
                  widget.onLocationSelected!(geo.Position(
                    latitude: center.latitude, longitude: center.longitude,
                    timestamp: DateTime.now(),
                    accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
                  ));
                }
              }
              
              if (event is MapEventMove) {
                if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                  _calculateVisibleItems();
                });
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
            if (widget.mode == MapMode.explore || widget.mode == MapMode.liveRequests)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: mapMarkers,
                  builder: (context, markers) {
                    final isLive = widget.mode == MapMode.liveRequests;
                    return Container(
                      decoration: BoxDecoration(
                        color: (isLive ? const Color(0xFFFF4B4B) : AppColors.primary).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              MarkerLayer(markers: mapMarkers),
          ],
        ),
        
        // Map Dim Scrim
        if (widget.selectedItemId != null)
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        
        // Floating Controls (Right Side)
        Positioned(
          bottom: 120, // Avoid bottom nav & preview cards
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassControl(Icons.layers_rounded, () {
                setState(() => _isSatellite = !_isSatellite);
              }),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final zoom = _mapController.camera.zoom;
                            _animatedMapMove(_mapController.camera.center, zoom + 1);
                          },
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.add, color: AppColors.primaryDark, size: 20)),
                        ),
                        Container(height: 1, width: 24, color: Colors.grey.withValues(alpha: 0.3)),
                        GestureDetector(
                          onTap: () {
                            final zoom = _mapController.camera.zoom;
                            _animatedMapMove(_mapController.camera.center, zoom - 1);
                          },
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.remove, color: AppColors.primaryDark, size: 20)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildGlassControl(Icons.near_me_rounded, _loadInitialLocation),
            ],
          ),
        ),

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

  Widget _buildGlassControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
        ),
      ),
    );
  }
}
