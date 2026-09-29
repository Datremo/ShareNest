// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationMember _$ConversationMemberFromJson(Map<String, dynamic> json) =>
    ConversationMember(
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      lastReadAt: json['last_read_at'] == null
          ? null
          : DateTime.parse(json['last_read_at'] as String),
      isArchived: json['is_archived'] as bool? ?? false,
      joinedAt: json['joined_at'] == null
          ? null
          : DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$ConversationMemberToJson(ConversationMember instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'role': instance.role,
      'last_read_at': instance.lastReadAt?.toIso8601String(),
      'is_archived': instance.isArchived,
      'joined_at': instance.joinedAt?.toIso8601String(),
    };
