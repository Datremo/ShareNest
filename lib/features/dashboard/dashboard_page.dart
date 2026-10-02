import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'dashboard_data.dart';
import '../../core/motion/sharenest_motion.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardPeriod _selectedPeriod = DashboardPeriod.d30;
  RealtimeChannel? _dashboardChannel;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isLedgerView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _setupRealtime();
  }

  void _setupRealtime() {
    _dashboardChannel = Supabase.instance.client.channel('public:dashboard_changes');
    _dashboardChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'item_requests',
        callback: (payload) {
          if (mounted) ref.invalidate(dashboardDataProvider);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'urgent_requests',
        callback: (payload) {
          if (mounted) ref.invalidate(dashboardDataProvider);
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    _dashboardChannel?.unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dashboardDataProvider(_selectedPeriod));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Fallback
      body: Stack(
        children: [
          // Parallax Background
          Positioned(
            top: -(_scrollOffset * 0.05).clamp(0.0, 50.0),
            left: 0,
            right: 0,
            bottom: -50 + (_scrollOffset * 0.05).clamp(0.0, 50.0),
            child: Image.asset(
              'assets/images/dashboard_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Glowing Ambient Orbs for Liquid Glass
          Positioned(
            top: -100 + (_scrollOffset * 0.2),
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 250 - (_scrollOffset * 0.1),
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 50 + (_scrollOffset * 0.15),
            right: 50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Readability Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildViewSwitcher()),
                
                dataAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                  ),
                  error: (err, stack) => const SliverFillRemaining(
                    child: Center(child: Text("Couldn't load this insight.\nTry again.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  ),
                  data: (data) => _isLedgerView 
                      ? SliverToBoxAdapter(child: _TransactionsReceipts(history: data.history))
                      : SliverToBoxAdapter(
                          child: AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 375),
                                childAnimationBuilder: (widget) => SlideAnimation(
                                  verticalOffset: 20.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                                children: [
                                  _DateFilterBar(selectedPeriod: _selectedPeriod, onPeriodChanged: (p) => setState(() => _selectedPeriod = p)),
                                  _CurrentSnapshot(snapshot: data.snapshot),
                                  _NeedsAttention(items: data.needsAttention),
                                  _YourActivity(activity: data.activity, status: data.status, analytics: data.requestAnalytics),
                                  _ActivityMix(lending: data.lending, borrowing: data.borrowing, giving: data.giving, received: data.received),
                                  _LendingOverview(lending: data.lending),
                                  _BorrowingOverview(borrowing: data.borrowing),
                                  _GivingOverview(giving: data.giving),
                                  _ReceivedOverview(received: data.received),
                                  _NeedItNow(urgent: data.urgent),
                                  _RequestAnalytics(analytics: data.requestAnalytics),
                                  _ReturnsHandovers(rh: data.returnsHandovers),
                                  _PostPerformance(postPerf: data.postPerformance),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
                const SizedBox(width: 8),
                Text('My Dashboard', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: _FrostedCard(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSwitcherTab('Overview', !_isLedgerView),
              _buildSwitcherTab('Ledger & Receipts', _isLedgerView),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcherTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isLedgerView = title != 'Overview'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CORE GLASS UI COMPONENT
// ---------------------------------------------------------
class _FrostedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color baseColor;

  const _FrostedCard({
    required this.child, 
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.baseColor = Colors.white,
  });

  @override
  State<_FrostedCard> createState() => _FrostedCardState();
}

class _FrostedCardState extends State<_FrostedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor == Colors.white 
                    ? Colors.black.withValues(alpha: 0.05) 
                    : widget.baseColor.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.baseColor.withValues(alpha: 0.6),
                      widget.baseColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// DATE FILTER
// ---------------------------------------------------------
class _DateFilterBar extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const _DateFilterBar({required this.selectedPeriod, required this.onPeriodChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: DashboardPeriod.values.map((p) => _buildChip(p.name.replaceAll('d', '').replaceAll('m', 'M').replaceAll('y', 'Y').toUpperCase(), p)).toList(),
      ),
    );
  }

  Widget _buildChip(String label, DashboardPeriod period) {
    final isSelected = period == selectedPeriod;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF475569))),
      ),
    );
  }
}

// ---------------------------------------------------------
// SECTION HEADER
// ---------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          ]
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SNAPSHOT
// ---------------------------------------------------------
class _CurrentSnapshot extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  const _CurrentSnapshot({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Current Snapshot', subtitle: 'Your active items at a glance.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _SnapshotCard(value: '${snapshot['active_lending'] ?? 0}', title: "Items you've lent", icon: Icons.inventory_2_outlined, color: const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: _SnapshotCard(value: '${snapshot['active_borrowing'] ?? 0}', title: "Items you're borrowing", icon: Icons.sync_alt_rounded, color: const Color(0xFF3B82F6))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SnapshotCard(value: '${snapshot['pending_returns'] ?? 0}', title: "Pending returns", icon: Icons.schedule_rounded, color: const Color(0xFFF59E0B))),
                  const SizedBox(width: 12),
                  Expanded(child: _SnapshotCard(value: '${snapshot['giving'] ?? 0}', title: "Giving", icon: Icons.redeem_rounded, color: const Color(0xFF8B5CF6))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String value, title;
  final IconData icon;
  final Color color;

  const _SnapshotCard({required this.value, required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)), maxLines: 2),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// OTHER SECTIONS (Kept structurally identical but wrapped in _FrostedCard)
// ---------------------------------------------------------
class _NeedsAttention extends StatelessWidget {
  final List<dynamic> items;
  const _NeedsAttention({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Needs Your Attention', subtitle: '${items.length} items require action.'),
        ...items.map((item) {
          String type = item['type'] ?? 'OTHER';
          IconData icon = Icons.info_outline;
          Color iconColor = const Color(0xFF3B82F6);
          
          if (type == 'RETURN') { icon = Icons.power_outlined; iconColor = const Color(0xFFF97316); } 
          else if (type == 'HANDOVER') { icon = Icons.arrow_downward_rounded; iconColor = const Color(0xFF10B981); }

          return _FrostedCard(
            baseColor: const Color(0xFFFFF7ED), // Subtle warm tint
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? 'Item', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(item['action'] ?? 'Pending action', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text(item['due_date'] != null ? DateFormat('MMM dd').format(DateTime.parse(item['due_date'])) : 'Soon', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: type == 'RETURN' ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6))),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _YourActivity extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Map<String, dynamic> status;
  final Map<String, dynamic> analytics;
  const _YourActivity({required this.activity, required this.status, required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) return const SizedBox.shrink();
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    activity.forEach((key, value) {
      barGroups.add(BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: (value as num).toDouble(), color: const Color(0xFF10B981), width: 16, borderRadius: BorderRadius.circular(4))],
      ));
      index++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Activity Heatmap', subtitle: 'Transactions over time.'),
        _FrostedCard(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (activity.values.isEmpty ? 10 : activity.values.map((e) => (e as num).toDouble()).reduce((a, b) => a > b ? a : b)) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text(activity.keys.elementAt(val.toInt()), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityMix extends StatelessWidget {
  final Map<String, dynamic> lending, borrowing, giving, received;
  const _ActivityMix({required this.lending, required this.borrowing, required this.giving, required this.received});

  @override
  Widget build(BuildContext context) {
    final double l = (lending['total'] ?? 0).toDouble();
    final double b = (borrowing['total'] ?? 0).toDouble();
    final double g = (giving['total'] ?? 0).toDouble();
    final double r = (received['total'] ?? 0).toDouble();
    final double total = l + b + g + r;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Activity Mix', subtitle: 'What you do most on ShareNest.'),
        _FrostedCard(
          padding: const EdgeInsets.all(24),
          child: total == 0 
            ? Center(child: Text("No activity yet", style: GoogleFonts.inter(color: Colors.grey)))
            : Row(
                children: [
                  SizedBox(
                    height: 120, width: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2, centerSpaceRadius: 30,
                        sections: [
                          if (l > 0) PieChartSectionData(color: const Color(0xFF10B981), value: l, title: '${l.toInt()}', radius: 25, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (b > 0) PieChartSectionData(color: const Color(0xFF3B82F6), value: b, title: '${b.toInt()}', radius: 25, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (g > 0) PieChartSectionData(color: const Color(0xFFF59E0B), value: g, title: '${g.toInt()}', radius: 25, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (r > 0) PieChartSectionData(color: const Color(0xFF8B5CF6), value: r, title: '${r.toInt()}', radius: 25, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _Legend('Lending', const Color(0xFF10B981), l.toInt()),
                        _Legend('Borrowing', const Color(0xFF3B82F6), b.toInt()),
                        _Legend('Giving', const Color(0xFFF59E0B), g.toInt()),
                        _Legend('Receiving', const Color(0xFF8B5CF6), r.toInt()),
                      ],
                    ),
                  )
                ],
              ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String title;
  final Color color;
  final int value;
  const _Legend(this.title, this.color, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
          Text('$value', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

// Stats Overviews
class _LendingOverview extends StatelessWidget {
  final Map<String, dynamic> lending;
  const _LendingOverview({required this.lending});

  @override
  Widget build(BuildContext context) => _BaseOverview('Lending Overview', Icons.handshake, const Color(0xFF10B981), lending, const Color(0xFFF0FDF4));
}

class _BorrowingOverview extends StatelessWidget {
  final Map<String, dynamic> borrowing;
  const _BorrowingOverview({required this.borrowing});

  @override
  Widget build(BuildContext context) => _BaseOverview('Borrowing Overview', Icons.sync_alt, const Color(0xFF3B82F6), borrowing, const Color(0xFFEFF6FF));
}

class _GivingOverview extends StatelessWidget {
  final Map<String, dynamic> giving;
  const _GivingOverview({required this.giving});

  @override
  Widget build(BuildContext context) => _BaseOverview('Giving Overview', Icons.redeem, const Color(0xFFF59E0B), giving, const Color(0xFFFFFBEB));
}

class _ReceivedOverview extends StatelessWidget {
  final Map<String, dynamic> received;
  const _ReceivedOverview({required this.received});

  @override
  Widget build(BuildContext context) => _BaseOverview('Receiving Overview', Icons.group, const Color(0xFF8B5CF6), received, const Color(0xFFF5F3FF));
}

class _BaseOverview extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Map<String, dynamic> data;

  const _BaseOverview(this.title, this.icon, this.color, this.data, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        _FrostedCard(
          baseColor: bgColor,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
                  const SizedBox(width: 16),
                  Text('${data['total'] ?? 0}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(width: 8),
                  Text('Total', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white)),
              Wrap(
                spacing: 16, runSpacing: 16,
                children: data.entries.where((e) => e.key != 'total').map((e) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 90) / 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.replaceAll('_', ' ').capitalize(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                        Text('${e.value}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _NeedItNow extends StatelessWidget {
  final Map<String, dynamic> urgent;
  const _NeedItNow({required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Need It Now Analytics', subtitle: 'Your urgent requests.'),
        _FrostedCard(
          baseColor: const Color(0xFFFEF2F2),
          child: Column(
            children: [
              _StatRow('Total Urgent Requests', urgent['total'] ?? 0, const Color(0xFFEF4444)),
              const Divider(color: Colors.white),
              _StatRow('Open', urgent['open'] ?? 0, const Color(0xFFF97316)),
              _StatRow('Accepted', urgent['accepted'] ?? 0, const Color(0xFF3B82F6)),
              _StatRow('Completed', urgent['completed'] ?? 0, const Color(0xFF10B981)),
            ],
          )
        )
      ],
    );
  }
}

class _RequestAnalytics extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _RequestAnalytics({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Request Analytics', subtitle: 'Overall request outcomes.'),
        _FrostedCard(
          child: Column(
            children: [
              _StatRow('Total Requests', analytics['total'] ?? 0, const Color(0xFF64748B)),
              const Divider(color: Color(0xFFF1F5F9)),
              _StatRow('Accepted / Active', analytics['accepted'] ?? 0, const Color(0xFF10B981)),
              _StatRow('Pending', analytics['pending'] ?? 0, const Color(0xFFF59E0B)),
              _StatRow('Declined', analytics['declined'] ?? 0, const Color(0xFFEF4444)),
              _StatRow('Cancelled', analytics['cancelled'] ?? 0, const Color(0xFF94A3B8)),
            ],
          )
        )
      ],
    );
  }
}

class _ReturnsHandovers extends StatelessWidget {
  final Map<String, dynamic> rh;
  const _ReturnsHandovers({required this.rh});

  @override
  Widget build(BuildContext context) {
    final double rawAvg = (rh['avg_duration_days'] ?? 0).toDouble();
    final bool isInvalid = rawAvg < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Returns & Duration', subtitle: 'Average lending duration and return statuses.'),
        _FrostedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Returns', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        _MicroStat('On time', rh['on_time'] ?? 0, const Color(0xFF10B981)),
                        _MicroStat('Late', rh['late'] ?? 0, const Color(0xFFF59E0B)),
                        _MicroStat('Overdue', rh['overdue'] ?? 0, const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Handovers', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        _MicroStat('Completed', rh['completed_handovers'] ?? 0, const Color(0xFF10B981)),
                        _MicroStat('Wait (owner)', rh['waiting_owner'] ?? 0, const Color(0xFFF59E0B)),
                        _MicroStat('Wait (rx)', rh['waiting_receiver'] ?? 0, const Color(0xFF3B82F6)),
                      ],
                    ),
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
              Text('Average lending duration', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              
              if (isInvalid)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Invalid data dates (negative duration). Complete more transactions.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB91C1C)))),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), shape: BoxShape.circle), child: const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Text('${rawAvg.toStringAsFixed(1)} days', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  ],
                ),
                
              const SizedBox(height: 16),
              Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Text('Based on fully completed transactions.', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
            ]
          )
        )
      ],
    );
  }
}

class _PostPerformance extends StatelessWidget {
  final Map<String, dynamic> postPerf;
  const _PostPerformance({required this.postPerf});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Post Performance', subtitle: 'How your shared posts are performing.'),
        _FrostedCard(
          baseColor: const Color(0xFFF0FDF4),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981), size: 28)),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${postPerf['posts_created'] ?? 0}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), 
                    Text('Total Posts', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)))
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _MicroStat('Lend', postPerf['lend'] ?? 0, const Color(0xFF10B981)), 
                    const SizedBox(height: 4),
                    _MicroStat('Give', postPerf['give'] ?? 0, const Color(0xFFF59E0B)), 
                    const SizedBox(height: 4),
                    _MicroStat('Urgent', postPerf['urgent'] ?? 0, const Color(0xFFEF4444))
                  ])
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white)),
              Column(
                children: [
                  _StatRow('Requests received', postPerf['requests_received'] ?? 0, const Color(0xFF10B981)),
                  _StatRow('Accepted', postPerf['accepted'] ?? 0, const Color(0xFF3B82F6)),
                  _StatRow('Completed', postPerf['completed'] ?? 0, const Color(0xFF10B981)),
                  _StatRow('Cancelled', postPerf['cancelled'] ?? 0, const Color(0xFFEF4444)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// TRANSACTIONS & RECEIPTS (LEDGER)
// ---------------------------------------------------------
class _TransactionsReceipts extends StatefulWidget {
  final List<dynamic> history;
  const _TransactionsReceipts({required this.history});

  @override
  State<_TransactionsReceipts> createState() => _TransactionsReceiptsState();
}

class _TransactionsReceiptsState extends State<_TransactionsReceipts> {
  String _categoryFilter = 'All Activity';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredHistory = widget.history.where((item) {
      bool categoryMatch = true;
      if (_categoryFilter != 'All Activity') {
        if (_categoryFilter == 'Lend') categoryMatch = item['category'] == 'LEND';
        if (_categoryFilter == 'Borrow') categoryMatch = item['category'] == 'BORROW';
        if (_categoryFilter == 'Give') categoryMatch = item['category'] == 'GIVE';
        if (_categoryFilter == 'Receive') categoryMatch = item['category'] == 'RECEIVE';
      }
      bool statusMatch = true;
      if (_statusFilter != 'All') {
        if (_statusFilter == 'Pending') statusMatch = item['status'] == 'PENDING';
        if (_statusFilter == 'Completed') statusMatch = item['status'] == 'COMPLETED';
      }
      return categoryMatch && statusMatch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FrostedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('Ledger Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModernFilter('All Activity', _categoryFilter == 'All Activity', () => setState(() => _categoryFilter = 'All Activity')),
                    _buildModernFilter('Lend', _categoryFilter == 'Lend', () => setState(() => _categoryFilter = 'Lend')),
                    _buildModernFilter('Borrow', _categoryFilter == 'Borrow', () => setState(() => _categoryFilter = 'Borrow')),
                    _buildModernFilter('Give', _categoryFilter == 'Give', () => setState(() => _categoryFilter = 'Give')),
                    _buildModernFilter('Receive', _categoryFilter == 'Receive', () => setState(() => _categoryFilter = 'Receive')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModernFilter('All Status', _statusFilter == 'All', () => setState(() => _statusFilter = 'All')),
                    _buildModernFilter('Pending', _statusFilter == 'Pending', () => setState(() => _statusFilter = 'Pending')),
                    _buildModernFilter('Completed', _statusFilter == 'Completed', () => setState(() => _statusFilter = 'Completed')),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (filteredHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40), 
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text("No transactions found.", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                ],
              )
            )
          )
        else
          AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: _AdvancedReceiptCard(item: filteredHistory[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildModernFilter(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }
}

class _AdvancedReceiptCard extends StatelessWidget {
  final dynamic item;
  const _AdvancedReceiptCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String status = item['status'] ?? '';
    String category = item['category'] ?? '';
    String title = item['title'] ?? 'Item';
    DateTime date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();

    Color color = Colors.grey;
    IconData icon = Icons.check_circle;
    
    if (category == 'LEND') { color = const Color(0xFF10B981); icon = Icons.outbox_rounded; }
    else if (category == 'BORROW') { color = const Color(0xFF3B82F6); icon = Icons.move_to_inbox_rounded; }
    else if (category == 'GIVE') { color = const Color(0xFFF59E0B); icon = Icons.redeem_rounded; }
    else if (category == 'RECEIVE') { color = const Color(0xFF8B5CF6); icon = Icons.volunteer_activism_rounded; }

    return _FrostedCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () {
          final isOwner = item['is_owner'] ?? false;
          final id = item['id'];
          if (id != null) {
            if (isOwner) {
              context.push('/owner-request-detail/$id');
            } else {
              context.push('/requester-request-detail/$id');
            }
          }
        },
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$category • ${DateFormat('MMM d, yyyy').format(date)}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _getStatusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String s) {
    if (s == 'COMPLETED') return const Color(0xFF10B981);
    if (s == 'PENDING') return const Color(0xFFF59E0B);
    if (s == 'CANCELLED' || s == 'DECLINED' || s == 'EXPIRED') return const Color(0xFFEF4444);
    return const Color(0xFF3B82F6);
  }
}

// Helper Widgets
class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
            ],
          ),
          Text('$value', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MicroStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        const SizedBox(width: 8),
        Text('$value', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
