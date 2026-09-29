import 'package:json_annotation/json_annotation.dart';
import 'profile.dart';

part 'conversation_member.g.dart';

@JsonSerializable()
class ConversationMember {
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String role;
  @JsonKey(name: 'last_read_at')
  final DateTime? lastReadAt;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'joined_at')
  final DateTime? joinedAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Profile? profile;

  ConversationMember({
    required this.conversationId,
    required this.userId,
    required this.role,
    this.lastReadAt,
    this.isArchived = false,
    this.joinedAt,
    this.profile,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) => _$ConversationMemberFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationMemberToJson(this);
}
