import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_debt_manager/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('FirmLedger ExpenseDebtApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseDebtApp(),
      ),
    );

    // Initial frame rendered
    await tester.pump();

    // Verify app title or core elements exist
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
