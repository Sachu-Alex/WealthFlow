import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/investment_card.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: investmentsAsync.when(
        loading: () => _buildLoadingScaffold(context),
        error: (e, _) => _buildErrorScaffold(context, '$e'),
        data: (investments) {
          if (investments.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push('/investments/add'),
            );
          }

          double totalInitial = 0;
          double totalWithdrawn = 0;
          for (final inv in investments) {
            totalInitial += inv.investment.initialAmount;
            totalWithdrawn += inv.totalWithdrawn;
          }
          final totalRemaining = totalInitial - totalWithdrawn;
          final overallProgress =
              totalInitial > 0 ? totalWithdrawn / totalInitial : 0.0;

          return CustomScrollView(
            slivers: [
              // Simple pinned AppBar — no expandedHeight, no FlexibleSpaceBar
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text('SWP Tracker'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add Investment',
                    onPressed: () => context.push('/investments/add'),
                  ),
                ],
              ),

              // Portfolio summary card — scrolls with content, no size constraint
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: PortfolioHeaderCard(
                    totalInvested: formatCurrency(totalInitial),
                    totalWithdrawn: formatCurrency(totalWithdrawn),
                    totalRemaining: formatCurrency(totalRemaining),
                    accountCount: investments.length,
                    overallProgress: overallProgress,
                  ),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        'My Investments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${investments.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Investment cards list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final inv = investments[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: InvestmentCard(
                        data: inv,
                        onTap: () => context
                            .push('/investments/${inv.investment.id}'),
                        onDelete: () => _confirmDelete(
                            context, ref, inv.investment.id!),
                      ),
                    );
                  },
                  childCount: investments.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: investmentsAsync.maybeWhen(
        data: (investments) => investments.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/investments/add'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Investment'),
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SWP Tracker')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String msg) {
    return Scaffold(
      appBar: AppBar(title: const Text('SWP Tracker')),
      body: Center(child: Text('Error: $msg')),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Investment'),
        content: const Text(
          'This will permanently delete the investment and all its withdrawal records.',
        ),
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
    );
    if (confirmed == true && context.mounted) {
      ref.read(investmentsProvider.notifier).deleteInvestment(id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('SWP Tracker'),
          ],
        ),
      ),
      body: Center(
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
                  Icons.account_balance_wallet_outlined,
                  size: 38,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'No Investments Yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Start tracking your Systematic Withdrawal Plan by adding your first investment account.',
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
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add First Investment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
