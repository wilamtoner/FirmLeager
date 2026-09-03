import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_tab.dart';
import 'expense_tab.dart';
import 'debt_tab.dart';
import 'debt_payoff_screen.dart';
import 'edit_firm_dialog.dart';
import '../providers/transaction_provider.dart';
import '../providers/firm_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/csv_exporter.dart';
import '../utils/pdf_invoice_generator.dart';
import '../utils/backup_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    ExpenseTab(),
    DebtTab(),
    DebtPayoffScreen(),
  ];

  static const Color darkGreen = Color(0xFF064E3B);

  Future<void> _exportCsv() async {
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);
    final dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final file = await CsvExporter.generateTransactionCsv(
      transactions: transactions,
      firm: firm,
      dateRange: dateRange,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV Statement Exported: ${file.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);
    final dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    await PdfInvoiceGenerator.exportAndPrintStatement(
      context: context,
      transactions: transactions,
      firm: firm,
      dateRange: dateRange,
    );
  }

  Future<void> _backupData() async {
    try {
      final file = await BackupService.createBackupFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full Backup Saved: ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = (themeMode == ThemeMode.dark);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => const Icon(Icons.account_balance_wallet, size: 24),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FirmLedger',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Dark / Light Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, color: Colors.white),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          // CSV Statement Export
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            tooltip: 'Export CSV Statement',
            onPressed: _exportCsv,
          ),
          // PDF Statement Export
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            tooltip: 'Export PDF Statement',
            onPressed: _exportPdf,
          ),
          // JSON Database Backup
          IconButton(
            icon: const Icon(Icons.backup_outlined, color: Colors.white),
            tooltip: 'Backup Database (JSON)',
            onPressed: _backupData,
          ),
          // Edit Firm Details Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  EditFirmDialog.showMobileBottomSheet(context);
                },
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Ledger'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Strategy'),
        ],
      ),
    );
  }
}
