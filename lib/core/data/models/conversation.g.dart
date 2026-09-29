// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as String,
  contextType: json['context_type'] as String,
  listingId: json['listing_id'] as String?,
  borrowRequestId: json['borrow_request_id'] as String?,
  itemRequestId: json['item_request_id'] as String?,
  urgentRequestId: json['urgent_request_id'] as String?,
  urgentOfferId: json['urgent_offer_id'] as String?,
  loanId: json['loan_id'] as String?,
  status: json['status'] as String? ?? 'active',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'context_type': instance.contextType,
      'listing_id': instance.listingId,
      'borrow_request_id': instance.borrowRequestId,
      'item_request_id': instance.itemRequestId,
      'urgent_request_id': instance.urgentRequestId,
      'urgent_offer_id': instance.urgentOfferId,
      'loan_id': instance.loanId,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
