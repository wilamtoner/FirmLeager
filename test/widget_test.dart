import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_debt_manager/main.dart';
import 'package:expense_debt_manager/views/home_screen.dart';
import 'package:expense_debt_manager/views/splash_screen.dart';
import 'package:expense_debt_manager/views/add_debt_dialog.dart';
import 'package:expense_debt_manager/views/new_debt_screen.dart';

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

  testWidgets('AddDebtDialog allows toggling No Interest and No Monthly Payment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            splashFactory: InkRipple.splashFactory,
          ),
          home: const Scaffold(
            body: AddDebtDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog title and initial options
    expect(find.text('Add Debt / Loan'), findsOneWidget);
    expect(find.text('No Interest (0% APR)'), findsOneWidget);
    expect(find.text('No Monthly Payment'), findsOneWidget);
    expect(find.text('Interest Rate (APR %)'), findsOneWidget);

    // Toggle No Interest
    final noInterestFinder = find.widgetWithText(SwitchListTile, 'No Interest (0% APR)');
    expect(noInterestFinder, findsOneWidget);
    await tester.ensureVisible(noInterestFinder);
    await tester.tap(noInterestFinder);
    await tester.pumpAndSettle();

    // APR input should now be replaced with 0% APR badge
    expect(find.text('0% APR — Interest-free debt'), findsOneWidget);
    expect(find.text('Interest Rate (APR %)'), findsNothing);

    // Toggle No Monthly Payment
    final noMinFinder = find.widgetWithText(SwitchListTile, 'No Monthly Payment');
    expect(noMinFinder, findsOneWidget);
    await tester.ensureVisible(noMinFinder);
    await tester.tap(noMinFinder);
    await tester.pumpAndSettle();

    // Min payment input replaced with Flexible Payoff badge
    expect(find.text('Flexible Payoff — No fixed monthly installment'), findsOneWidget);
  });

  testWidgets('NewDebtScreen renders full page form and toggles interest terms', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewDebtScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify screen elements
    expect(find.text('New Liability (I Owe)'), findsOneWidget);
    expect(find.text('I Owe (Liability)'), findsOneWidget);
    expect(find.text('Owed to Me (Asset)'), findsOneWidget);
    expect(find.text('Debt / Loan Title*'), findsOneWidget);
    expect(find.text('Lender / Creditor Name*'), findsOneWidget);
    expect(find.text('Save Liability Record'), findsOneWidget);

    // Switch to Asset
    await tester.tap(find.text('Owed to Me (Asset)'));
    await tester.pumpAndSettle();

    expect(find.text('New Asset (Owed to Me)'), findsOneWidget);
    expect(find.text('Borrower / Debtor Name*'), findsOneWidget);
    expect(find.text('Save Asset Record'), findsOneWidget);
  });
}
