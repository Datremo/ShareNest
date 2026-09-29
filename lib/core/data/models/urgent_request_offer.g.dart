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
      offerType: json['offer_type'] as String?,
      itemCondition: json['item_condition'] as String?,
      extraDetails: json['extra_details'] as String?,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      handoverLocationType: json['handover_location_type'] as String?,
      handoverLat: (json['handover_lat'] as num?)?.toDouble(),
      handoverLng: (json['handover_lng'] as num?)?.toDouble(),
      availabilityDate: json['availability_date'] as String?,
      handoverMethod: json['handover_method'] as String?,
      availabilityWindowStart: json['availability_window_start'] as String?,
      availabilityWindowEnd: json['availability_window_end'] as String?,
      additionalNote: json['additional_note'] as String?,
    );

Map<String, dynamic> _$UrgentRequestOfferToJson(UrgentRequestOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'urgent_request_id': instance.urgentRequestId,
      'helper_id': instance.helperId,
      'available_for_duration': instance.availableForDuration,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'offer_type': instance.offerType,
      'item_condition': instance.itemCondition,
      'extra_details': instance.extraDetails,
      'photos': instance.photos,
      'handover_location_type': instance.handoverLocationType,
      'handover_lat': instance.handoverLat,
      'handover_lng': instance.handoverLng,
      'availability_date': instance.availabilityDate,
      'handover_method': instance.handoverMethod,
      'availability_window_start': instance.availabilityWindowStart,
      'availability_window_end': instance.availabilityWindowEnd,
      'additional_note': instance.additionalNote,
    };
