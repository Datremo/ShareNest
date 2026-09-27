import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DashboardPeriod { d7, d30, m3, m6, y1, all }

class DashboardData {
  final Map<String, dynamic> snapshot;
  final Map<String, dynamic> lending;
  final Map<String, dynamic> borrowing;
  final Map<String, dynamic> giving;
  final Map<String, dynamic> received;
  final Map<String, dynamic> urgent;
  final Map<String, dynamic> status;
  final Map<String, dynamic> postPerformance;
  final Map<String, dynamic> activity;
  final Map<String, dynamic> requestAnalytics;
  final Map<String, dynamic> returnsHandovers;
  final List<dynamic> history;
  final List<dynamic> needsAttention;

  DashboardData({
    required this.snapshot,
    required this.lending,
    required this.borrowing,
    required this.giving,
    required this.received,
    required this.urgent,
    required this.status,
    required this.postPerformance,
    required this.activity,
    required this.requestAnalytics,
    required this.returnsHandovers,
    required this.history,
    required this.needsAttention,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      snapshot: json['snapshot'] ?? {},
      lending: json['lending'] ?? {},
      borrowing: json['borrowing'] ?? {},
      giving: json['giving'] ?? {},
      received: json['received'] ?? {},
      urgent: json['urgent'] ?? {},
      status: json['status'] ?? {},
      postPerformance: json['post_performance'] ?? {},
      activity: json['activity'] ?? {},
      requestAnalytics: json['request_analytics'] ?? {},
      returnsHandovers: json['returns_handovers'] ?? {},
      history: json['history'] as List<dynamic>? ?? [],
      needsAttention: json['needs_attention'] as List<dynamic>? ?? [],
    );
  }
}

class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  Future<DashboardData> getDashboardData(DashboardPeriod period) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    String? startDateStr;
    final now = DateTime.now();
    switch (period) {
      case DashboardPeriod.d7: startDateStr = now.subtract(const Duration(days: 7)).toIso8601String(); break;
      case DashboardPeriod.d30: startDateStr = now.subtract(const Duration(days: 30)).toIso8601String(); break;
      case DashboardPeriod.m3: startDateStr = DateTime(now.year, now.month - 3, now.day).toIso8601String(); break;
      case DashboardPeriod.m6: startDateStr = DateTime(now.year, now.month - 6, now.day).toIso8601String(); break;
      case DashboardPeriod.y1: startDateStr = DateTime(now.year - 1, now.month, now.day).toIso8601String(); break;
      case DashboardPeriod.all: startDateStr = null; break;
    }

    // Call the PostgreSQL RPC function
    final response = await _client.rpc('get_dashboard_data', params: {
      'p_user_id': userId,
      'p_start_date': startDateStr,
    });

    return DashboardData.fromJson(response as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(Supabase.instance.client));

final dashboardDataProvider = FutureProvider.family<DashboardData, DashboardPeriod>((ref, period) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardData(period);
});
