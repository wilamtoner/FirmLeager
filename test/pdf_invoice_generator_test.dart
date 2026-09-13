import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/transaction.dart';
import 'package:expense_debt_manager/models/firm_profile.dart';
import 'package:expense_debt_manager/utils/pdf_invoice_generator.dart';

void main() {
  group('PdfInvoiceGenerator Tests', () {
    test('sanitizeText replaces currency unicode glyphs with ASCII codes', () {
      expect(PdfInvoiceGenerator.sanitizeText('Price is €50 and £20 and ₹100'), equals('Price is EUR 50 and GBP 20 and Rs. 100'));
      expect(PdfInvoiceGenerator.sanitizeCurrency('€'), equals('EUR'));
      expect(PdfInvoiceGenerator.sanitizeCurrency('£'), equals('GBP'));
      expect(PdfInvoiceGenerator.sanitizeCurrency('₹'), equals('Rs.'));
      expect(PdfInvoiceGenerator.sanitizeCurrency('\$'), equals('\$'));
    });

    test('buildStatementDocument creates valid PDF Document without exceptions', () async {
      final firm = FirmProfileModel(
        name: 'ACME Super Traders €',
        taxId: 'PAN-123456789',
        address: 'Kathmandu / Munich',
        phone: '+977-9800000000',
        currencySymbol: '€',
      );

      final t1 = TransactionModel(
        id: 'tx-1',
        title: 'Office Stationary 📝',
        partyName: 'Stationery Supplier 🏢',
        amount: 1500,
        type: TransactionType.expense,
        categoryId: 'cat_office',
        date: DateTime(2026, 9, 10),
      );

      final t2 = TransactionModel(
        id: 'tx-2',
        title: 'Consulting Retainer 💼',
        partyName: 'Global Client',
        amount: 8500,
        type: TransactionType.income,
        categoryId: 'cat_income',
        date: DateTime(2026, 9, 11),
      );

      final doc = PdfInvoiceGenerator.buildStatementDocument(
        transactions: [t1, t2],
        firm: firm,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
      );

      // Verify that the PDF document compiles and saves to bytes cleanly
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('buildStatementDocument handles empty transactions cleanly', () async {
      final firm = FirmProfileModel(
        name: 'Empty Books Corp',
        taxId: 'PAN-000',
        address: 'Null Island',
        phone: '000',
      );

      final doc = PdfInvoiceGenerator.buildStatementDocument(
        transactions: [],
        firm: firm,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });
}
