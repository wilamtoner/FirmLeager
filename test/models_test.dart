import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/transaction.dart';
import 'package:expense_debt_manager/models/debt.dart';
import 'package:expense_debt_manager/models/category.dart';
import 'package:expense_debt_manager/models/firm_profile.dart';

void main() {
  group('TransactionModel Tests', () {
    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx-123',
        title: 'Office Supplies',
        amount: 1500.50,
        type: TransactionType.expense,
        incomeType: IncomeType.goods,
        paymentMethod: PaymentMethod.bank,
        partyName: 'ABC Stationary',
        categoryId: 'cat-office',
        date: now,
        notes: 'Printer paper & ink cartridges',
      );

      final map = tx.toMap();
      expect(map['id'], 'tx-123');
      expect(map['title'], 'Office Supplies');
      expect(map['amount'], 1500.50);
      expect(map['type'], 'expense');
      expect(map['incomeType'], 'goods');
      expect(map['paymentMethod'], 'bank');
      expect(map['partyName'], 'ABC Stationary');
      expect(map['categoryId'], 'cat-office');
      expect(map['date'], now.toIso8601String());
      expect(map['notes'], 'Printer paper & ink cartridges');

      final deserialized = TransactionModel.fromMap(map);
      expect(deserialized.id, tx.id);
      expect(deserialized.title, tx.title);
      expect(deserialized.amount, tx.amount);
      expect(deserialized.type, TransactionType.expense);
      expect(deserialized.incomeType, IncomeType.goods);
      expect(deserialized.paymentMethod, PaymentMethod.bank);
      expect(deserialized.partyName, 'ABC Stationary');
      expect(deserialized.categoryId, 'cat-office');
      expect(deserialized.notes, 'Printer paper & ink cartridges');
    });

    test('income transaction fromMap preserves type and defaults', () {
      final map = {
        'id': 'tx-456',
        'title': 'Consulting Fee',
        'amount': 5000,
        'type': 'income',
        'incomeType': 'service',
        'paymentMethod': 'bank',
        'partyName': 'Client Corp',
        'categoryId': 'cat-services',
        'date': DateTime.now().toIso8601String(),
        'notes': null,
      };

      final tx = TransactionModel.fromMap(map);
      expect(tx.type, TransactionType.income);
      expect(tx.incomeType, IncomeType.service);
      expect(tx.amount, 5000.0);
      expect(tx.notes, isNull);
    });
  });

  group('DebtModel Tests', () {
    test('toMap and fromMap serialization roundtrip', () {
      final dueDate = DateTime(2026, 12, 31);
      final debt = DebtModel(
        id: 'debt-001',
        title: 'Commercial Bank Loan',
        partyName: 'Nabil Bank',
        isOwedByMe: true,
        originalAmount: 100000.0,
        currentBalance: 75000.0,
        apr: 12.5,
        minMonthlyPayment: 2500.0,
        dueDate: dueDate,
        notes: 'Machinery financing loan',
      );

      final map = debt.toMap();
      expect(map['id'], 'debt-001');
      expect(map['isOwedByMe'], 1);
      expect(map['currentBalance'], 75000.0);

      final deserialized = DebtModel.fromMap(map);
      expect(deserialized.id, debt.id);
      expect(deserialized.partyName, 'Nabil Bank');
      expect(deserialized.isOwedByMe, isTrue);
      expect(deserialized.apr, 12.5);
      expect(deserialized.currentBalance, 75000.0);
    });

    test('debt owed to me converts isOwedByMe to false', () {
      final map = {
        'id': 'debt-002',
        'title': 'Customer Credit',
        'partyName': 'Retailer XYZ',
        'isOwedByMe': 0,
        'originalAmount': 20000,
        'currentBalance': 15000,
        'apr': 0,
        'minMonthlyPayment': 1000,
        'dueDate': DateTime(2026, 6, 30).toIso8601String(),
        'notes': null,
      };

      final debt = DebtModel.fromMap(map);
      expect(debt.isOwedByMe, isFalse);
      expect(debt.currentBalance, 15000.0);
    });

    test('debt fromMap handles boolean isOwedByMe from JSON', () {
      final map = {
        'id': 'debt-002-bool',
        'title': 'Customer Credit',
        'partyName': 'Retailer XYZ',
        'isOwedByMe': true,
        'originalAmount': 20000,
        'currentBalance': 15000,
        'apr': 0,
        'minMonthlyPayment': 1000,
        'dueDate': DateTime(2026, 6, 30).toIso8601String(),
        'notes': null,
      };

      final debt = DebtModel.fromMap(map);
      expect(debt.isOwedByMe, isTrue);
      expect(debt.currentBalance, 15000.0);
    });

    test('copyWith modifies balance correctly', () {
      final debt = DebtModel(
        id: 'debt-003',
        title: 'Supplier Balance',
        partyName: 'Vendor ABC',
        isOwedByMe: true,
        originalAmount: 10000,
        currentBalance: 8000,
        apr: 5.0,
        minMonthlyPayment: 500,
        dueDate: DateTime.now(),
      );

      final updated = debt.copyWith(currentBalance: 6000);
      expect(updated.currentBalance, 6000);
      expect(updated.originalAmount, 10000);
      expect(updated.id, debt.id);
    });

    test('copyWith modifies all optional fields correctly', () {
      final debt = DebtModel(
        id: 'debt-1',
        title: 'Old Title',
        partyName: 'Old Party',
        isOwedByMe: true,
        originalAmount: 1000,
        currentBalance: 800,
        apr: 10.0,
        minMonthlyPayment: 100,
        dueDate: DateTime(2025, 1, 1),
        notes: 'Old note',
      );

      final updated = debt.copyWith(
        title: 'New Title',
        partyName: 'New Party',
        isOwedByMe: false,
        apr: 0.0,
        notes: 'New note',
      );

      expect(updated.title, 'New Title');
      expect(updated.partyName, 'New Party');
      expect(updated.isOwedByMe, false);
      expect(updated.apr, 0.0);
      expect(updated.notes, 'New note');
      expect(updated.originalAmount, 1000);
      expect(updated.currentBalance, 800);
    });
  });

  group('CategoryModel Tests', () {
    test('toMap and fromMap with budget limit', () {
      final cat = CategoryModel(
        id: 'cat-rent',
        name: 'Office Rent',
        colorHex: 0xFF2196F3,
        budgetLimit: 25000.0,
      );

      final map = cat.toMap();
      expect(map['id'], 'cat-rent');
      expect(map['name'], 'Office Rent');
      expect(map['colorHex'], 0xFF2196F3);
      expect(map['budgetLimit'], 25000.0);

      final fromMap = CategoryModel.fromMap(map);
      expect(fromMap.id, cat.id);
      expect(fromMap.name, cat.name);
      expect(fromMap.budgetLimit, 25000.0);
    });
  });

  group('FirmProfileModel Tests', () {
    test('serialization and copyWith', () {
      final profile = FirmProfileModel(
        name: 'Himalayan Enterprises',
        taxId: 'PAN-109283746',
        address: 'Kathmandu, Bagmati',
        phone: '+977-1-4455667',
        currencySymbol: 'Rs.',
      );

      final map = profile.toMap();
      final fromMap = FirmProfileModel.fromMap(map);
      expect(fromMap.name, 'Himalayan Enterprises');
      expect(fromMap.taxId, 'PAN-109283746');
      expect(fromMap.currencySymbol, 'Rs.');

      final updated = fromMap.copyWith(currencySymbol: '\$');
      expect(updated.currencySymbol, '\$');
      expect(updated.name, 'Himalayan Enterprises');
    });

    test('defaults fallback when map values are missing', () {
      final fromMap = FirmProfileModel.fromMap({});
      expect(fromMap.name, 'DEMO FIRM PVT. LTD.');
      expect(fromMap.currencySymbol, 'Rs.');
    });
  });
}
