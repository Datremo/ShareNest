import 'package:json_annotation/json_annotation.dart';

part 'urgent_request.g.dart';

@JsonSerializable()
class UrgentRequest {
  final String id;
  @JsonKey(name: 'requester_id')
  final String requesterId;
  final String title;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'needed_by')
  final String? neededBy;
  final String? duration;
  @JsonKey(name: 'radius_km')
  final double? radiusKm;
  final double? lat;
  final double? lng;
  final String status;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UrgentRequest({
    required this.id,
    required this.requesterId,
    required this.title,
    this.description,
    this.imageUrl,
    this.neededBy,
    this.duration,
    this.radiusKm,
    this.lat,
    this.lng,
    this.status = 'ACTIVE',
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UrgentRequest.fromJson(Map<String, dynamic> json) =>
      _$UrgentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UrgentRequestToJson(this);
}
