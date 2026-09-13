import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../models/recurring_transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_debt_manager.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorHex INTEGER NOT NULL,
        budgetLimit REAL NOT NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        incomeType TEXT,
        paymentMethod TEXT,
        partyName TEXT,
        categoryId TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Debts Table
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        partyName TEXT NOT NULL,
        isOwedByMe INTEGER NOT NULL,
        originalAmount REAL NOT NULL,
        currentBalance REAL NOT NULL,
        apr REAL NOT NULL,
        minMonthlyPayment REAL NOT NULL,
        dueDate TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Debt Payments Table
    await db.execute('''
      CREATE TABLE debt_payments (
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Recurring Transactions Table
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        partyName TEXT,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        nextDueDate TEXT NOT NULL,
        lastExecutedDate TEXT,
        isActive INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Indexes for high performance querying
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(categoryId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_owed ON debts(isOwedByMe)');

    // Seed Default Categories
    await _seedDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN incomeType TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethod TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN partyName TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(categoryId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_owed ON debts(isOwedByMe)');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recurring_transactions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            categoryId TEXT NOT NULL,
            paymentMethod TEXT NOT NULL,
            partyName TEXT,
            frequency TEXT NOT NULL,
            startDate TEXT NOT NULL,
            nextDueDate TEXT NOT NULL,
            lastExecutedDate TEXT,
            isActive INTEGER NOT NULL,
            notes TEXT
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaults = [
      CategoryModel(id: 'cat_housing', name: 'Housing & Rent', colorHex: 0xFF4CAF50, budgetLimit: 1500.0),
      CategoryModel(id: 'cat_food', name: 'Food & Dining', colorHex: 0xFFFF9800, budgetLimit: 600.0),
      CategoryModel(id: 'cat_transport', name: 'Transportation', colorHex: 0xFF2196F3, budgetLimit: 300.0),
      CategoryModel(id: 'cat_utilities', name: 'Utilities & Bills', colorHex: 0xFF9C27B0, budgetLimit: 250.0),
      CategoryModel(id: 'cat_entertainment', name: 'Entertainment', colorHex: 0xFFE91E63, budgetLimit: 200.0),
      CategoryModel(id: 'cat_income', name: 'Salary & Income', colorHex: 0xFF009688, budgetLimit: 0.0),
    ];

    for (var cat in defaults) {
      await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final res = await db.query('categories');
    return res.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> saveCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final res = await db.query('transactions', orderBy: 'date DESC');
    return res.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- DEBTS ---
  Future<List<DebtModel>> getDebts() async {
    final db = await database;
    final res = await db.query('debts');
    return res.map((e) => DebtModel.fromMap(e)).toList();
  }

  Future<void> insertDebt(DebtModel debt) async {
    final db = await database;
    await db.insert('debts', debt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDebtBalance(String debtId, double newBalance) async {
    final db = await database;
    await db.update('debts', {'currentBalance': newBalance}, where: 'id = ?', whereArgs: [debtId]);
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    await db.delete('debt_payments', where: 'debtId = ?', whereArgs: [id]);
  }

  // --- DEBT PAYMENTS ---
  Future<List<DebtPaymentModel>> getDebtPayments(String debtId) async {
    final db = await database;
    final res = await db.query('debt_payments', where: 'debtId = ?', orderBy: 'date DESC', whereArgs: [debtId]);
    return res.map((e) => DebtPaymentModel.fromMap(e)).toList();
  }

  Future<void> insertDebtPayment(DebtPaymentModel payment) async {
    final db = await database;
    await db.insert('debt_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- RECURRING TRANSACTIONS ---
  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final db = await database;
    final res = await db.query('recurring_transactions', orderBy: 'nextDueDate ASC');
    return res.map((e) => RecurringTransactionModel.fromMap(e)).toList();
  }

  Future<void> insertRecurringTransaction(RecurringTransactionModel recurring) async {
    final db = await database;
    await db.insert('recurring_transactions', recurring.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRecurringTransaction(RecurringTransactionModel recurring) async {
    final db = await database;
    await db.update('recurring_transactions', recurring.toMap(), where: 'id = ?', whereArgs: [recurring.id]);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> processPendingRecurringTransactions() async {
    final recurringList = await getRecurringTransactions();
    final now = DateTime.now();
    int executedCount = 0;

    for (var r in recurringList) {
      if (!r.isActive) continue;

      if (r.nextDueDate.isBefore(now) || r.nextDueDate.isAtSameMomentAs(now)) {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          title: '${r.title} (Recurring)',
          amount: r.amount,
          type: r.type,
          categoryId: r.categoryId,
          paymentMethod: r.paymentMethod,
          partyName: r.partyName,
          date: r.nextDueDate,
          notes: r.notes ?? 'Auto-generated recurring transaction',
        );
        await insertTransaction(tx);

        final nextDate = r.calculateNextDate(r.nextDueDate);
        final updated = r.copyWith(
          lastExecutedDate: now,
          nextDueDate: nextDate,
        );
        await updateRecurringTransaction(updated);
        executedCount++;
      }
    }
    return executedCount;
  }
}
