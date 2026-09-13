import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gold_silver_provider.dart';
import '../services/gold_silver_service.dart';
import '../utils/formatters.dart';
import '../theme/app_colors.dart';

class GoldSilverScreen extends ConsumerStatefulWidget {
  const GoldSilverScreen({super.key});

  @override
  ConsumerState<GoldSilverScreen> createState() => _GoldSilverScreenState();
}

class _GoldSilverScreenState extends ConsumerState<GoldSilverScreen> {
  static const Color brandNavy = AppColors.primaryDark;
  static const Color brandBlue = AppColors.primaryBlue;
  static const Color darkGreen = brandBlue;

  // Unit toggle: '1 tola' vs '10 gram'
  String _selectedUnit = '1 tola';

  // Calculator State
  String _calcMetal = 'gold'; // 'gold' or 'silver'
  String _calcWeightUnit = 'tola'; // 'tola', 'gram', 'lal'
  final TextEditingController _quantityController = TextEditingController(text: '1.0');
  final TextEditingController _makingChargesController = TextEditingController(text: '0');
  final TextEditingController _wastageController = TextEditingController(text: '0');

  @override
  void dispose() {
    _quantityController.dispose();
    _makingChargesController.dispose();
    _wastageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goldSilverProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    final goldRate = state.getRate('gold', _selectedUnit);
    final silverRate = state.getRate('silver', _selectedUnit);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Gold & Silver Nepal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh FENEGOSIDA Rates',
            onPressed: state.isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref.read(goldSilverProvider.notifier).refresh();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Market Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: state.isLive
                      ? (isDark ? const Color(0xFF052E16) : Colors.green.shade50)
                      : (isDark ? const Color(0xFF451A03) : Colors.amber.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isLive ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: state.isLive ? Colors.green : Colors.amber.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isLive ? 'FENEGOSIDA Official Live Rates' : 'Offline Reference Rates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: state.isLive ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            'Last updated: ${DateFormat("MMM dd, yyyy • hh:mm a").format(state.lastUpdated)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Unit Switcher (1 Tola vs 10 Gram)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: '1 tola',
                    label: Text('Per 1 Tola (11.66g)', style: TextStyle(fontWeight: FontWeight.w600)),
                    icon: Icon(Icons.scale),
                  ),
                  ButtonSegment<String>(
                    value: '10 gram',
                    label: Text('Per 10 Grams', style: TextStyle(fontWeight: FontWeight.w600)),
                    icon: Icon(Icons.fitness_center),
                  ),
                ],
                selected: {_selectedUnit},
                onSelectionChanged: (set) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedUnit = set.first);
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

              // 3. Gold Card
              if (goldRate != null)
                _buildMetalCard(
                  title: 'Fine Gold (छापावाल सुन)',
                  subTitle: '24 Karat 9999 Pure Gold • ${_selectedUnit == "1 tola" ? "1 Tola" : "10 Grams"}',
                  rate: goldRate,
                  gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFB45309)],
                  icon: Icons.workspace_premium,
                ),
              const SizedBox(height: 14),

              // 4. Silver Card
              if (silverRate != null)
                _buildMetalCard(
                  title: 'Pure Silver (असली चाँदी दर)',
                  subTitle: 'Fine Silver • ${_selectedUnit == "1 tola" ? "1 Tola" : "10 Grams"}',
                  rate: silverRate,
                  gradientColors: const [Color(0xFF475569), Color(0xFF64748B), Color(0xFF334155)],
                  icon: Icons.monetization_on_outlined,
                ),

              const SizedBox(height: 24),

              // 5. Bullion Value Calculator
              _buildBullionCalculator(cardBg, borderColor, isDark, state),

              const SizedBox(height: 16),

              // 6. Nepali Unit Standards Reference Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Nepal Bullion Measurement Standards',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• 1 Tola = 11.6638 Grams = 100 Lal (लाल)\n'
                      '• 1 Lal = 0.1166 Grams\n'
                      '• Rates governed by Federation of Nepal Gold and Silver Dealers\' Association (FENEGOSIDA).',
                      style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetalCard({
    required String title,
    required String subTitle,
    required dynamic rate,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    final double change = rate.changeAmount;
    final double changePct = rate.changePercent;
    final bool isPositive = change > 0;
    final bool isZero = change == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Daily change badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isZero
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isPositive
                          ? Colors.green.shade800.withValues(alpha: 0.85)
                          : Colors.red.shade800.withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isZero ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isPositive ? "+" : isZero ? "" : "-"}Rs. ${change.abs().toStringAsFixed(0)} (${changePct.abs().toStringAsFixed(2)}%)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Price
          Text(
            Formatters.currency(rate.todayRate, 'Rs.'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yesterday: ${Formatters.currency(rate.yesterdayRate, 'Rs.')}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Unit: ${rate.unit}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBullionCalculator(Color cardBg, Color borderColor, bool isDark, dynamic state) {
    final goldTolaRate = state.getRate('gold', '1 tola')?.todayRate ?? 302200.0;
    final silverTolaRate = state.getRate('silver', '1 tola')?.todayRate ?? 4660.0;

    final double activeTolaRate = (_calcMetal == 'gold') ? goldTolaRate : silverTolaRate;

    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double makingCharges = double.tryParse(_makingChargesController.text) ?? 0.0;
    final double wastagePercent = double.tryParse(_wastageController.text) ?? 0.0;

    final double grandTotal = GoldSilverService.calculateTotal(
      ratePerTola: activeTolaRate,
      quantity: quantity,
      unit: _calcWeightUnit,
      makingCharges: makingCharges,
      wastagePercent: wastagePercent,
    );

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
              Icon(Icons.calculate_outlined, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Bullion Value Calculator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metal Selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'gold', label: Text('Gold (सुन)'), icon: Icon(Icons.circle, color: Colors.amber)),
              ButtonSegment<String>(value: 'silver', label: Text('Silver (चाँदी)'), icon: Icon(Icons.circle, color: Colors.blueGrey)),
            ],
            selected: {_calcMetal},
            onSelectionChanged: (set) {
              HapticFeedback.selectionClick();
              setState(() => _calcMetal = set.first);
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
          const SizedBox(height: 14),

          // Weight Unit & Quantity
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight / Quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _calcWeightUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tola', child: Text('Tola (तोला)')),
                    DropdownMenuItem(value: 'gram', child: Text('Grams (ग्राम)')),
                    DropdownMenuItem(value: 'lal', child: Text('Lal (लाल)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _calcWeightUnit = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Making & Wastage
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _makingChargesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Making Fee (Rs.)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _wastageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Wastage / जर्ती (%)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grand Total Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED TOTAL MARKET VALUE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.7, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(grandTotal, 'Rs.'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${Formatters.currency(activeTolaRate, 'Rs.')} / Tola',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
