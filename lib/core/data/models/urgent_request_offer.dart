import 'package:json_annotation/json_annotation.dart';

part 'urgent_request_offer.g.dart';

@JsonSerializable()
class UrgentRequestOffer {
  final String id;
  @JsonKey(name: 'urgent_request_id')
  final String urgentRequestId;
  @JsonKey(name: 'helper_id')
  final String helperId;
  @JsonKey(name: 'available_for_duration')
  final String? availableForDuration;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  // New fields
  @JsonKey(name: 'offer_type')
  final String? offerType;
  @JsonKey(name: 'item_condition')
  final String? itemCondition;
  @JsonKey(name: 'extra_details')
  final String? extraDetails;
  final List<String>? photos;
  @JsonKey(name: 'handover_location_type')
  final String? handoverLocationType;
  @JsonKey(name: 'handover_lat')
  final double? handoverLat;
  @JsonKey(name: 'handover_lng')
  final double? handoverLng;
  @JsonKey(name: 'availability_date')
  final String? availabilityDate;
  @JsonKey(name: 'handover_method')
  final String? handoverMethod;
  @JsonKey(name: 'availability_window_start')
  final String? availabilityWindowStart;
  @JsonKey(name: 'availability_window_end')
  final String? availabilityWindowEnd;
  @JsonKey(name: 'additional_note')
  final String? additionalNote;

  UrgentRequestOffer({
    required this.id,
    required this.urgentRequestId,
    required this.helperId,
    this.availableForDuration,
    this.status = 'PENDING',
    this.createdAt,
    this.offerType,
    this.itemCondition,
    this.extraDetails,
    this.photos,
    this.handoverLocationType,
    this.handoverLat,
    this.handoverLng,
    this.availabilityDate,
    this.handoverMethod,
    this.availabilityWindowStart,
    this.availabilityWindowEnd,
    this.additionalNote,
  });

  factory UrgentRequestOffer.fromJson(Map<String, dynamic> json) =>
      _$UrgentRequestOfferFromJson(json);
  Map<String, dynamic> toJson() => _$UrgentRequestOfferToJson(this);
}
