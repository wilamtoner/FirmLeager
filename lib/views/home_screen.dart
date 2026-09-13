import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_tab.dart';
import 'date_converter_screen.dart';
import 'expense_tab.dart';
import 'debt_tab.dart';
import 'edit_firm_dialog.dart';
import 'gold_silver_screen.dart';
import '../providers/transaction_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/category_provider.dart';
import '../providers/firm_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/csv_exporter.dart';
import '../utils/pdf_invoice_generator.dart';
import '../utils/backup_service.dart';
import '../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const Color brandPrimary = AppColors.primaryDark;
  // Keep darkGreen as alias for backward compatibility
  static const Color darkGreen = brandPrimary;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    ExpenseTab(),
    DebtTab(),
  ];

  static const Color darkGreen = HomeScreen.brandPrimary;

  @override
  void initState() {
    super.initState();
    // Automatically process any pending recurring transactions upon app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringProvider.notifier).checkAndProcessDue();
    });
  }

  Future<void> _exportCsv() async {
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);
    final dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    try {
      await CsvExporter.shareTransactionCsv(
        transactions: transactions,
        firm: firm,
        dateRange: dateRange,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);
    final dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    try {
      await PdfInvoiceGenerator.exportAndPrintStatement(
        context: context,
        transactions: transactions,
        firm: firm,
        dateRange: dateRange,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  Future<void> _backupData() async {
    try {
      await BackupService.shareBackupFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _restoreData() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup (JSON)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your FirmLedger backup JSON below to restore categories, transactions, and debt records.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '{"appName": "FirmLedger", ...}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final results = await BackupService.restoreFromJson(text);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  ref.read(transactionProvider.notifier).loadTransactions();
                  ref.read(debtProvider.notifier).loadDebts();
                  ref.read(categoryProvider.notifier).loadCategories();
                  ref.read(recurringProvider.notifier).loadRecurring();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restored ${results['transactions']} transactions, ${results['debts']} debts, ${results['categories']} categories.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
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
          if (MediaQuery.of(context).size.width >= 600) ...[
            // Desktop/Tablet Toolbar
            IconButton(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
              tooltip: 'Export CSV Statement',
              onPressed: _exportCsv,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              tooltip: 'Export PDF Statement',
              onPressed: _exportPdf,
            ),
            IconButton(
              icon: const Icon(Icons.backup_outlined, color: Colors.white),
              tooltip: 'Backup Database (JSON)',
              onPressed: _backupData,
            ),
            IconButton(
              icon: const Icon(Icons.settings_backup_restore, color: Colors.white),
              tooltip: 'Restore Database (JSON)',
              onPressed: _restoreData,
            ),
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
            ),
          ] else ...[
            // Mobile Overflow Popup Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: 'More actions',
              onSelected: (val) {
                switch (val) {
                  case 'edit':
                    EditFirmDialog.showMobileBottomSheet(context);
                    break;
                  case 'pdf':
                    _exportPdf();
                    break;
                  case 'csv':
                    _exportCsv();
                    break;
                  case 'backup':
                    _backupData();
                    break;
                  case 'restore':
                    _restoreData();
                    break;
                  case 'date_converter':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const DateConverterScreen()),
                    );
                    break;
                  case 'gold_silver':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const GoldSilverScreen()),
                    );
                    break;
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Firm Info'),
                ),
                PopupMenuItem(
                  value: 'gold_silver',
                  child: Text('Gold & Silver Rates (NP)'),
                ),
                PopupMenuItem(
                  value: 'date_converter',
                  child: Text('Nepali Date Converter'),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Text('Export PDF Statement'),
                ),
                PopupMenuItem(
                  value: 'csv',
                  child: Text('Export CSV File'),
                ),
                PopupMenuItem(
                  value: 'backup',
                  child: Text('Backup Database'),
                ),
                PopupMenuItem(
                  value: 'restore',
                  child: Text('Restore from Backup'),
                ),
              ],
            ),
          ],
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
        ],
      ),
    );
  }
}
