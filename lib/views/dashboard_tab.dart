import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../utils/csv_exporter.dart';
import '../utils/pdf_invoice_generator.dart';
import 'card_detail_dialog.dart';
import 'currency_converter_screen.dart';
import 'edit_firm_dialog.dart';
import 'new_transaction_screen.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  static const Color darkGreen = Color(0xFF064E3B);
  static const Color emeraldGradientEnd = Color(0xFF047857);

  Future<void> _selectDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _openDetail(DetailCardType type) {
    CardDetailDialog.showMobileBottomSheet(context, type, dateRange: _dateRange);
  }

  Future<void> _exportCsv() async {
    HapticFeedback.lightImpact();
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);

    final file = await CsvExporter.generateTransactionCsv(
      transactions: transactions,
      firm: firm,
      dateRange: _dateRange,
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
    HapticFeedback.lightImpact();
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);

    await PdfInvoiceGenerator.exportAndPrintStatement(
      context: context,
      transactions: transactions,
      firm: firm,
      dateRange: _dateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final debts = ref.watch(debtProvider);
    final firm = ref.watch(firmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions by selected date range (start of start day to end of end day)
    final startDate = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day, 0, 0, 0);
    final endDate = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);

    final filteredTransactions = allTransactions.where((t) {
      return (t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)) &&
          (t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate));
    }).toList();

    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    for (var t in filteredTransactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
      }
    }

    double totalDebtsOwed = 0.0;
    double totalDebtsOwedToMe = 0.0;
    for (var d in debts) {
      if (d.isOwedByMe) {
        totalDebtsOwed += d.currentBalance;
      } else {
        totalDebtsOwedToMe += d.currentBalance;
      }
    }

    final debtsIOweCount = debts.where((d) => d.isOwedByMe && d.currentBalance > 0).length;
    final debtsOwedToMeCount = debts.where((d) => !d.isOwedByMe && d.currentBalance > 0).length;

    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateStr = '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}';
    final symbol = firm.currencySymbol;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mobile Gradient Firm Banner Card
            InkWell(
              onTap: () {
                EditFirmDialog.showMobileBottomSheet(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkGreen, emeraldGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      firm.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            firm.taxId,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${firm.address}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Quick Actions Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton(
                    context,
                    label: 'Income',
                    color: Colors.green.shade700,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const NewTransactionScreen(initialType: TransactionType.income)),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'Expense',
                    color: Colors.red.shade700,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const NewTransactionScreen(initialType: TransactionType.expense)),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'Credit',
                    color: Colors.amber.shade800,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const NewTransactionScreen(initialType: TransactionType.income)),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'CSV',
                    color: Colors.indigo.shade700,
                    onTap: _exportCsv,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'PDF',
                    color: Colors.teal.shade800,
                    onTap: _exportPdf,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'Convert',
                    color: Colors.blueGrey.shade800,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const CurrencyConverterScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Date Range Filter Picker
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: darkGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Text('Change', style: TextStyle(color: darkGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Mobile 2x2 Financial Summary Grid (Date Range Filtered!)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                // Top Left: Income
                _buildStatCard(
                  context,
                  title: 'Income',
                  subtitle: 'Period Total',
                  value: '$symbol ${totalIncome.toStringAsFixed(0)}',
                  badgeColor: Colors.green.shade800,
                  onDetailTap: () => _openDetail(DetailCardType.income),
                ),

                // Top Right: Expense
                _buildStatCard(
                  context,
                  title: 'Expense',
                  subtitle: 'Period Total',
                  value: '$symbol ${totalExpenses.toStringAsFixed(0)}',
                  badgeColor: Colors.orange.shade800,
                  onDetailTap: () => _openDetail(DetailCardType.expense),
                ),

                // Bottom Left: Receivables
                _buildStatCard(
                  context,
                  title: 'Receivables',
                  subtitle: '$debtsOwedToMeCount to collect',
                  value: '$symbol ${totalDebtsOwedToMe.toStringAsFixed(0)}',
                  badgeColor: darkGreen,
                  onDetailTap: () => _openDetail(DetailCardType.receivables),
                ),

                // Bottom Right: Payables
                _buildStatCard(
                  context,
                  title: 'Payables',
                  subtitle: '$debtsIOweCount due',
                  value: '$symbol ${totalDebtsOwed.toStringAsFixed(0)}',
                  badgeColor: Colors.red.shade800,
                  onDetailTap: () => _openDetail(DetailCardType.payables),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Mobile Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _openDetail(DetailCardType.income);
                },
                child: const Text(
                  'View All Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 6. Income vs Expense Pie Chart Section
            Center(
              child: Text(
                'Income vs Expense',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _buildIncomeVsExpensePieChart(totalIncome, totalExpenses),
            const SizedBox(height: 28),

            // 7. Receivables vs Payables Bar Chart Section
            Center(
              child: Text(
                'Receivables vs Payables',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _buildReceivablesVsPayablesBarChart(totalDebtsOwedToMe, totalDebtsOwed),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String value,
    required Color badgeColor,
    required VoidCallback onDetailTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onDetailTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: badgeColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpensePieChart(double income, double expenses) {
    final total = income + expenses;
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Text('No Piechart data available.', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 5, backgroundColor: Colors.lightGreen),
                  SizedBox(width: 4),
                  Text('Income: 0.00%', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  CircleAvatar(radius: 5, backgroundColor: Colors.redAccent),
                  SizedBox(width: 4),
                  Text('Expense: 0.00%', style: TextStyle(fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      );
    }

    final incomePct = (income / total) * 100;
    final expensePct = (expenses / total) * 100;

    return RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: Colors.lightGreen,
                    title: '${incomePct.toStringAsFixed(1)}%',
                    radius: 40,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                  ),
                  PieChartSectionData(
                    value: expenses,
                    color: Colors.redAccent,
                    title: '${expensePct.toStringAsFixed(1)}%',
                    radius: 40,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              swapAnimationDuration: Duration.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 5, backgroundColor: Colors.lightGreen),
              const SizedBox(width: 4),
              Text('Income: ${incomePct.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              const CircleAvatar(radius: 5, backgroundColor: Colors.redAccent),
              const SizedBox(width: 4),
              Text('Expense: ${expensePct.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReceivablesVsPayablesBarChart(double receivables, double payables) {
    final total = receivables + payables;
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text('No Barchart data available.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final maxY = (receivables > payables ? receivables : payables) * 1.2;

    return RepaintBoundary(
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY : 100,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val == 0) return const Text('Receivables', style: TextStyle(fontSize: 11));
                    if (val == 1) return const Text('Payables', style: TextStyle(fontSize: 11));
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(toY: receivables, color: darkGreen, width: 22, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(toY: payables, color: Colors.redAccent, width: 22, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ],
          ),
          swapAnimationDuration: Duration.zero,
        ),
      ),
    );
  }
}
