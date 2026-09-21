import 'package:json_annotation/json_annotation.dart';

part 'item_request.g.dart';

@JsonSerializable()
class ItemRequest {
  final String id;
  @JsonKey(name: 'listing_id')
  final String listingId;
  @JsonKey(name: 'requester_id')
  final String requesterId;
  final String status;
  final String? message;
  @JsonKey(name: 'exchange_listing_id')
  final String? exchangeListingId;
  final String? duration;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'handoff_code')
  final String? handoffCode;
  @JsonKey(name: 'return_code')
  final String? returnCode;
  @JsonKey(name: 'pickup_time')
  final DateTime? pickupTime;

  ItemRequest({
    required this.id,
    required this.listingId,
    required this.requesterId,
    this.status = 'PENDING',
    this.message,
    this.exchangeListingId,
    this.duration,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.handoffCode,
    this.returnCode,
    this.pickupTime,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
}
