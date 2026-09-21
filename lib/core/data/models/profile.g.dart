// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  id: json['id'] as String,
  displayName: json['display_name'] as String,
  photoUrl: json['photo_url'] as String?,
  bio: json['bio'] as String?,
  trustScore: (json['trust_score'] as num?)?.toInt() ?? 100,
  locationName: json['location_name'] as String?,
  itemsShared: (json['items_shared'] as num?)?.toInt() ?? 0,
  successfulExchanges: (json['successful_exchanges'] as num?)?.toInt() ?? 0,
  interests: (json['interests'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  isVerified: json['is_verified'] as bool? ?? false,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
  itemsBorrowed: (json['items_borrowed'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'photo_url': instance.photoUrl,
  'bio': instance.bio,
  'trust_score': instance.trustScore,
  'location_name': instance.locationName,
  'items_shared': instance.itemsShared,
  'successful_exchanges': instance.successfulExchanges,
  'interests': instance.interests,
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_verified': instance.isVerified,
  'rating': instance.rating,
  'review_count': instance.reviewCount,
  'items_borrowed': instance.itemsBorrowed,
};
