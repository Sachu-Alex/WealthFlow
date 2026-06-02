import 'investment.dart';

class InvestmentWithStats {
  final Investment investment;
  final double totalWithdrawn;
  final int withdrawalCount;

  const InvestmentWithStats({
    required this.investment,
    required this.totalWithdrawn,
    required this.withdrawalCount,
  });

  double get remainingBalance => investment.initialAmount - totalWithdrawn;

  double get withdrawalPercentage =>
      investment.initialAmount > 0 ? (totalWithdrawn / investment.initialAmount) * 100 : 0.0;

  double get utilizationProgress =>
      investment.initialAmount > 0 ? (totalWithdrawn / investment.initialAmount).clamp(0.0, 1.0) : 0.0;
}
