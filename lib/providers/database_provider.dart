import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/investment_repository.dart';
import '../data/repositories/withdrawal_repository.dart';
import '../data/repositories/expense_repository.dart';
import 'auth_provider.dart';

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) throw StateError('Not authenticated');
  return InvestmentRepository(uid);
});

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) throw StateError('Not authenticated');
  return WithdrawalRepository(uid);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) throw StateError('Not authenticated');
  return ExpenseRepository(uid);
});
