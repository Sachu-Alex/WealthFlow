import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/pdf_report_service.dart';
import '../../providers/investment_provider.dart';
import '../../providers/withdrawal_provider.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/withdrawal_list_item.dart';

class InvestmentDetailScreen extends ConsumerStatefulWidget {
  final String investmentId;
  const InvestmentDetailScreen({super.key, required this.investmentId});

  @override
  ConsumerState<InvestmentDetailScreen> createState() =>
      _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState
    extends ConsumerState<InvestmentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date_desc';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    final investment =
        await ref.read(investmentByIdProvider(widget.investmentId).future);
    if (investment == null || !mounted) return;

    setState(() => _exporting = true);
    try {
      final withdrawals =
          await ref.read(withdrawalsProvider(widget.investmentId).future);

      final bytes = await PdfReportService.generateInvestmentReport(
        investment: investment,
        withdrawals: withdrawals,
      );

      final safeFileName =
          investment.investorName.replaceAll(RegExp(r'[^\w]'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'wealthflow_$safeFileName.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final investmentAsync =
        ref.watch(investmentByIdProvider(widget.investmentId));
    final statsAsync =
        ref.watch(investmentStatsProvider(widget.investmentId));

    return Scaffold(
      body: investmentAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (investment) {
          if (investment == null) {
            return const Scaffold(
                body: Center(child: Text('Investment not found')));
          }
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 196,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white),
                    tooltip: 'Export PDF',
                    onPressed: _exporting ? null : _exportPdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white),
                    tooltip: 'Add Withdrawal',
                    onPressed: () => context.push(
                        '/investments/${widget.investmentId}/withdrawal/add'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _GradientHeader(
                    investorName: investment.investorName,
                    investmentDate: investment.investmentDate,
                    statsAsync: statsAsync,
                    initialAmount: investment.initialAmount,
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Charts'),
                    Tab(text: 'History'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  investmentId: widget.investmentId,
                  statsAsync: statsAsync,
                  initialAmount: investment.initialAmount,
                ),
                _ChartsTab(
                  statsAsync: statsAsync,
                  isDark: isDark,
                ),
                _HistoryTab(
                  investmentId: widget.investmentId,
                  searchCtrl: _searchCtrl,
                  searchQuery: _searchQuery,
                  sortBy: _sortBy,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onSortChanged: (s) => setState(() => _sortBy = s),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
            '/investments/${widget.investmentId}/withdrawal/add'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final String investorName;
  final DateTime investmentDate;
  final AsyncValue<InvestmentStats> statsAsync;
  final double initialAmount;

  const _GradientHeader({
    required this.investorName,
    required this.investmentDate,
    required this.statsAsync,
    required this.initialAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 52, 20, 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  investorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Since ${formatDate(investmentDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      _HeaderStat(
                        label: 'Remaining',
                        value: formatCurrency(stats.remainingBalance),
                        color: const Color(0xFF6EE7B7),
                      ),
                      const SizedBox(width: 20),
                      _HeaderStat(
                        label: 'Withdrawn',
                        value: formatCurrency(stats.totalWithdrawn),
                        color: const Color(0xFFFDE68A),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          statsAsync.when(
            data: (stats) => AnimatedProgressRing(
              progress:
                  (stats.totalWithdrawn / initialAmount).clamp(0.0, 1.0),
              size: 96,
              centerLabel: formatPercent(stats.withdrawalPercentage),
              subLabel: 'Used',
              color: Colors.white,
              strokeWidth: 9,
            ),
            loading: () => const SizedBox(width: 96, height: 96),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.3),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
        ),
      ],
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String investmentId;
  final AsyncValue<InvestmentStats> statsAsync;
  final double initialAmount;

  const _OverviewTab({
    required this.investmentId,
    required this.statsAsync,
    required this.initialAmount,
  });

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          // Central ring + amounts
          _RingSection(stats: stats, initialAmount: initialAmount),
          const SizedBox(height: 20),
          // Balance bar card
          _BalanceCard(stats: stats, initialAmount: initialAmount),
          const SizedBox(height: 16),
          // Stats grid — uses mainAxisExtent to PREVENT overflow
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 128, // Fixed height — no overflow ever
            ),
            itemCount: 4,
            itemBuilder: (context, i) {
              switch (i) {
                case 0:
                  return StatCard(
                    label: 'Initial Investment',
                    value: formatCurrency(initialAmount),
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF0D9488),
                  );
                case 1:
                  return StatCard(
                    label: 'Total Withdrawn',
                    value: formatCurrency(stats.totalWithdrawn),
                    icon: Icons.south_rounded,
                    color: const Color(0xFFD97706),
                  );
                case 2:
                  return StatCard(
                    label: 'Remaining Balance',
                    value: formatCurrency(stats.remainingBalance),
                    icon: Icons.savings_rounded,
                    color: const Color(0xFF16A34A),
                  );
                default:
                  return StatCard(
                    label: 'Withdrawals',
                    value: '${stats.withdrawalCount}',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF7C3AED),
                    subtitle: 'total transactions',
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RingSection extends StatelessWidget {
  final InvestmentStats stats;
  final double initialAmount;

  const _RingSection(
      {required this.stats, required this.initialAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF1A3349)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          AnimatedProgressRing(
            progress:
                (stats.totalWithdrawn / initialAmount).clamp(0.0, 1.0),
            size: 140,
            centerLabel: formatPercent(stats.withdrawalPercentage),
            subLabel: 'Withdrawn',
            strokeWidth: 14,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingStat(
                  label: 'Withdrawn',
                  value: formatCurrency(stats.totalWithdrawn),
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(height: 12),
                _RingStat(
                  label: 'Remaining',
                  value: formatCurrency(stats.remainingBalance),
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 12),
                _RingStat(
                  label: 'Initial',
                  value: formatCurrency(initialAmount),
                  color: const Color(0xFF0D9488),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RingStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final InvestmentStats stats;
  final double initialAmount;

  const _BalanceCard(
      {required this.stats, required this.initialAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = initialAmount > 0
        ? (stats.remainingBalance / initialAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF1A3349)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(stats.remainingBalance),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${formatPercent(progress * 100)} left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  const Color(0xFF16A34A).withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF16A34A)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹0',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              Text(formatCurrency(initialAmount),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Charts Tab ───────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  final AsyncValue<InvestmentStats> statsAsync;
  final bool isDark;

  const _ChartsTab({required this.statsAsync, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          _ChartSection(
            title: 'Allocation',
            subtitle: 'Withdrawn vs remaining',
            child: stats.totalWithdrawn == 0
                ? const _EmptyChartState(
                    message: 'Record a withdrawal to see allocation')
                : RepaintBoundary(
                    child: _PieChartWidget(stats: stats)),
          ),
          const SizedBox(height: 16),
          _ChartSection(
            title: 'Balance Timeline',
            subtitle: 'Balance after each withdrawal',
            child: stats.balanceHistory.length < 2
                ? const _EmptyChartState(
                    message: 'Need at least one withdrawal')
                : RepaintBoundary(
                    child: _LineChartWidget(
                        spots: stats.balanceHistory,
                        isDark: isDark)),
          ),
          const SizedBox(height: 16),
          _ChartSection(
            title: 'Monthly Withdrawals',
            subtitle: 'Grouped by month',
            child: stats.monthlyWithdrawals.isEmpty
                ? const _EmptyChartState(message: 'No withdrawal data')
                : RepaintBoundary(
                    child: _BarChartWidget(
                        monthly: stats.monthlyWithdrawals,
                        isDark: isDark)),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartSection(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF1A3349)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final String message;
  const _EmptyChartState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PieChartWidget extends StatefulWidget {
  final InvestmentStats stats;
  const _PieChartWidget({required this.stats});

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final withdrawn = widget.stats.totalWithdrawn;
    final remaining = widget.stats.remainingBalance;
    final total = withdrawn + remaining;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touched = event.isInterestedForInteractions
                        ? response?.touchedSection?.touchedSectionIndex ?? -1
                        : -1;
                  });
                },
              ),
              sections: [
                PieChartSectionData(
                  value: withdrawn,
                  color: const Color(0xFFD97706),
                  title: _touched == 0
                      ? formatCurrency(withdrawn)
                      : '${(withdrawn / total * 100).toStringAsFixed(1)}%',
                  radius: _touched == 0 ? 88 : 78,
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                PieChartSectionData(
                  value: remaining,
                  color: const Color(0xFF0D9488),
                  title: _touched == 1
                      ? formatCurrency(remaining)
                      : '${(remaining / total * 100).toStringAsFixed(1)}%',
                  radius: _touched == 1 ? 88 : 78,
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ],
              sectionsSpace: 3,
              centerSpaceRadius: 44,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(
                color: const Color(0xFFD97706),
                label: 'Withdrawn',
                value: formatCurrency(withdrawn)),
            const SizedBox(width: 24),
            _Legend(
                color: const Color(0xFF0D9488),
                label: 'Remaining',
                value: formatCurrency(remaining)),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Legend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final bool isDark;

  const _LineChartWidget({required this.spots, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxY = spots.map((s) => s.y).reduce(math.max) * 1.12;
    final minY =
        math.max(0.0, spots.map((s) => s.y).reduce(math.min) * 0.88);
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                getTitlesWidget: (v, _) => Text(
                  formatCompactCurrency(v),
                  style: TextStyle(fontSize: 9, color: labelColor),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: spots.length > 6
                    ? (spots.length / 5).roundToDouble()
                    : 1,
                getTitlesWidget: (v, _) => Text(
                  '#${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: labelColor),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF0D9488),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF0D9488),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.2),
                    const Color(0xFF0D9488).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        formatCurrency(s.y),
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<String, double> monthly;
  final bool isDark;

  const _BarChartWidget(
      {required this.monthly, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = monthly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last6 =
        sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;
    final maxY = last6.map((e) => e.value).reduce(math.max) * 1.25;
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= last6.length) {
                    return const SizedBox();
                  }
                  final parts = last6[i].key.split('-');
                  final dt = DateTime(
                      int.parse(parts[0]), int.parse(parts[1]));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM').format(dt),
                      style: TextStyle(fontSize: 9, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  formatCompactCurrency(v),
                  style: TextStyle(fontSize: 9, color: labelColor),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            last6.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: last6[i].value,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                formatCurrency(rod.toY),
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  final String investmentId;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;

  const _HistoryTab({
    required this.investmentId,
    required this.searchCtrl,
    required this.searchQuery,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(withdrawalsProvider(investmentId));

    return withdrawalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        var filtered = all.where((w) {
          if (searchQuery.isEmpty) return true;
          final q = searchQuery.toLowerCase();
          return (w.remarks?.toLowerCase().contains(q) ?? false) ||
              formatDate(w.withdrawalDate).toLowerCase().contains(q) ||
              formatCurrency(w.amount).contains(q);
        }).toList();

        filtered = [...filtered]..sort((a, b) {
            switch (sortBy) {
              case 'amount_desc':
                return b.amount.compareTo(a.amount);
              case 'amount_asc':
                return a.amount.compareTo(b.amount);
              case 'date_asc':
                return a.withdrawalDate.compareTo(b.withdrawalDate);
              default:
                return b.withdrawalDate.compareTo(a.withdrawalDate);
            }
          });

        return Column(
          children: [
            // Search + sort bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search withdrawals…',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: sortBy,
                      onSelected: onSortChanged,
                      icon: Icon(Icons.sort_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22),
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'date_desc',
                            child: Text('Newest First')),
                        PopupMenuItem(
                            value: 'date_asc',
                            child: Text('Oldest First')),
                        PopupMenuItem(
                            value: 'amount_desc',
                            child: Text('Highest Amount')),
                        PopupMenuItem(
                            value: 'amount_asc',
                            child: Text('Lowest Amount')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Results count
            if (all.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? 'record' : 'records'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        searchQuery.isEmpty
                            ? 'No withdrawals yet\nTap + to add one'
                            : 'No results for "$searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => WithdrawalListItem(
                        withdrawal: filtered[i],
                        onDelete: () => ref
                            .read(withdrawalsProvider(investmentId)
                                .notifier)
                            .deleteWithdrawal(filtered[i].id!),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
