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

  UrgentRequestOffer({
    required this.id,
    required this.urgentRequestId,
    required this.helperId,
    this.availableForDuration,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory UrgentRequestOffer.fromJson(Map<String, dynamic> json) =>
      _$UrgentRequestOfferFromJson(json);
  Map<String, dynamic> toJson() => _$UrgentRequestOfferToJson(this);
}
