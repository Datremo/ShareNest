import 'package:json_annotation/json_annotation.dart';

part 'listing.g.dart';

@JsonSerializable()
class Listing {
  final String id;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  final String mode; // LEND, GIVE, EXCHANGE
  final String title;
  @JsonKey(name: 'category_id')
  final String categoryId;
  final String? description;
  @JsonKey(name: 'photo_urls')
  final List<String> photoUrls;
  final String status;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  final String? condition;
  final String? brand;
  final int? quantity;
  @JsonKey(name: 'location_name')
  final String? locationName;
  final List<String>? availability;
  final Map<String, dynamic>? preferences;

  Listing({
    required this.id,
    required this.ownerId,
    required this.mode,
    required this.title,
    required this.categoryId,
    this.description,
    this.photoUrls = const [],
    this.status = 'ACTIVE',
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.condition,
    this.brand,
    this.quantity,
    this.locationName,
    this.availability,
    this.preferences,
  });

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
  Map<String, dynamic> toJson() => _$ListingToJson(this);

  List<String> get imageUrls {
    return photoUrls;
  }

  Listing copyWith({
    String? id,
    String? ownerId,
    String? mode,
    String? title,
    String? categoryId,
    String? description,
    List<String>? photoUrls,
    String? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? condition,
    String? brand,
    int? quantity,
    String? locationName,
    List<String>? availability,
    Map<String, dynamic>? preferences,
  }) {
    return Listing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      mode: mode ?? this.mode,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      locationName: locationName ?? this.locationName,
      availability: availability ?? this.availability,
      preferences: preferences ?? this.preferences,
    );
  }
}