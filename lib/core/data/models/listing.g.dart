// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Listing _$ListingFromJson(Map<String, dynamic> json) => Listing(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  mode: json['mode'] as String,
  title: json['title'] as String,
  categoryId: json['category_id'] as String,
  description: json['description'] as String?,
  photoUrls:
      (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status: json['status'] as String? ?? 'ACTIVE',
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  condition: json['condition'] as String?,
  brand: json['brand'] as String?,
  quantity: (json['quantity'] as num?)?.toInt(),
  locationName: json['location_name'] as String?,
  availability: (json['availability'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  preferences: json['preferences'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ListingToJson(Listing instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'mode': instance.mode,
  'title': instance.title,
  'category_id': instance.categoryId,
  'description': instance.description,
  'photo_urls': instance.photoUrls,
  'status': instance.status,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'condition': instance.condition,
  'brand': instance.brand,
  'quantity': instance.quantity,
  'location_name': instance.locationName,
  'availability': instance.availability,
  'preferences': instance.preferences,
};
