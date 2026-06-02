import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/expense.dart';
import 'database_provider.dart';

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(expenseRepositoryProvider).getAll();
  }

  Future<void> addExpense({
    required String category,
    required int categoryColor,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final expense = Expense(
      category: category,
      categoryColor: categoryColor,
      amount: amount,
      note: note,
      date: date,
      createdAt: DateTime.now(),
    );
    await ref.read(expenseRepositoryProvider).insert(expense);
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

// Computed stats provider
class ExpenseStats {
  final double todayTotal;
  final double monthTotal;
  final Map<String, double> categoryTotals;
  final int todayCount;
  final int monthCount;

  const ExpenseStats({
    required this.todayTotal,
    required this.monthTotal,
    required this.categoryTotals,
    required this.todayCount,
    required this.monthCount,
  });
}

final expenseStatsProvider = FutureProvider<ExpenseStats>((ref) async {
  final all = await ref.watch(expensesProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);

  double todayTotal = 0;
  double monthTotal = 0;
  int todayCount = 0;
  int monthCount = 0;
  final catTotals = <String, double>{};

  for (final e in all) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    final isToday = day.isAtSameMomentAs(today);
    final isThisMonth = !e.date.isBefore(monthStart);

    if (isToday) {
      todayTotal += e.amount;
      todayCount++;
    }
    if (isThisMonth) {
      monthTotal += e.amount;
      monthCount++;
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
  }

  return ExpenseStats(
    todayTotal: todayTotal,
    monthTotal: monthTotal,
    categoryTotals: catTotals,
    todayCount: todayCount,
    monthCount: monthCount,
  );
});
