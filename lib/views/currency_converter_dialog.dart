import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';
import '../services/currency_service.dart';
import '../utils/formatters.dart';

class CurrencyConverterDialog extends ConsumerStatefulWidget {
  const CurrencyConverterDialog({super.key});

  @override
  ConsumerState<CurrencyConverterDialog> createState() => _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends ConsumerState<CurrencyConverterDialog> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(currencyConverterProvider);
    _amountController = TextEditingController(text: state.inputAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.currency_exchange, size: 20, color: Color(0xFF064E3B)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Live Currency Converter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh live rates',
                    onPressed: state.isLoading ? null : () => notifier.refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isLive ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isLive ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: state.isLive ? Colors.green.shade700 : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.isLive
                            ? 'Real-time rates active • ${state.lastUpdated != null ? Formatters.date(state.lastUpdated!) : "Just now"}'
                            : 'Offline cached rates • Connect to refresh',
                        style: TextStyle(
                          fontSize: 11,
                          color: state.isLive ? Colors.green.shade900 : Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Input Amount Field
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount to Convert',
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      widthFactor: 1,
                      child: Text(fromInfo.flagEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  notifier.setAmount(parsed);
                },
              ),
              const SizedBox(height: 16),

              // Currency Selectors with Swap
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('from_${state.fromCurrency}'),
                      initialValue: state.fromCurrency,
                      decoration: InputDecoration(
                        labelText: 'From',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: CurrencyService.supportedCurrencies.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            '${c.flagEmoji} ${c.code}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setFromCurrency(val);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => notifier.swap(),
                    icon: const Icon(Icons.swap_horiz, size: 28, color: Color(0xFF064E3B)),
                    tooltip: 'Swap Currencies',
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('to_${state.toCurrency}'),
                      initialValue: state.toCurrency,
                      decoration: InputDecoration(
                        labelText: 'To',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: CurrencyService.supportedCurrencies.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            '${c.flagEmoji} ${c.code}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
              const SizedBox(height: 20),

              // Converted Result Display Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
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
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '1 ${state.fromCurrency} = ${unitRate.toStringAsFixed(3)} ${state.toCurrency}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${toInfo.symbol} ${Formatters.number(state.convertedAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.inputAmount.toStringAsFixed(2)} ${fromInfo.name} = ${state.convertedAmount.toStringAsFixed(2)} ${toInfo.name}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Value'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
