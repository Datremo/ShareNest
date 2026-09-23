// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'urgent_request_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UrgentRequestOffer _$UrgentRequestOfferFromJson(Map<String, dynamic> json) =>
    UrgentRequestOffer(
      id: json['id'] as String,
      urgentRequestId: json['urgent_request_id'] as String,
      helperId: json['helper_id'] as String,
      availableForDuration: json['available_for_duration'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UrgentRequestOfferToJson(UrgentRequestOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'urgent_request_id': instance.urgentRequestId,
      'helper_id': instance.helperId,
      'available_for_duration': instance.availableForDuration,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };
