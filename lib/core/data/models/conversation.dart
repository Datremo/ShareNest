import 'package:json_annotation/json_annotation.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  final String id;
  @JsonKey(name: 'context_type')
  final String contextType;
  @JsonKey(name: 'listing_id')
  final String? listingId;
  @JsonKey(name: 'borrow_request_id')
  final String? borrowRequestId;
  @JsonKey(name: 'item_request_id')
  final String? itemRequestId;
  @JsonKey(name: 'urgent_request_id')
  final String? urgentRequestId;
  @JsonKey(name: 'urgent_offer_id')
  final String? urgentOfferId;
  @JsonKey(name: 'loan_id')
  final String? loanId;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.contextType,
    this.listingId,
    this.borrowRequestId,
    this.itemRequestId,
    this.urgentRequestId,
    this.urgentOfferId,
    this.loanId,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}
