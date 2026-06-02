import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final statsAsync = ref.watch(expenseStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Expenses'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_comment_rounded),
                tooltip: 'Log Expense',
                onPressed: () => context.push('/expenses/chat'),
              ),
            ],
          ),

          // Summary cards
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox(height: 120),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _SummarySection(stats: stats, isDark: isDark),
            ),
          ),

          // Category breakdown
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => stats.categoryTotals.isEmpty
                  ? const SizedBox.shrink()
                  : _CategoryBreakdown(
                      totals: stats.categoryTotals,
                      monthTotal: stats.monthTotal,
                      isDark: isDark,
                    ),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // Expense list
          expensesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (expenses) {
              if (expenses.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    onLog: () => context.push('/expenses/chat'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final e = expenses[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _ExpenseListItem(
                        expense: e,
                        isDark: isDark,
                        onDelete: () => ref
                            .read(expensesProvider.notifier)
                            .deleteExpense(e.id!),
                      ),
                    );
                  },
                  childCount: expenses.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/chat'),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Log Expense'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final ExpenseStats stats;
  final bool isDark;

  const _SummarySection({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Today',
              amount: formatCurrency(stats.todayTotal),
              count: stats.todayCount,
              icon: Icons.today_rounded,
              color: const Color(0xFF0D9488),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'This Month',
              amount: formatCurrency(stats.monthTotal),
              count: stats.monthCount,
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF7C3AED),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final int count;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                '$count txn',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatefulWidget {
  final Map<String, double> totals;
  final double monthTotal;
  final bool isDark;

  const _CategoryBreakdown({
    required this.totals,
    required this.monthTotal,
    required this.isDark,
  });

  @override
  State<_CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<_CategoryBreakdown> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = widget.totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    final sections = top5.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final cat = categoryByName(e.key);
      final color = cat?.color ?? const Color(0xFF94A3B8);
      final isTouched = i == _touchedIndex;
      final pct = widget.monthTotal > 0 ? (e.value / widget.monthTotal) * 100 : 0.0;

      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: isTouched ? 64 : 54,
        title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.isDark
              ? Border.all(color: const Color(0xFF334155))
              : null,
          boxShadow: widget.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month by Category',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie chart
                RepaintBoundary(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              _touchedIndex = event.isInterestedForInteractions
                                  ? response?.touchedSection
                                          ?.touchedSectionIndex ??
                                      -1
                                  : -1;
                            });
                          },
                        ),
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend + bars
                Expanded(
                  child: Column(
                    children: top5.map((e) {
                      final cat = categoryByName(e.key);
                      final color = cat?.color ?? const Color(0xFF94A3B8);
                      final pct = widget.monthTotal > 0
                          ? (e.value / widget.monthTotal)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatCurrency(e.value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                backgroundColor:
                                    color.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Expense List Item ────────────────────────────────────────────────────────

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final VoidCallback onDelete;

  const _ExpenseListItem({
    required this.expense,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categoryByName(expense.category);
    final color = cat?.color ?? expense.color;
    final emoji = cat?.emoji ?? '📦';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expDay = DateTime(
        expense.date.year, expense.date.month, expense.date.day);

    final dateLabel = expDay.isAtSameMomentAs(today)
        ? 'Today, ${DateFormat('h:mm a').format(expense.date)}'
        : expDay.isAtSameMomentAs(yesterday)
            ? 'Yesterday'
            : formatDate(expense.date);

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFDC2626), size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Expense'),
            content:
                Text('Delete ${expense.category} expense of ${formatCurrency(expense.amount)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626)),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.note?.isNotEmpty == true
                        ? expense.note!
                        : dateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (expense.note?.isNotEmpty == true)
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '-${formatCurrency(expense.amount)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onLog;
  const _EmptyState({required this.onLog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.15),
                    const Color(0xFF0369A1).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No Expenses Yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Start logging your daily expenses with a quick chat — no boring forms!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLog,
                icon: const Icon(Icons.add_comment_rounded),
                label: const Text('Log First Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
