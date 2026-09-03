import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/recurring_transaction.dart';

class BackupService {
  static final DatabaseService _db = DatabaseService();

  static Future<File> createBackupFile() async {
    final categories = await _db.getCategories();
    final transactions = await _db.getTransactions();
    final debts = await _db.getDebts();
    final recurring = await _db.getRecurringTransactions();

    final backupData = {
      'appName': 'FirmLedger',
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'debts': debts.map((d) => d.toMap()).toList(),
      'recurring': recurring.map((r) => r.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    final directory = Directory.systemTemp;
    final path = '${directory.path}/firmledger_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path);
    return await file.writeAsString(jsonString);
  }

  static Future<Map<String, int>> restoreFromJson(String jsonContent) async {
    final Map<String, dynamic> data = jsonDecode(jsonContent);

    if (data['appName'] != 'FirmLedger') {
      throw const FormatException('Invalid backup file. Not a FirmLedger backup.');
    }

    int categoriesCount = 0;
    int transactionsCount = 0;
    int debtsCount = 0;
    int recurringCount = 0;

    // Restore Categories
    if (data['categories'] is List) {
      for (var item in data['categories']) {
        final cat = CategoryModel.fromMap(item as Map<String, dynamic>);
        await _db.saveCategory(cat);
        categoriesCount++;
      }
    }

    // Restore Transactions
    if (data['transactions'] is List) {
      for (var item in data['transactions']) {
        final tx = TransactionModel.fromMap(item as Map<String, dynamic>);
        await _db.insertTransaction(tx);
        transactionsCount++;
      }
    }

    // Restore Debts
    if (data['debts'] is List) {
      for (var item in data['debts']) {
        final debt = DebtModel.fromMap(item as Map<String, dynamic>);
        await _db.insertDebt(debt);
        debtsCount++;
      }
    }

    // Restore Recurring
    if (data['recurring'] is List) {
      for (var item in data['recurring']) {
        final r = RecurringTransactionModel.fromMap(item as Map<String, dynamic>);
        await _db.insertRecurringTransaction(r);
        recurringCount++;
      }
    }

    return {
      'categories': categoriesCount,
      'transactions': transactionsCount,
      'debts': debtsCount,
      'recurring': recurringCount,
    };
  }
}
