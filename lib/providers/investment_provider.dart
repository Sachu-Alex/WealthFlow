import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/investment.dart';
import '../data/models/investment_with_stats.dart';
import 'database_provider.dart';

class InvestmentsNotifier extends AsyncNotifier<List<InvestmentWithStats>> {
  @override
  Future<List<InvestmentWithStats>> build() async {
    return ref.read(investmentRepositoryProvider).getAllWithStats();
  }

  Future<String> addInvestment({
    required String investorName,
    required double initialAmount,
    required DateTime investmentDate,
    String? notes,
  }) async {
    final investment = Investment(
      investorName: investorName,
      initialAmount: initialAmount,
      investmentDate: investmentDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
    final id = await ref.read(investmentRepositoryProvider).insert(investment);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteInvestment(String id) async {
    await ref.read(investmentRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<InvestmentWithStats>>(
  InvestmentsNotifier.new,
);

final investmentByIdProvider =
    FutureProvider.family<Investment?, String>((ref, id) async {
  ref.watch(investmentsProvider);
  return ref.read(investmentRepositoryProvider).getById(id);
});
