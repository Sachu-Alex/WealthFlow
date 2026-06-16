import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/withdrawal.dart';
import 'database_provider.dart';
import 'investment_provider.dart';

class WithdrawalsNotifier
    extends FamilyAsyncNotifier<List<Withdrawal>, String> {
  @override
  Future<List<Withdrawal>> build(String investmentId) async {
    return ref.read(withdrawalRepositoryProvider).getByInvestmentId(investmentId);
  }

  Future<void> addWithdrawal({
    required double amount,
    required DateTime withdrawalDate,
    String? remarks,
  }) async {
    final withdrawal = Withdrawal(
      investmentId: arg,
      amount: amount,
      withdrawalDate: withdrawalDate,
      remarks: remarks,
      createdAt: DateTime.now(),
    );
    await ref.read(withdrawalRepositoryProvider).insert(withdrawal);
    ref.invalidateSelf();
    ref.invalidate(investmentsProvider);
  }

  Future<void> deleteWithdrawal(String id) async {
    await ref.read(withdrawalRepositoryProvider).delete(id);
    ref.invalidateSelf();
    ref.invalidate(investmentsProvider);
  }
}

final withdrawalsProvider =
    AsyncNotifierProvider.family<WithdrawalsNotifier, List<Withdrawal>, String>(
  WithdrawalsNotifier.new,
);

final allWithdrawalsProvider = FutureProvider<List<Withdrawal>>((ref) async {
  return ref.read(withdrawalRepositoryProvider).getAll();
});

class InvestmentStats {
  final double totalWithdrawn;
  final double remainingBalance;
  final double withdrawalPercentage;
  final int withdrawalCount;
  final List<FlSpot> balanceHistory;
  final Map<String, double> monthlyWithdrawals;

  const InvestmentStats({
    required this.totalWithdrawn,
    required this.remainingBalance,
    required this.withdrawalPercentage,
    required this.withdrawalCount,
    required this.balanceHistory,
    required this.monthlyWithdrawals,
  });
}

final investmentStatsProvider =
    FutureProvider.family<InvestmentStats, String>((ref, investmentId) async {
  final investmentAsync =
      await ref.watch(investmentByIdProvider(investmentId).future);
  final withdrawals =
      await ref.watch(withdrawalsProvider(investmentId).future);

  if (investmentAsync == null) {
    return InvestmentStats(
      totalWithdrawn: 0,
      remainingBalance: 0,
      withdrawalPercentage: 0,
      withdrawalCount: 0,
      balanceHistory: [const FlSpot(0, 0)],
      monthlyWithdrawals: {},
    );
  }

  final initialAmount = investmentAsync.initialAmount;
  final totalWithdrawn = withdrawals.fold<double>(0.0, (acc, w) => acc + w.amount);
  final remaining = initialAmount - totalWithdrawn;
  final percentage =
      initialAmount > 0 ? (totalWithdrawn / initialAmount) * 100 : 0.0;

  final sorted = [...withdrawals]
    ..sort((a, b) => a.withdrawalDate.compareTo(b.withdrawalDate));

  double balance = initialAmount;
  final history = <FlSpot>[FlSpot(0, balance)];
  for (var i = 0; i < sorted.length; i++) {
    balance -= sorted[i].amount;
    history.add(FlSpot((i + 1).toDouble(), balance));
  }

  final monthly = <String, double>{};
  for (final w in withdrawals) {
    final key =
        '${w.withdrawalDate.year}-${w.withdrawalDate.month.toString().padLeft(2, '0')}';
    monthly[key] = (monthly[key] ?? 0) + w.amount;
  }

  return InvestmentStats(
    totalWithdrawn: totalWithdrawn,
    remainingBalance: remaining,
    withdrawalPercentage: percentage,
    withdrawalCount: withdrawals.length,
    balanceHistory: history,
    monthlyWithdrawals: monthly,
  );
});
