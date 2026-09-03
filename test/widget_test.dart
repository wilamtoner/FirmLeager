import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_debt_manager/main.dart';
import 'package:expense_debt_manager/views/home_screen.dart';
import 'package:expense_debt_manager/views/splash_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('FirmLedger ExpenseDebtApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseDebtApp(home: HomeScreen()),
      ),
    );

    // Initial frame rendered
    await tester.pump();

    // Verify app title or core elements exist
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('FirmLedger'), findsWidgets);
  });

  testWidgets('SplashScreen renders animated logo and transitions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            duration: Duration(milliseconds: 100),
            nextScreen: Scaffold(body: Text('Destination Screen')),
          ),
        ),
      ),
    );

    // Verify initial splash state
    expect(find.text('FirmLedger'), findsOneWidget);
    expect(find.text('Small Business Accounting & Debt Engine'), findsOneWidget);

    // Advance timer past duration
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Verify successful transition
    expect(find.text('Destination Screen'), findsOneWidget);
  });
}
