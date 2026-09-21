// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemRequest _$ItemRequestFromJson(Map<String, dynamic> json) => ItemRequest(
  id: json['id'] as String,
  listingId: json['listing_id'] as String,
  requesterId: json['requester_id'] as String,
  status: json['status'] as String? ?? 'PENDING',
  message: json['message'] as String?,
  exchangeListingId: json['exchange_listing_id'] as String?,
  duration: json['duration'] as String?,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  handoffCode: json['handoff_code'] as String?,
  returnCode: json['return_code'] as String?,
  pickupTime: json['pickup_time'] == null
      ? null
      : DateTime.parse(json['pickup_time'] as String),
);

Map<String, dynamic> _$ItemRequestToJson(ItemRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listing_id': instance.listingId,
      'requester_id': instance.requesterId,
      'status': instance.status,
      'message': instance.message,
      'exchange_listing_id': instance.exchangeListingId,
      'duration': instance.duration,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'handoff_code': instance.handoffCode,
      'return_code': instance.returnCode,
      'pickup_time': instance.pickupTime?.toIso8601String(),
    };
