import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'dashboard_data.dart';
import '../../core/motion/sharenest_motion.dart';
import '../../core/presentation/widgets/glassmorphism.dart' as glass;
import '../../core/presentation/widgets/liquid_glass_widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  DashboardPeriod _selectedPeriod = DashboardPeriod.d30;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: ShareNestMotion.slow);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dashboardDataProvider(_selectedPeriod));

    return DefaultTabController(
      length: 2,
      child: AnimatedLiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('My Dashboard', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)), onPressed: () {}),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  labelColor: const Color(0xFF10B981),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Ledger & Receipts'),
                  ],
                ),
              ),
            ),
          ),
          body: dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            error: (err, stack) => Center(child: Text('Error loading dashboard: $err')),
            data: (data) => TabBarView(
              children: [
                // Tab 1: Overview
                RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: () async {
                    ref.invalidate(dashboardDataProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnimated(0, _DashboardHeader(selectedPeriod: _selectedPeriod, onPeriodChanged: (p) => setState(() => _selectedPeriod = p))),
                        _buildAnimated(1, _CurrentSnapshot(snapshot: data.snapshot)),
                        _buildAnimated(2, _NeedsAttention(items: data.needsAttention)),
                        _buildAnimated(3, _YourActivity(activity: data.activity, status: data.status, analytics: data.requestAnalytics)),
                        _buildAnimated(4, _ActivityMix(lending: data.lending, borrowing: data.borrowing, giving: data.giving, received: data.received)),
                        _buildAnimated(5, _LendingOverview(lending: data.lending)),
                        _buildAnimated(6, _BorrowingOverview(borrowing: data.borrowing)),
                        _buildAnimated(7, _GivingOverview(giving: data.giving)),
                        _buildAnimated(8, _ReceivedOverview(received: data.received)),
                        _buildAnimated(9, _NeedItNow(urgent: data.urgent)),
                        _buildAnimated(10, _RequestAnalytics(analytics: data.requestAnalytics)),
                        _buildAnimated(11, _ReturnsHandovers(rh: data.returnsHandovers)),
                        _buildAnimated(12, _PostPerformance(postPerf: data.postPerformance)),
                      ],
                    ),
                  ),
                ),
                // Tab 2: Ledger
                RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: () async {
                    ref.invalidate(dashboardDataProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(top: 16, bottom: 120),
                    child: _TransactionsReceipts(history: data.history),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimated(int index, Widget child) {
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval((index * 0.05).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutBack),
    );
    return ShareNestMotion.fadeSlide(child: child, animation: animation);
  }
}

// ---------------------------------------------------------
// 1. HEADER & DATES
// ---------------------------------------------------------
class _DashboardHeader extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const _DashboardHeader({required this.selectedPeriod, required this.onPeriodChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your ShareNest activity, transactions & history', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...DashboardPeriod.values.map((p) => _buildChip(p.name.replaceAll('d', '').replaceAll('m', 'M').replaceAll('y', 'Y').toUpperCase(), p)),
              const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B), size: 20),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label, DashboardPeriod period) {
    final isSelected = period == selectedPeriod;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: ShareNestMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. CURRENT SNAPSHOT
// ---------------------------------------------------------
class _CurrentSnapshot extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  const _CurrentSnapshot({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(title: 'Current Snapshot', onViewAll: () {}),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _SnapshotCard(value: '${snapshot['active_lending'] ?? 0}', title: "Items you've lent", subtitle: "With neighbours", icon: Icons.inventory_2_outlined, color: const Color(0xFF10B981), bgColor: const Color(0xFFECFDF5))),
                  const SizedBox(width: 12),
                  Expanded(child: _SnapshotCard(value: '${snapshot['active_borrowing'] ?? 0}', title: "Items you're borrowing", subtitle: "With you", icon: Icons.sync_alt_rounded, color: const Color(0xFF3B82F6), bgColor: const Color(0xFFEFF6FF))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SnapshotCard(value: '${snapshot['pending_returns'] ?? 0}', title: "Pending returns", subtitle: "Need attention", icon: Icons.schedule_rounded, color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFFBEB))),
                  const SizedBox(width: 12),
                  Expanded(child: _SnapshotCard(value: '${snapshot['giving'] ?? 0}', title: "Giving", subtitle: "In progress", icon: Icons.redeem_rounded, color: const Color(0xFF8B5CF6), bgColor: const Color(0xFFF5F3FF))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SnapshotCard(value: '${snapshot['receiving'] ?? 0}', title: "Receiving", subtitle: "In progress", icon: Icons.group_outlined, color: const Color(0xFFEC4899), bgColor: const Color(0xFFFDF2F8))),
                  const SizedBox(width: 12),
                  Expanded(child: _SnapshotCard(value: '${snapshot['open_urgent'] ?? 0}', title: "Open urgent requests", subtitle: "Need It Now", icon: Icons.bolt_rounded, color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEF2F2))),
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
  final String value, title, subtitle;
  final IconData icon;
  final Color color, bgColor;

  const _SnapshotCard({required this.value, required this.title, required this.subtitle, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return glass.GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. NEEDS YOUR ATTENTION (Static Mock for layout matching)
// ---------------------------------------------------------
class _NeedsAttention extends StatelessWidget {
  final List<dynamic> items;
  const _NeedsAttention({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: glass.GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 32),
              ),
              const SizedBox(height: 16),
              Text("You're all caught up!", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text("No pending returns or urgent actions needed right now.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Needs Your Attention', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)), child: Text('${items.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
              Text('View all >', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
        ...items.map((item) {
          String type = item['type'] ?? 'OTHER';
          IconData icon = Icons.info_outline;
          Color iconColor = const Color(0xFF3B82F6);
          Color iconBg = const Color(0xFFEFF6FF);
          
          if (type == 'RETURN') {
             icon = Icons.power_outlined; iconColor = const Color(0xFFF97316); iconBg = const Color(0xFFFFF7ED);
          } else if (type == 'HANDOVER') {
             icon = Icons.arrow_downward_rounded; iconColor = const Color(0xFF10B981); iconBg = const Color(0xFFECFDF5);
          }

          return _AttentionItem(
            icon: icon, 
            iconColor: iconColor, 
            iconBg: iconBg, 
            title: item['title'] ?? 'Item', 
            subtitle: item['action'] ?? 'Pending action', 
            actionText: item['due_date'] != null ? 'Due ${DateFormat('MMM dd').format(DateTime.parse(item['due_date']))}' : 'Action required', 
            actionColor: type == 'RETURN' ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6)
          );
        }).toList(),
      ],
    );
  }
}

class _AttentionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg, actionColor;
  final String title, subtitle, actionText;

  const _AttentionItem({required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.subtitle, required this.actionText, required this.actionColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: glass.GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(actionText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: actionColor)),
              ],
            ),
          ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. YOUR ACTIVITY (Over Time Stacked Bar + Status Donut + Journey)
// ---------------------------------------------------------
class _YourActivity extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Map<String, dynamic> status;
  final Map<String, dynamic> analytics;

  const _YourActivity({required this.activity, required this.status, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(title: 'Your Activity', trailingText: 'Last 30 days v'),
        
        // Activity Over Time (Mocked UI stacked bar to match design)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity over time', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: activity.isEmpty 
                  ? Center(child: Text("No activity data for this period", style: GoogleFonts.inter(color: Colors.grey)))
                  : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxActivity(activity),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                        final keys = activity.keys.toList();
                        if (val.toInt() >= 0 && val.toInt() < keys.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(keys[val.toInt()], style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))));
                        }
                        return const SizedBox.shrink();
                      })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: (_getMaxActivity(activity) / 4).ceilToDouble().clamp(1.0, double.infinity), getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))))),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (_getMaxActivity(activity) / 4).ceilToDouble().clamp(1.0, double.infinity), getDrawingHorizontalLine: (val) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(activity.length, (index) {
                      final val = (activity.values.toList()[index] as num).toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            width: 14,
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot('Transactions', const Color(0xFF10B981)),
                ],
              )
            ],
          ),
        ),

        // Transaction Status Donut (Real Data)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: _buildStatusSections(status),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_totalStatus(status)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              Text('Total', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatLegend('Active', status['active'] ?? 0, const Color(0xFF10B981)),
                        _StatLegend('Pending', status['pending'] ?? 0, const Color(0xFF3B82F6)),
                        _StatLegend('Completed', status['completed'] ?? 0, const Color(0xFF64748B)),
                        _StatLegend('Cancelled', status['cancelled'] ?? 0, const Color(0xFFEF4444)),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),

        // Transaction Journey (Stepper mock)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction Journey', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _JourneyStep('${analytics['total'] ?? 0}', 'Interactions', Icons.chat_bubble_outline, const Color(0xFF10B981)),
                  Icon(Icons.arrow_right_alt, color: Colors.grey[300]),
                  _JourneyStep('${status['pending'] ?? 0}', 'Pending', Icons.schedule_rounded, const Color(0xFF3B82F6)),
                  Icon(Icons.arrow_right_alt, color: Colors.grey[300]),
                  _JourneyStep('${status['active'] ?? 0}', 'Active/Handover', Icons.handshake_outlined, const Color(0xFF8B5CF6)),
                  Icon(Icons.arrow_right_alt, color: Colors.grey[300]),
                  _JourneyStep('${status['completed'] ?? 0}', 'Completed', Icons.card_giftcard, const Color(0xFFF59E0B)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  double _getMaxActivity(Map<String, dynamic> activity) {
    if (activity.isEmpty) return 10.0;
    double max = 0;
    for (var val in activity.values) {
      if ((val as num).toDouble() > max) max = val.toDouble();
    }
    return max == 0 ? 10.0 : max * 1.2;
  }
}

// ---------------------------------------------------------
// 5. ACTIVITY MIX (Second screen start)
// ---------------------------------------------------------
class _ActivityMix extends StatelessWidget {
  final Map<String, dynamic> lending, borrowing, giving, received;
  const _ActivityMix({required this.lending, required this.borrowing, required this.giving, required this.received});

  @override
  Widget build(BuildContext context) {
    int l = lending['total'] ?? 0;
    int b = borrowing['total'] ?? 0;
    int g = giving['total'] ?? 0;
    int r = received['total'] ?? 0;
    int total = l + b + g + r;
    if (total == 0) {
      l = b = g = r = 25; // fallback for equal dummy donut if completely empty
    }

    return Column(
      children: [
        _SectionHeader(title: 'Activity Mix', onViewAll: null),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: glass.GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 45,
                            sections: [
                              PieChartSectionData(value: l.toDouble(), color: const Color(0xFF10B981), radius: 24, showTitle: false),
                              PieChartSectionData(value: g.toDouble(), color: const Color(0xFFF59E0B), radius: 24, showTitle: false),
                              PieChartSectionData(value: b.toDouble(), color: const Color(0xFF3B82F6), radius: 24, showTitle: false),
                              PieChartSectionData(value: r.toDouble(), color: const Color(0xFF8B5CF6), radius: 24, showTitle: false),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(total == 0 ? '0' : '$total', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            Text('Transactions', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PctLegend('Lending', total == 0 ? '0%' : '${(l/total*100).round()}%', const Color(0xFF10B981)),
                      _PctLegend('Giving', total == 0 ? '0%' : '${(g/total*100).round()}%', const Color(0xFFF59E0B)),
                      _PctLegend('Borrowing', total == 0 ? '0%' : '${(b/total*100).round()}%', const Color(0xFF3B82F6)),
                      _PctLegend('Receiving', total == 0 ? '0%' : '${(r/total*100).round()}%', const Color(0xFF8B5CF6)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 6. LENDING / BORROWING / GIVING / RECEIVED OVERVIEWS
// ---------------------------------------------------------
class _LendingOverview extends StatelessWidget {
  final Map<String, dynamic> lending;
  const _LendingOverview({required this.lending});
  @override Widget build(BuildContext context) => _OverviewBlock(title: 'Lending Overview', totalLabel: 'Total lending transactions', data: lending, primaryColor: const Color(0xFF10B981), icon: Icons.inventory_2_rounded);
}
class _BorrowingOverview extends StatelessWidget {
  final Map<String, dynamic> borrowing;
  const _BorrowingOverview({required this.borrowing});
  @override Widget build(BuildContext context) => _OverviewBlock(title: 'Borrowing Overview', totalLabel: 'Total borrowing transactions', data: borrowing, primaryColor: const Color(0xFF3B82F6), icon: Icons.sync_alt_rounded);
}
class _GivingOverview extends StatelessWidget {
  final Map<String, dynamic> giving;
  const _GivingOverview({required this.giving});
  @override Widget build(BuildContext context) => _OverviewBlock(title: 'Giving Overview', totalLabel: 'Total giving transactions', data: giving, primaryColor: const Color(0xFFF59E0B), icon: Icons.redeem_rounded);
}
class _ReceivedOverview extends StatelessWidget {
  final Map<String, dynamic> received;
  const _ReceivedOverview({required this.received});
  @override Widget build(BuildContext context) => _OverviewBlock(title: 'Received Overview', totalLabel: 'Total received transactions', data: received, primaryColor: const Color(0xFF8B5CF6), icon: Icons.group_outlined);
}

class _OverviewBlock extends StatelessWidget {
  final String title, totalLabel;
  final Map<String, dynamic> data;
  final Color primaryColor;
  final IconData icon;

  const _OverviewBlock({required this.title, required this.totalLabel, required this.data, required this.primaryColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    int total = data['total'] ?? 0;
    return Column(
      children: [
        _SectionHeader(title: title, onViewAll: () {}),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(total.toString(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(width: 8),
                  Text(totalLabel, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 24),
              if (data.containsKey('active')) _HorizontalBarRow('Active', data['active'], total, primaryColor),
              if (data.containsKey('pending_return')) _HorizontalBarRow('Pending return', data['pending_return'], total, const Color(0xFFF59E0B)),
              if (data.containsKey('pending_handover')) _HorizontalBarRow('Pending handover', data['pending_handover'], total, const Color(0xFFF59E0B)),
              if (data.containsKey('overdue')) _HorizontalBarRow('Overdue', data['overdue'], total, const Color(0xFFEF4444)),
              if (data.containsKey('completed')) _HorizontalBarRow('Completed', data['completed'], total, const Color(0xFF94A3B8)),
              if (data.containsKey('cancelled')) _HorizontalBarRow('Cancelled', data['cancelled'], total, const Color(0xFFEF4444)),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// 7. NEED IT NOW
// ---------------------------------------------------------
class _NeedItNow extends StatelessWidget {
  final Map<String, dynamic> urgent;
  const _NeedItNow({required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(title: 'Need It Now ⚡', onViewAll: () {}),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _UrgentStat(urgent['total'] ?? 0, 'Requests\ncreated', const Color(0xFF64748B)),
                  _UrgentStat(urgent['open'] ?? 0, 'Live', const Color(0xFF3B82F6)),
                  _UrgentStat(urgent['accepted'] ?? 0, 'Accepted', const Color(0xFFF59E0B)),
                  _UrgentStat(urgent['completed'] ?? 0, 'Completed', const Color(0xFF10B981)),
                  _UrgentStat(urgent['cancelled'] ?? 0, 'Cancelled', const Color(0xFFEF4444)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average time to first help', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text('-- min', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Not enough data to calculate.', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offers received per request', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        _HorizontalBarRow('1 offer', 0, 100, const Color(0xFF10B981), showValue: false, suffix: '0%'),
                        _HorizontalBarRow('2-3 offers', 0, 100, const Color(0xFF3B82F6), showValue: false, suffix: '0%'),
                        _HorizontalBarRow('4+ offers', 0, 100, const Color(0xFFF59E0B), showValue: false, suffix: '0%'),
                      ],
                    ),
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
              Builder(
                builder: (context) {
                  int totalUrgent = urgent['total'] ?? 0;
                  int open = urgent['open'] ?? 0;
                  int cancelled = urgent['cancelled'] ?? 0;
                  int completed = urgent['completed'] ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Urgent Request Outcomes', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.hardEdge,
                        child: totalUrgent == 0 ? null : Row(
                          children: [
                            if (completed > 0) Expanded(flex: completed, child: Container(color: const Color(0xFF10B981))),
                            if (open > 0) Expanded(flex: open, child: Container(color: const Color(0xFF3B82F6))),
                            if (cancelled > 0) Expanded(flex: cancelled, child: Container(color: const Color(0xFFF59E0B))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OutcomeLegend('Fulfilled\n${totalUrgent == 0 ? 0 : (completed/totalUrgent * 100).round()}%'),
                          _OutcomeLegend('Still Open\n${totalUrgent == 0 ? 0 : (open/totalUrgent * 100).round()}%'),
                          _OutcomeLegend('Cancelled\n${totalUrgent == 0 ? 0 : (cancelled/totalUrgent * 100).round()}%'),
                        ],
                      )
                    ],
                  );
                }
              ),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// 8. THIRD SCREEN SECTIONS
// ---------------------------------------------------------
class _RequestAnalytics extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _RequestAnalytics({required this.analytics});

  @override Widget build(BuildContext context) {
    int total = analytics['total'] ?? 0;
    int acc = analytics['accepted'] ?? 0;
    int pen = analytics['pending'] ?? 0;
    int dec = analytics['declined'] ?? 0;
    int can = analytics['cancelled'] ?? 0;
    
    final incTrend = (analytics['incoming_trend'] as Map<String, dynamic>? ?? {});
    final outTrend = (analytics['outgoing_trend'] as Map<String, dynamic>? ?? {});
    
    return Column(
      children: [
        _SectionHeader(title: 'Request Analytics', trailingText: 'Last 30 days v'),
        
        // Incoming vs Outgoing (Line Chart)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text('Incoming vs Outgoing Requests', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), 
              const SizedBox(height: 24), 
              if (total == 0)
                 Center(child: Text('No request data for this period.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)))
              else
                 SizedBox(
                   height: 150,
                   child: LineChart(
                     LineChartData(
                       gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (val) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                       titlesData: FlTitlesData(
                         bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                           final keys = {...incTrend.keys, ...outTrend.keys}.toList();
                           if (val.toInt() >= 0 && val.toInt() < keys.length) {
                             return Padding(padding: const EdgeInsets.only(top: 8), child: Text(keys[val.toInt()], style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))));
                           }
                           return const SizedBox.shrink();
                         })),
                         leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))))),
                         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       ),
                       borderData: FlBorderData(show: false),
                       lineBarsData: [
                         _createTrendLine(incTrend, const Color(0xFF3B82F6)),
                         _createTrendLine(outTrend, const Color(0xFF8B5CF6)),
                       ],
                     ),
                   ),
                 ),
                 const SizedBox(height: 16),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     _LegendDot('Incoming', const Color(0xFF3B82F6)),
                     const SizedBox(width: 16),
                     _LegendDot('Outgoing', const Color(0xFF8B5CF6)),
                   ],
                 )
            ]
          )
        ),
        
        // Request Outcomes (Horizontal Stack)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text('Request Outcomes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), 
              const SizedBox(height: 16), 
              Container(
                height: 16,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.hardEdge,
                child: total == 0 ? null : Row(
                  children: [
                    if (acc > 0) Expanded(flex: acc, child: Container(color: const Color(0xFF10B981))),
                    if (pen > 0) Expanded(flex: pen, child: Container(color: const Color(0xFFF59E0B))),
                    if (dec > 0) Expanded(flex: dec, child: Container(color: const Color(0xFFEF4444))),
                    if (can > 0) Expanded(flex: can, child: Container(color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _OutcomeLegend('Accepted\n${total == 0 ? 0 : (acc/total * 100).round()}%'),
                  _OutcomeLegend('Pending\n${total == 0 ? 0 : (pen/total * 100).round()}%'),
                  _OutcomeLegend('Declined\n${total == 0 ? 0 : (dec/total * 100).round()}%'),
                  _OutcomeLegend('Cancelled\n${total == 0 ? 0 : (can/total * 100).round()}%'),
                ],
              )
            ]
          )
        )
      ],
    );
  }

  LineChartBarData _createTrendLine(Map<String, dynamic> trend, Color color) {
    List<FlSpot> spots = [];
    int i = 0;
    for (var val in trend.values) {
      spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
      i++;
    }
    if (spots.isEmpty) spots.add(const FlSpot(0, 0)); // fallback
    return LineChartBarData(spots: spots, isCurved: true, color: color, barWidth: 3, isStrokeCapRound: true, dotData: FlDotData(show: true));
  }
}

class _ReturnsHandovers extends StatelessWidget {
  final Map<String, dynamic> rh;
  const _ReturnsHandovers({required this.rh});

  @override Widget build(BuildContext context) {
    double avg = (rh['avg_duration_days'] as num?)?.toDouble() ?? 0.0;
    return Column(
      children: [
        _SectionHeader(title: 'Returns & Handovers', onViewAll: () {}),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), 
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
                        _MicroStat('Waiting (owner)', rh['waiting_owner'] ?? 0, const Color(0xFFF59E0B)),
                        _MicroStat('Waiting (receiver)', rh['waiting_receiver'] ?? 0, const Color(0xFF3B82F6)),
                      ],
                    ),
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
              Text('Average lending duration', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('${avg.toStringAsFixed(1)} days', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 16),
              // Dummy distribution representation for average lending (since SQL doesn't return bin ranges yet)
              Container(
                height: 8,
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Text('Data reflects fully completed transaction lifecycle.', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
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
      children: [
        _SectionHeader(title: 'Post Performance', onViewAll: () {}),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981))),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${postPerf['posts_created'] ?? 0}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), Text('Total posts', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_MicroStat('Lend', postPerf['lend'] ?? 0, const Color(0xFF10B981)), _MicroStat('Give', postPerf['give'] ?? 0, const Color(0xFFF59E0B)), _MicroStat('Urgent', postPerf['urgent'] ?? 0, const Color(0xFFEF4444))])
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
              Column(
                children: [
                  _StatRow('Requests received', postPerf['requests_received'] ?? 0, const Color(0xFF10B981)),
                  _StatRow('Accepted', postPerf['accepted'] ?? 0, const Color(0xFF3B82F6)),
                  _StatRow('Completed', postPerf['completed'] ?? 0, const Color(0xFFF59E0B)),
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
// 9. TRANSACTIONS & RECEIPTS
// ---------------------------------------------------------
class _TransactionsReceipts extends StatefulWidget {
  final List<dynamic> history;
  const _TransactionsReceipts({required this.history});

  @override
  State<_TransactionsReceipts> createState() => _TransactionsReceiptsState();
}

class _TransactionsReceiptsState extends State<_TransactionsReceipts> with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;
  String _categoryFilter = 'All Activity';
  String _statusFilter = 'All';
  String _dateFilter = 'All Time';
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _dateFilter = 'Custom Range';
        _listAnimController.reset();
        _listAnimController.forward();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _listAnimController.forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // Group history by category for subsection display
    final Map<String, List<dynamic>> grouped = {
      'Lending': [],
      'Borrowing': [],
      'Giving': [],
      'Receiving': [],
    };
    
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
      
      bool dateMatch = true;
      if (_dateFilter != 'All Time' && item['date'] != null) {
        DateTime itemDate = DateTime.tryParse(item['date']) ?? DateTime.now();
        DateTime now = DateTime.now();
        if (_dateFilter == 'Last 7 Days') {
          dateMatch = now.difference(itemDate).inDays <= 7;
        } else if (_dateFilter == 'This Month') {
          dateMatch = itemDate.year == now.year && itemDate.month == now.month;
        } else if (_dateFilter == 'Custom Range' && _selectedDateRange != null) {
          dateMatch = itemDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                      itemDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
        }
      }
      
      return categoryMatch && statusMatch && dateMatch;
    }).toList();

    for (var item in filteredHistory) {
      String cat = item['category'] ?? '';
      if (cat == 'LEND') grouped['Lending']!.add(item);
      else if (cat == 'BORROW') grouped['Borrowing']!.add(item);
      else if (cat == 'GIVE') grouped['Giving']!.add(item);
      else if (cat == 'RECEIVE') grouped['Receiving']!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Transactions Ledger', onViewAll: () {}),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: glass.GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Category', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildModernFilter('All Activity', _categoryFilter == 'All Activity', () => _setFilter('category', 'All Activity')),
                    _buildModernFilter('Lend', _categoryFilter == 'Lend', () => _setFilter('category', 'Lend')),
                    _buildModernFilter('Borrow', _categoryFilter == 'Borrow', () => _setFilter('category', 'Borrow')),
                    _buildModernFilter('Give', _categoryFilter == 'Give', () => _setFilter('category', 'Give')),
                    _buildModernFilter('Receive', _categoryFilter == 'Receive', () => _setFilter('category', 'Receive')),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFE2E8F0), height: 1)),
                Text('Status', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildModernFilter('All Status', _statusFilter == 'All', () => _setFilter('status', 'All')),
                    _buildModernFilter('Pending', _statusFilter == 'Pending', () => _setFilter('status', 'Pending')),
                    _buildModernFilter('Completed', _statusFilter == 'Completed', () => _setFilter('status', 'Completed')),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFE2E8F0), height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date Range', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                    if (_dateFilter == 'Custom Range' && _selectedDateRange != null)
                      Text('${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildModernFilter('All Time', _dateFilter == 'All Time', () => _setFilter('date', 'All Time')),
                    _buildModernFilter('Last 7 Days', _dateFilter == 'Last 7 Days', () => _setFilter('date', 'Last 7 Days')),
                    _buildModernFilter('This Month', _dateFilter == 'This Month', () => _setFilter('date', 'This Month')),
                    _buildModernFilter('Custom Date...', _dateFilter == 'Custom Range', () => _pickDateRange(context), icon: Icons.calendar_month_outlined),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (filteredHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32), 
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No transactions found for these filters.", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              )
            )
          )
        else
          ...grouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final item = entry.value[index];
                    final overallIndex = filteredHistory.indexOf(item);
                    final animation = CurvedAnimation(
                      parent: _listAnimController,
                      curve: Interval((overallIndex * 0.15).clamp(0.0, 1.0), 1.0, curve: Curves.fastLinearToSlowEaseIn),
                    );
                    return ShareNestMotion.fadeSlide(
                      animation: animation,
                      child: _AdvancedReceiptCard(item: item),
                    );
                  },
                ),
              ],
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  void _setFilter(String type, String value) {
    setState(() {
      if (type == 'category') _categoryFilter = value;
      if (type == 'status') _statusFilter = value;
      if (type == 'date') _dateFilter = value;
      _listAnimController.reset();
      _listAnimController.forward();
    });
  }

  Widget _buildModernFilter(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
    
    // Dynamic styling based on real categories
    if (category == 'LEND') { color = const Color(0xFF10B981); icon = Icons.outbox_rounded; }
    else if (category == 'BORROW') { color = const Color(0xFF3B82F6); icon = Icons.move_to_inbox_rounded; }
    else if (category == 'GIVE') { color = const Color(0xFFF59E0B); icon = Icons.redeem_rounded; }
    else if (category == 'RECEIVE') { color = const Color(0xFF8B5CF6); icon = Icons.volunteer_activism_rounded; }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item['id'] != null) {
              if (item['is_owner'] == true) {
                context.push('/owner-request-detail/${item['id']}');
              } else {
                context.push('/requester-request-detail/${item['id']}');
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          highlightColor: color.withValues(alpha: 0.05),
          splashColor: color.withValues(alpha: 0.1),
          child: glass.GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Advanced Icon Box with inner glow
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ), 
                  child: Icon(icon, color: color, size: 28)
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color, 
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                            ),
                            child: Text(category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(status.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Trailing metrics & receipt button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('MMM dd, yy').format(date), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))), 
                      child: Row(
                        children: [
                          Text('View', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF475569))
                        ],
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HELPERS
// ---------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String? trailingText;
  const _SectionHeader({required this.title, this.onViewAll, this.trailingText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          if (onViewAll != null)
            GestureDetector(onTap: onViewAll, child: Text('View all >', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))))
          else if (trailingText != null)
            Text(trailingText!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);
  @override Widget build(BuildContext context) => Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)))]);
}

class _StatLegend extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatLegend(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))), Text(value.toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))]));
}

List<PieChartSectionData> _buildStatusSections(Map<String, dynamic> status) {
  int a = status['active'] ?? 0;
  int p = status['pending'] ?? 0;
  int c = status['completed'] ?? 0;
  int d = status['cancelled'] ?? 0;
  if (a+p+c+d == 0) return [PieChartSectionData(value: 1, color: Colors.grey[200], radius: 16, showTitle: false)];
  return [
    if (a > 0) PieChartSectionData(value: a.toDouble(), color: const Color(0xFF10B981), radius: 16, showTitle: false),
    if (p > 0) PieChartSectionData(value: p.toDouble(), color: const Color(0xFF3B82F6), radius: 16, showTitle: false),
    if (c > 0) PieChartSectionData(value: c.toDouble(), color: const Color(0xFF64748B), radius: 16, showTitle: false),
    if (d > 0) PieChartSectionData(value: d.toDouble(), color: const Color(0xFFEF4444), radius: 16, showTitle: false),
  ];
}
int _totalStatus(Map<String, dynamic> status) => (status['active'] ?? 0) + (status['pending'] ?? 0) + (status['completed'] ?? 0) + (status['cancelled'] ?? 0);

class _JourneyStep extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _JourneyStep(this.value, this.label, this.icon, this.color);
  @override Widget build(BuildContext context) => Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 4), Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)))]);
}

class _PctLegend extends StatelessWidget {
  final String label, pct;
  final Color color;
  const _PctLegend(this.label, this.pct, this.color);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))), Text(pct, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))]));
}

class _HorizontalBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final bool showValue;
  final String? suffix;
  const _HorizontalBarRow(this.label, this.value, this.total, this.color, {this.showValue = true, this.suffix});

  @override
  Widget build(BuildContext context) {
    double flex = total == 0 ? 0 : (value / total);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: flex, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)))),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 24, child: Text(showValue ? value.toString() : (suffix ?? ''), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))),
        ],
      ),
    );
  }
}

class _UrgentStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _UrgentStat(this.value, this.label, this.color);
  @override Widget build(BuildContext context) => Column(children: [Text(value.toString(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)), Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)))]);
}
class _OutcomeLegend extends StatelessWidget {
  final String label;
  const _OutcomeLegend(this.label);
  @override Widget build(BuildContext context) => Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)));
}
class _MicroStat extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _MicroStat(this.label, this.val, this.color);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))), const SizedBox(width: 12), Text(val.toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))]));
}
class _StatRow extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _StatRow(this.label, this.val, this.color);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))), Text(val.toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))]));
}
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;
  const _FilterChip(this.label, this.active, {this.icon, this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: active ? const Color(0xFF10B981) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? const Color(0xFF10B981) : const Color(0xFFE2E8F0))), child: Row(children: [if(icon!=null) ...[Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF64748B)), const SizedBox(width: 6)], Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.white : const Color(0xFF64748B)))])),
  );
}
