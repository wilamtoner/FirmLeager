import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_transaction.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';

final recurringProvider = StateNotifierProvider<RecurringNotifier, List<RecurringTransactionModel>>((ref) {
  final notifier = RecurringNotifier(ref);
  return notifier;
});

class RecurringNotifier extends StateNotifier<List<RecurringTransactionModel>> {
  final Ref _ref;
  final DatabaseService _db = DatabaseService();

  RecurringNotifier(this._ref) : super([]) {
    checkAndProcessDue();
  }

  Future<void> loadRecurring() async {
    final list = await _db.getRecurringTransactions();
    state = list;
  }

  Future<void> addRecurring(RecurringTransactionModel recurring) async {
    await _db.insertRecurringTransaction(recurring);
    await loadRecurring();
    await checkAndProcessDue();
  }

  Future<void> updateRecurring(RecurringTransactionModel recurring) async {
    await _db.updateRecurringTransaction(recurring);
    await loadRecurring();
  }

  Future<void> toggleActive(String id) async {
    final item = state.firstWhere((r) => r.id == id);
    final updated = item.copyWith(isActive: !item.isActive);
    await updateRecurring(updated);
  }

  Future<void> deleteRecurring(String id) async {
    await _db.deleteRecurringTransaction(id);
    await loadRecurring();
  }

  Future<int> checkAndProcessDue() async {
    final executed = await _db.processPendingRecurringTransactions();
    if (executed > 0) {
      // Reload active transactions state if any were auto-generated
      await _ref.read(transactionProvider.notifier).loadTransactions();
    }
    await loadRecurring();
    return executed;
  }
}
