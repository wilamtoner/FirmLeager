import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';
import '../services/currency_service.dart';
import '../utils/formatters.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(currencyConverterProvider);
    _amountController = TextEditingController(
      text: state.inputAmount == 0 ? '100' : state.inputAmount.toStringAsFixed(0),
    );
    if (state.inputAmount == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currencyConverterProvider.notifier).setAmount(100.0);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickAmount(double amount) {
    HapticFeedback.selectionClick();
    _amountController.text = amount.toStringAsFixed(0);
    ref.read(currencyConverterProvider.notifier).setAmount(amount);
  }

  void _applyPair(String from, String to) {
    HapticFeedback.selectionClick();
    ref.read(currencyConverterProvider.notifier).setFromCurrency(from);
    ref.read(currencyConverterProvider.notifier).setToCurrency(to);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currencyConverterProvider);
    final notifier = ref.read(currencyConverterProvider.notifier);
    final fromInfo = CurrencyService.getInfo(state.fromCurrency);
    final toInfo = CurrencyService.getInfo(state.toCurrency);

    // Calculate unit exchange rate (1 Source = X Target)
    final service = ref.read(currencyServiceProvider);
    final unitRate = service.convert(amount: 1.0, from: state.fromCurrency, to: state.toCurrency);
    final inverseRate = service.convert(amount: 1.0, from: state.toCurrency, to: state.fromCurrency);

    const darkGreen = Color(0xFF064E3B);
    const emerald = Color(0xFF047857);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('💱', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Live Currency Converter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: darkGreen,
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
            tooltip: 'Refresh live market rates',
            onPressed: state.isLoading ? null : () => notifier.refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Market Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: state.isLive ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isLive ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: state.isLive ? Colors.green.shade700 : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.isLive
                            ? 'Real-Time Market Rates Active • ${state.lastUpdated != null ? Formatters.date(state.lastUpdated!) : "Live"}'
                            : 'Offline Cached Rates • Connect to internet to sync latest rates',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isLive ? Colors.green.shade900 : Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Input Amount Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AMOUNT TO CONVERT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Center(
                              widthFactor: 1,
                              child: Text(fromInfo.flagEmoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          suffixText: state.fromCurrency,
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          notifier.setAmount(parsed);
                        },
                      ),
                      const SizedBox(height: 10),
                      // Quick Amount Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [10.0, 50.0, 100.0, 500.0, 1000.0, 5000.0].map((amt) {
                            final isSelected = (state.inputAmount == amt);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text('${fromInfo.symbol}${amt.toInt()}'),
                                selected: isSelected,
                                onSelected: (_) => _applyQuickAmount(amt),
                                selectedColor: darkGreen,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Currency Selector & Swap Row
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('from_${state.fromCurrency}'),
                              initialValue: state.fromCurrency,
                              decoration: InputDecoration(
                                labelText: 'From',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: CurrencyService.supportedCurrencies.map((c) {
                                return DropdownMenuItem(
                                  value: c.code,
                                  child: Text(
                                    '${c.flagEmoji} ${c.code} - ${c.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) notifier.setFromCurrency(val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: darkGreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              notifier.swap();
                            },
                            icon: const Icon(Icons.swap_horiz, size: 24),
                            tooltip: 'Swap Currencies',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('to_${state.toCurrency}'),
                              initialValue: state.toCurrency,
                              decoration: InputDecoration(
                                labelText: 'To',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: CurrencyService.supportedCurrencies.map((c) {
                                return DropdownMenuItem(
                                  value: c.code,
                                  child: Text(
                                    '${c.flagEmoji} ${c.code} - ${c.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) notifier.setToCurrency(val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Popular Currency Pair Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            {'from': 'USD', 'to': 'NPR'},
                            {'from': 'INR', 'to': 'NPR'},
                            {'from': 'EUR', 'to': 'USD'},
                            {'from': 'GBP', 'to': 'USD'},
                            {'from': 'AUD', 'to': 'USD'},
                            {'from': 'USD', 'to': 'INR'},
                          ].map((pair) {
                            final isPairActive =
                                (state.fromCurrency == pair['from'] && state.toCurrency == pair['to']);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                label: Text('${pair['from']} ⇄ ${pair['to']}'),
                                backgroundColor: isPairActive ? darkGreen.withValues(alpha: 0.15) : null,
                                side: isPairActive ? const BorderSide(color: darkGreen, width: 1.5) : null,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isPairActive ? FontWeight.bold : FontWeight.normal,
                                  color: isPairActive ? darkGreen : null,
                                ),
                                onPressed: () => _applyPair(pair['from']!, pair['to']!),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Converted Result Display Card (Emerald Gradient)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkGreen, emerald],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CONVERTED ESTIMATE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1 ${state.fromCurrency} = ${unitRate.toStringAsFixed(4)} ${state.toCurrency}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${toInfo.symbol} ${Formatters.number(state.convertedAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${state.inputAmount.toStringAsFixed(2)} ${fromInfo.name} = ${state.convertedAmount.toStringAsFixed(2)} ${toInfo.name}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inverse: 1 ${state.toCurrency} = ${inverseRate.toStringAsFixed(4)} ${state.fromCurrency}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                          tooltip: 'Copy converted amount',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(ClipboardData(
                              text: state.convertedAmount.toStringAsFixed(2),
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Copied ${toInfo.symbol}${state.convertedAmount.toStringAsFixed(2)} to clipboard',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Action Buttons
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Amount to Clipboard'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(
                    text: state.convertedAmount.toStringAsFixed(2),
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Copied ${toInfo.symbol}${state.convertedAmount.toStringAsFixed(2)} to clipboard',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
