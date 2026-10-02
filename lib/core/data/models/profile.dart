import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final String id;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? username;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final String? bio;
  @JsonKey(name: 'trust_score')
  final int trustScore;
  @JsonKey(name: 'location_name')
  final String? locationName;
  @JsonKey(name: 'items_shared')
  final int itemsShared;
  @JsonKey(name: 'successful_exchanges')
  final int successfulExchanges;
  final List<String>? interests;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  final double rating;
  @JsonKey(name: 'review_count')
  final int reviewCount;
  @JsonKey(name: 'items_borrowed')
  final int itemsBorrowed;

  Profile({
    required this.id,
    this.fullName,
    required this.displayName,
    this.username,
    this.photoUrl,
    this.bio,
    this.trustScore = 100,
    this.locationName,
    this.itemsShared = 0,
    this.successfulExchanges = 0,
    this.interests,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.itemsBorrowed = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
      
  Map<String, dynamic> toJson() {
    final json = _$ProfileToJson(this);
    json.remove('updated_at');
    json.remove('created_at');
    return json;
  }
  
  // Dynamic trust score calculated based on user activity
  int get calculatedTrustScore {
    int score = 50; // Base score
    score += (isVerified ? 20 : 0);
    score += (itemsShared * 5);
    score += (successfulExchanges * 10);
    score += (rating * reviewCount).toInt();
    
    // Cap at 100
    if (score > 100) return 100;
    return score;
  }
}
