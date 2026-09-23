// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'urgent_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UrgentRequest _$UrgentRequestFromJson(Map<String, dynamic> json) =>
    UrgentRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      neededBy: json['needed_by'] as String?,
      duration: json['duration'] as String?,
      radiusKm: (json['radius_km'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UrgentRequestToJson(UrgentRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester_id': instance.requesterId,
      'title': instance.title,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'needed_by': instance.neededBy,
      'duration': instance.duration,
      'radius_km': instance.radiusKm,
      'lat': instance.lat,
      'lng': instance.lng,
      'status': instance.status,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
