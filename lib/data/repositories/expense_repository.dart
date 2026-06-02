import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _db;
  final String _uid;

  ExpenseRepository(this._uid) : _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('expenses');

  Future<List<Expense>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map(Expense.fromFirestore).toList();
  }

  Future<List<Expense>> getByDateRange(DateTime from, DateTime to) async {
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    final list = snap.docs.map(Expense.fromFirestore).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<String> insert(Expense expense) async {
    final ref = await _col.add(expense.toFirestore());
    return ref.id;
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<double> getTotalForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.fold<double>(0.0, (acc, d) => acc + (d['amount'] as num).toDouble());
  }

  Future<double> getTotalForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.fold<double>(0.0, (acc, d) => acc + (d['amount'] as num).toDouble());
  }
}
