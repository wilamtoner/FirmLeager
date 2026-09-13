import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../utils/nepali_date_helper.dart';
import '../theme/app_colors.dart';

class DateConverterScreen extends StatefulWidget {
  const DateConverterScreen({super.key});

  @override
  State<DateConverterScreen> createState() => _DateConverterScreenState();
}

class _DateConverterScreenState extends State<DateConverterScreen> {
  static const Color brandNavy = AppColors.primaryDark;
  static const Color brandBlue = AppColors.primaryBlue;
  static const Color darkGreen = brandBlue;
  static const Color emerald = Color(0xFF1D4ED8);

  // Conversion Mode: 0 = AD to BS, 1 = BS to AD
  int _conversionMode = 0;

  // AD state
  DateTime _selectedAdDate = DateTime.now();

  // BS state
  late int _selectedBsYear;
  late int _selectedBsMonth;
  late int _selectedBsDay;

  // Date Difference Calculator State
  DateTime _diffStartDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _diffEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final todayBs = NepaliDateTime.now();
    _selectedBsYear = todayBs.year;
    _selectedBsMonth = todayBs.month;
    _selectedBsDay = todayBs.day;
  }

  void _selectAdDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedAdDate,
      firstDate: DateTime(1944),
      lastDate: DateTime(2043),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: darkGreen,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedAdDate = picked;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _adjustAdDate(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAdDate = _selectedAdDate.add(Duration(days: days));
    });
  }

  void _setToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final nowBs = NepaliDateTime.now();
    setState(() {
      _selectedAdDate = now;
      _selectedBsYear = nowBs.year;
      _selectedBsMonth = nowBs.month;
      _selectedBsDay = nowBs.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nepali Date Converter',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Jump to Today',
            onPressed: _setToday,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mode Switcher (AD to BS vs BS to AD)
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('AD → BS (English to Nepali)', style: TextStyle(fontWeight: FontWeight.w600)),
                    icon: Icon(Icons.swap_horiz),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('BS → AD (Nepali to English)', style: TextStyle(fontWeight: FontWeight.w600)),
                    icon: Icon(Icons.swap_horiz),
                  ),
                ],
                selected: {_conversionMode},
                onSelectionChanged: (set) {
                  HapticFeedback.selectionClick();
                  setState(() => _conversionMode = set.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return darkGreen;
                    }
                    return isDark ? Colors.grey.shade900 : Colors.grey.shade100;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? Colors.white70 : Colors.black87;
                  }),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Active Conversion Panel
              if (_conversionMode == 0) _buildAdToBsPanel(cardBg, borderColor, isDark)
              else _buildBsToAdPanel(cardBg, borderColor, isDark),

              const SizedBox(height: 24),

              // 3. Date Difference & Duration Calculator
              _buildDifferenceCalculator(cardBg, borderColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdToBsPanel(Color cardBg, Color borderColor, bool isDark) {
    final bsDetails = NepaliDateHelper.convertAdToBs(_selectedAdDate);
    final adFormatted = DateFormat('yyyy-MM-dd (EEEE, MMMM d, yyyy)').format(_selectedAdDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input Card: AD Date
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT ENGLISH (AD) DATE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectAdDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: darkGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: darkGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          adFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      const Icon(Icons.edit_calendar, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Quick jump chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildJumpChip('Today', _setToday),
                    _buildJumpChip('-1 Day', () => _adjustAdDate(-1)),
                    _buildJumpChip('+1 Day', () => _adjustAdDate(1)),
                    _buildJumpChip('+7 Days', () => _adjustAdDate(7)),
                    _buildJumpChip('+30 Days', () => _adjustAdDate(30)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result Card: Nepali (BS) Output
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [darkGreen, emerald],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEPALI (BIKRAM SAMBAT)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                    tooltip: 'Copy Nepali Date',
                    onPressed: () => _copyToClipboard(bsDetails.formattedNp, 'Nepali date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Big Devanagari Date
              Text(
                bsDetails.formattedNp,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              // English script
              Text(
                bsDetails.formattedEn,
                style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResultMeta('ISO Format', '${bsDetails.isoFormat} BS'),
                  _buildResultMeta('Month', '${bsDetails.monthNameEn} (${bsDetails.monthNameNp})'),
                  _buildResultMeta('Day', '${bsDetails.dayNameEn} (${bsDetails.dayNameNp})'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBsToAdPanel(Color cardBg, Color borderColor, bool isDark) {
    final maxDays = NepaliDateHelper.getDaysInBsMonth(_selectedBsYear, _selectedBsMonth);
    if (_selectedBsDay > maxDays) {
      _selectedBsDay = maxDays;
    }

    final bsDetails = NepaliDateHelper.convertBsToAd(_selectedBsYear, _selectedBsMonth, _selectedBsDay);
    final adFormatted = DateFormat('yyyy-MM-dd (EEEE, MMMM d, yyyy)').format(bsDetails.adEquivalent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input Card: BS Selectors (Year, Month, Day)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT NEPALI (BS) DATE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Year Dropdown
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Year', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          key: ValueKey('bs-year-$_selectedBsYear'),
                          initialValue: _selectedBsYear,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          items: List.generate(100, (i) => 2000 + i).map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text('$y', style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final newMax = NepaliDateHelper.getDaysInBsMonth(val, _selectedBsMonth);
                              setState(() {
                                _selectedBsYear = val;
                                if (_selectedBsDay > newMax) _selectedBsDay = newMax;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Month Dropdown
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Month', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          key: ValueKey('bs-month-$_selectedBsMonth'),
                          initialValue: _selectedBsMonth,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          items: List.generate(12, (i) => i + 1).map((m) {
                            final name = NepaliDateHelper.bsMonthsEn[m - 1];
                            final nameNp = NepaliDateHelper.bsMonthsNp[m - 1];
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text('$name ($nameNp)', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final newMax = NepaliDateHelper.getDaysInBsMonth(_selectedBsYear, val);
                              setState(() {
                                _selectedBsMonth = val;
                                if (_selectedBsDay > newMax) _selectedBsDay = newMax;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Day Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          key: ValueKey('bs-day-$_selectedBsDay-$maxDays'),
                          initialValue: _selectedBsDay.clamp(1, maxDays),
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          items: List.generate(maxDays, (i) => i + 1).map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d', style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBsDay = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildJumpChip('Set to Today (BS)', _setToday),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result Card: English (AD) Output
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [darkGreen, emerald],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ENGLISH (GREGORIAN - AD)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                    tooltip: 'Copy English Date',
                    onPressed: () => _copyToClipboard(adFormatted, 'English date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                adFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.4,
                ),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResultMeta('ISO Format', '${DateFormat("yyyy-MM-dd").format(bsDetails.adEquivalent)} AD'),
                  _buildResultMeta('Bikram Sambat', '${bsDetails.isoFormat} BS'),
                  _buildResultMeta('Nepali Month', bsDetails.monthNameNp),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifferenceCalculator(Color cardBg, Color borderColor, bool isDark) {
    final diff = NepaliDateHelper.calculateDifference(_diffStartDate, _diffEndDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Date Difference & Age Calculator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDatePickTile(
                  label: 'Start Date',
                  date: _diffStartDate,
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _diffStartDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2050),
                    );
                    if (p != null && mounted) setState(() => _diffStartDate = p);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDatePickTile(
                  label: 'End Date',
                  date: _diffEndDate,
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _diffEndDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2050),
                    );
                    if (p != null && mounted) setState(() => _diffEndDate = p);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diff.summary,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Duration: ${diff.totalDays} days',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildResultMeta(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
