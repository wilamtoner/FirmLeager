import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firm_provider.dart';

class EditFirmDialog extends ConsumerStatefulWidget {
  const EditFirmDialog({super.key});

  static void showMobileBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EditFirmDialog(),
    );
  }

  @override
  ConsumerState<EditFirmDialog> createState() => _EditFirmDialogState();
}

class _EditFirmDialogState extends ConsumerState<EditFirmDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final firm = ref.read(firmProvider);
    _nameController = TextEditingController(text: firm.name);
    _taxIdController = TextEditingController(text: firm.taxId);
    _addressController = TextEditingController(text: firm.address);
    _phoneController = TextEditingController(text: firm.phone);
    _currency = firm.currencySymbol;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(firmProvider.notifier).updateFirm(
            name: _nameController.text.trim(),
            taxId: _taxIdController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            currencySymbol: _currency,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mobile Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Firm Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(labelText: 'Firm / Business Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter firm name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxIdController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(labelText: 'PAN / Tax Reg. Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency Symbol', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Rs.', child: Text('Rs. (Nepalese/Indian Rupee)')),
                    DropdownMenuItem(value: '\$', child: Text('\$ (US Dollar)')),
                    DropdownMenuItem(value: '€', child: Text('€ (Euro)')),
                    DropdownMenuItem(value: '£', child: Text('£ (Pound Sterling)')),
                  ],
                  onChanged: (val) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (val != null) setState(() => _currency = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
