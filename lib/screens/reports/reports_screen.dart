import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/stat_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Reports & Analytics'),
          ),
          investmentsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (investments) {
              if (investments.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No investment data.\nAdd investments to see reports.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }

              double totalInitial = 0;
              double totalWithdrawn = 0;
              int totalWithdrawals = 0;

              for (final inv in investments) {
                totalInitial += inv.investment.initialAmount;
                totalWithdrawn += inv.totalWithdrawn;
                totalWithdrawals += inv.withdrawalCount;
              }

              final totalRemaining = totalInitial - totalWithdrawn;
              final overallPct = totalInitial > 0
                  ? (totalWithdrawn / totalInitial) * 100
                  : 0.0;

              return SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        StatCard(
                          label: 'Total Portfolio',
                          value: formatCurrency(totalInitial),
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF0D9488),
                          subtitle: '${investments.length} accounts',
                        ),
                        StatCard(
                          label: 'Total Withdrawn',
                          value: formatCurrency(totalWithdrawn),
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFFD97706),
                          subtitle: '$totalWithdrawals transactions',
                        ),
                        StatCard(
                          label: 'Total Remaining',
                          value: formatCurrency(totalRemaining),
                          icon: Icons.savings_rounded,
                          color: const Color(0xFF16A34A),
                          subtitle: '${formatPercent(100 - overallPct)} remaining',
                        ),
                        StatCard(
                          label: 'Utilization',
                          value: formatPercent(overallPct),
                          icon: Icons.donut_large_rounded,
                          color: const Color(0xFF7C3AED),
                          subtitle: 'of portfolio',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (investments.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionTitle('Portfolio Allocation'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PortfolioBarChart(investments: investments),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionTitle('Account Summary'),
                  ),
                  const SizedBox(height: 12),
                  ...investments.map(
                    (inv) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _AccountSummaryRow(data: inv),
                    ),
                  ),
                  const SizedBox(height: 80),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _PortfolioBarChart extends StatelessWidget {
  final List investments;

  const _PortfolioBarChart({required this.investments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = investments
        .map((i) => i.investment.initialAmount)
        .reduce((a, b) => math.max(a as double, b as double));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: (maxVal as double) * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= investments.length) {
                      return const SizedBox();
                    }
                    final name =
                        investments[idx].investment.investorName as String;
                    final short =
                        name.split(' ').map((s) => s[0]).take(3).join();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(short,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 55,
                  getTitlesWidget: (v, meta) => Text(
                    formatCompactCurrency(v),
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(investments.length, (i) {
              final inv = investments[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: inv.totalWithdrawn as double,
                    color: const Color(0xFFD97706),
                    width: 16,
                    borderRadius: BorderRadius.zero,
                  ),
                  BarChartRodData(
                    toY: inv.remainingBalance as double,
                    color: const Color(0xFF0D9488),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
                barsSpace: 2,
              );
            }),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gIdx, rod, rIdx) {
                  final label = rIdx == 0 ? 'Withdrawn' : 'Remaining';
                  return BarTooltipItem(
                    '$label\n${formatCurrency(rod.toY)}',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountSummaryRow extends StatelessWidget {
  final dynamic data;
  const _AccountSummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = data.withdrawalPercentage as double;
    final progressColor = pct >= 80
        ? const Color(0xFFDC2626)
        : pct >= 60
            ? const Color(0xFFD97706)
            : const Color(0xFF0D9488);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.investment.investorName as String,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatPercent(pct),
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (data.utilizationProgress as double).clamp(0.0, 1.0),
              backgroundColor: progressColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatCurrency(data.investment.initialAmount as double),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                '${data.withdrawalCount} withdrawals',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                '${formatCurrency(data.remainingBalance as double)} left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
