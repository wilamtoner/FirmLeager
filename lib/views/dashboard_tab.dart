import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../utils/formatters.dart';
import '../utils/csv_exporter.dart';
import '../utils/pdf_invoice_generator.dart';
import 'card_detail_dialog.dart';
import 'currency_converter_screen.dart';
import 'date_converter_screen.dart';
import 'edit_firm_dialog.dart';
import 'gold_silver_screen.dart';
import 'new_transaction_screen.dart';
import '../providers/gold_silver_provider.dart';
import '../utils/nepali_date_helper.dart';
import '../theme/app_colors.dart';

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
  String _selectedTrendMode = 'income_expense';

  static const Color brandNavy = AppColors.primaryDark;
  static const Color brandBlue = AppColors.primaryBlue;
  static const Color blueGradientEnd = Color(0xFF1D4ED8);
  // Alias darkGreen for backwards compatibility
  static const Color darkGreen = brandBlue;

  Future<void> _selectDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked != null && mounted) {
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

    try {
      await CsvExporter.shareTransactionCsv(
        transactions: transactions,
        firm: firm,
        dateRange: _dateRange,
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
    HapticFeedback.lightImpact();
    final transactions = ref.read(transactionProvider);
    final firm = ref.read(firmProvider);

    try {
      await PdfInvoiceGenerator.exportAndPrintStatement(
        context: context,
        transactions: transactions,
        firm: firm,
        dateRange: _dateRange,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final debts = ref.watch(debtProvider);
    final firm = ref.watch(firmProvider);
    final goldState = ref.watch(goldSilverProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayBsDetails = NepaliDateHelper.convertAdToBs(DateTime.now());
    final goldTolaRate = goldState.getRate('gold', '1 tola');
    final silverTolaRate = goldState.getRate('silver', '1 tola');

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
                    colors: [brandNavy, blueGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: brandNavy.withValues(alpha: 0.35),
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
                        MaterialPageRoute(
                          builder: (ctx) => const NewTransactionScreen(
                            initialType: TransactionType.expense,
                            initialMethod: PaymentMethod.credit,
                          ),
                        ),
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
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'Date BS',
                    color: Colors.deepPurple.shade700,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const DateConverterScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    context,
                    label: 'Gold/Silver',
                    color: Colors.amber.shade900,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const GoldSilverScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2b. Live Nepal Market & BS Calendar Ticker Strip
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const GoldSilverScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.amber.shade50.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                todayBsDetails.formattedNp,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: goldState.isLive ? Colors.green.shade600 : Colors.grey.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  goldState.isLive ? 'LIVE' : 'OFFLINE',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goldTolaRate != null && silverTolaRate != null
                                ? 'Fine Gold: Rs. ${goldTolaRate.todayRate.toStringAsFixed(0)}/tola • Silver: Rs. ${silverTolaRate.todayRate.toStringAsFixed(0)}/tola'
                                : 'Tap to view live Nepal Gold & Silver prices',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade500),
                  ],
                ),
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

            // 5. Secondary Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkGreen,
                  side: const BorderSide(color: darkGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _openDetail(DetailCardType.income);
                },
                child: const Text(
                  'View All Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

            // 7. Financial Trend Line Graph Section
            _buildFinancialTrendLineChart(
              transactions: filteredTransactions,
              debts: debts,
              currencySymbol: symbol,
              dateRange: _dateRange,
              isDark: isDark,
            ),
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
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: Colors.lightGreen,
                    showTitle: false,
                    radius: 36,
                  ),
                  PieChartSectionData(
                    value: expenses,
                    color: Colors.redAccent,
                    showTitle: false,
                    radius: 36,
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

  Widget _buildFinancialTrendLineChart({
    required List<TransactionModel> transactions,
    required List<DebtModel> debts,
    required String currencySymbol,
    required DateTimeRange dateRange,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final textMuted = isDark ? Colors.white60 : Colors.black54;

    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
    final int rawDays = end.difference(start).inDays + 1;
    final int totalDays = rawDays < 2 ? 2 : rawDays;

    // 1. Calculate Spots based on selected mode
    List<FlSpot> primarySpots = [];
    List<FlSpot> secondarySpots = [];
    String primaryLabel = '';
    String secondaryLabel = '';
    Color primaryColor = const Color(0xFF059669);
    Color secondaryColor = const Color(0xFFEF4444);
    double totalPrimary = 0.0;
    double totalSecondary = 0.0;

    if (_selectedTrendMode == 'net_flow') {
      primaryLabel = 'Net Cash Flow';
      primaryColor = const Color(0xFF10B981);
      double runningNet = 0.0;
      for (int i = 0; i < totalDays; i++) {
        final day = start.add(Duration(days: i));
        double dayIncome = 0;
        double dayExpense = 0;
        for (final t in transactions) {
          if (t.date.year == day.year && t.date.month == day.month && t.date.day == day.day) {
            if (t.type == TransactionType.income) {
              dayIncome += t.amount;
            } else {
              dayExpense += t.amount;
            }
          }
        }
        runningNet += (dayIncome - dayExpense);
        primarySpots.add(FlSpot(i.toDouble(), runningNet));
      }
      totalPrimary = runningNet;
    } else if (_selectedTrendMode == 'debts') {
      primaryLabel = 'Receivables';
      secondaryLabel = 'Payables';
      primaryColor = darkGreen;
      secondaryColor = const Color(0xFFEF4444);

      double totalReceivables = 0.0;
      double totalPayables = 0.0;
      for (final d in debts) {
        if (!d.isOwedByMe) {
          totalReceivables += d.currentBalance;
        } else {
          totalPayables += d.currentBalance;
        }
      }
      totalPrimary = totalReceivables;
      totalSecondary = totalPayables;

      for (int i = 0; i < totalDays; i++) {
        primarySpots.add(FlSpot(i.toDouble(), totalReceivables));
        secondarySpots.add(FlSpot(i.toDouble(), totalPayables));
      }
    } else {
      // Default: 'income_expense'
      primaryLabel = 'Income';
      secondaryLabel = 'Expense';
      primaryColor = const Color(0xFF059669);
      secondaryColor = const Color(0xFFEF4444);

      for (int i = 0; i < totalDays; i++) {
        final day = start.add(Duration(days: i));
        double dayIncome = 0;
        double dayExpense = 0;
        for (final t in transactions) {
          if (t.date.year == day.year && t.date.month == day.month && t.date.day == day.day) {
            if (t.type == TransactionType.income) {
              dayIncome += t.amount;
            } else {
              dayExpense += t.amount;
            }
          }
        }
        totalPrimary += dayIncome;
        totalSecondary += dayExpense;
        primarySpots.add(FlSpot(i.toDouble(), dayIncome));
        secondarySpots.add(FlSpot(i.toDouble(), dayExpense));
      }
    }

    // Determine min and max Y values
    double computedMaxY = 0;
    double computedMinY = 0;
    for (final s in primarySpots) {
      if (s.y > computedMaxY) computedMaxY = s.y;
      if (s.y < computedMinY) computedMinY = s.y;
    }
    for (final s in secondarySpots) {
      if (s.y > computedMaxY) computedMaxY = s.y;
      if (s.y < computedMinY) computedMinY = s.y;
    }

    if (computedMaxY == 0 && computedMinY == 0) {
      computedMaxY = 100;
    } else if (computedMaxY == computedMinY) {
      computedMaxY = computedMaxY > 0 ? computedMaxY * 1.3 : 100;
      computedMinY = computedMinY > 0 ? 0 : computedMinY * 1.3;
    } else {
      final span = computedMaxY - computedMinY;
      computedMaxY += span * 0.15;
      if (computedMinY > 0 && computedMinY < computedMaxY * 0.3) {
        computedMinY = 0;
      } else if (computedMinY < 0) {
        computedMinY -= span * 0.1;
      }
    }

    // Interval for bottom axis labels
    double bottomInterval = 1;
    if (totalDays > 24) {
      bottomInterval = (totalDays / 4).ceilToDouble();
    } else if (totalDays > 12) {
      bottomInterval = (totalDays / 5).ceilToDouble();
    } else if (totalDays > 6) {
      bottomInterval = 2;
    }

    final lineBarsData = <LineChartBarData>[
      LineChartBarData(
        spots: primarySpots,
        isCurved: totalDays > 2,
        curveSmoothness: 0.3,
        color: primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: totalDays <= 14,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3.5,
            color: primaryColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.22),
              primaryColor.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      if (secondarySpots.isNotEmpty)
        LineChartBarData(
          spots: secondarySpots,
          isCurved: totalDays > 2,
          curveSmoothness: 0.3,
          color: secondaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: totalDays <= 14,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3.5,
              color: secondaryColor,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                secondaryColor.withValues(alpha: 0.20),
                secondaryColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.show_chart, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Financial Trend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              // Compact Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTrendModeChip('income_expense', 'Trend', isDark),
                    _buildTrendModeChip('net_flow', 'Net', isDark),
                    _buildTrendModeChip('debts', 'Debts', isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Chart View
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => isDark ? const Color(0xFF0F172A) : Colors.black87,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dayIndex = spot.x.toInt();
                        final spotDate = start.add(Duration(days: dayIndex));
                        final dateTitle = DateFormat('MMM d').format(spotDate);
                        final isFirst = spot.barIndex == 0;
                        final label = isFirst ? primaryLabel : secondaryLabel;
                        return LineTooltipItem(
                          '$dateTitle\n$label: ${Formatters.currency(spot.y, currencySymbol)}',
                          TextStyle(
                            color: isFirst ? primaryColor : secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: computedMaxY > computedMinY ? (computedMaxY - computedMinY) / 3 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) {
                        if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                        return Text(
                          _formatCompactAxisNumber(val),
                          style: TextStyle(fontSize: 10, color: textMuted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: bottomInterval,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= totalDays) return const SizedBox.shrink();
                        final d = start.add(Duration(days: idx));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MMM d').format(d),
                            style: TextStyle(fontSize: 10, color: textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (totalDays - 1).toDouble(),
                minY: computedMinY,
                maxY: computedMaxY,
                lineBarsData: lineBarsData,
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Legend & Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(primaryLabel, totalPrimary, primaryColor, currencySymbol, isDark),
              if (secondarySpots.isNotEmpty)
                _buildLegendItem(secondaryLabel, totalSecondary, secondaryColor, currencySymbol, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendModeChip(String mode, String label, bool isDark) {
    final isSelected = _selectedTrendMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTrendMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? darkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color, String symbol, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
        ),
        Text(
          Formatters.currency(amount, symbol),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  String _formatCompactAxisNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
