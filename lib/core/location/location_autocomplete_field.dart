import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import 'location_core.dart';
import 'location_picker_page.dart';

class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final String? placeId;

  LocationSuggestion({required this.displayName, required this.lat, required this.lon, this.placeId});

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
    );
  }
}

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationSuggestion)? onSelected;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.onSelected,
    this.validator,
    this.decoration,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  bool _isLoading = false;
  // Use the Maps Key because it has the Maps JavaScript API enabled, which this SDK relies on.
  static const _googlePlacesKey = 'AIzaSyCVf0EriwuMaiXjUgdpw1gg6YXAuWTFrUg';
  static const _googleGeocodingKey = 'AIzaSyDvxih6DWk1ozvhAEWf_Rrldi0bi2fOnc0';

  @override
  void initState() {
    super.initState();
  }

  Future<List<LocationSuggestion>> _getSuggestions(String query) async {
    if (query.length < 3) return [];
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googlePlacesKey&components=country:in';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null) {
          return (data['predictions'] as List).map((p) {
            return LocationSuggestion(
              displayName: p['description'],
              lat: 0,
              lon: 0,
              placeId: p['place_id'],
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }

  Future<void> _reverseGeocodeAndSelect(double lat, double lon) async {
    setState(() => _isLoading = true);
    try {
      // We still need the HTTP call for reverse geocoding because Places SDK doesn't natively do lat/lng -> address easily.
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$_googleGeocodingKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final displayName = data['results'][0]['formatted_address'];
          final suggestion = LocationSuggestion(
            displayName: displayName,
            lat: lat,
            lon: lon,
          );
          
          widget.controller.text = displayName;
          if (widget.onSelected != null) {
            widget.onSelected!(suggestion);
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final service = LocationService();
      final result = await service.getCurrentLocation();
      if (result.state == LocationState.ready && result.position != null) {
        await _reverseGeocodeAndSelect(result.position!.latitude, result.position!.longitude);
      } else {
        throw Exception('Location permission denied or service disabled.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final position = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerPage()),
    );
    
    if (position != null) {
      await _reverseGeocodeAndSelect(position.latitude, position.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeAheadField<LocationSuggestion>(
          controller: widget.controller,
          builder: (context, controller, focusNode) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              validator: widget.validator,
              decoration: widget.decoration ?? const InputDecoration(
                hintText: 'Search location...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            );
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: Text(suggestion.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            );
          },
          onSelected: (suggestion) async {
            LocationSuggestion finalSuggestion = suggestion;
            if (suggestion.placeId != null && suggestion.lat == 0) {
              setState(() => _isLoading = true);
              try {
                String url = 'https://maps.googleapis.com/maps/api/geocode/json?place_id=${suggestion.placeId}&key=$_googleGeocodingKey';
                final response = await http.get(Uri.parse(url));
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['results'] != null && (data['results'] as List).isNotEmpty) {
                    final location = data['results'][0]['geometry']['location'];
                    finalSuggestion = LocationSuggestion(
                      displayName: suggestion.displayName,
                      lat: location['lat'],
                      lon: location['lng'],
                      placeId: suggestion.placeId,
                    );
                  }
                }
              } catch(e) {
                 debugPrint('Geocode fetch error: $e');
              } finally {
                 if(mounted) setState(() => _isLoading = false);
              }
            }
            
            widget.controller.text = finalSuggestion.displayName;
            if (widget.onSelected != null) {
              widget.onSelected!(finalSuggestion);
            }
          },
          suggestionsCallback: (pattern) async {
            return await _getSuggestions(pattern);
          },
          debounceDuration: const Duration(milliseconds: 600),
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No locations found', style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.my_location, size: 16, color: AppColors.primaryDark),
                label: const Text('Current Location', style: TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: _useCurrentLocation,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.map, size: 16, color: AppColors.primaryDark),
                label: const Text('Choose on Map', style: TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: _chooseOnMap,
              ),
            ],
          ),
      ],
    );
  }
}

