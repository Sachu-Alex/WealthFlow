import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/form_widgets.dart';

class AddInvestmentScreen extends ConsumerStatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  ConsumerState<AddInvestmentScreen> createState() =>
      _AddInvestmentScreenState();
}

class _AddInvestmentScreenState
    extends ConsumerState<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: const Color(0xFF0D9488)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount =
          double.parse(_amountCtrl.text.replaceAll(',', ''));
      await ref.read(investmentsProvider.notifier).addInvestment(
            investorName: _nameCtrl.text.trim(),
            initialAmount: amount,
            investmentDate: _selectedDate,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Investment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const FormSectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Investor Details',
              subtitle: 'Who is this investment for?',
            ),
            const SizedBox(height: 16),
            FormInputField(
              controller: _nameCtrl,
              label: 'Investor Name',
              hint: 'e.g. Rahul Sharma',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 28),
            const FormSectionHeader(
              icon: Icons.currency_rupee_rounded,
              title: 'Investment Details',
              subtitle: 'Amount and start date',
            ),
            const SizedBox(height: 16),
            FormInputField(
              controller: _amountCtrl,
              label: 'Initial Investment (₹)',
              hint: 'e.g. 110000',
              icon: Icons.currency_rupee_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Amount is required';
                }
                final parsed =
                    double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FormDateField(
              date: _selectedDate,
              label: 'Investment Date',
              onTap: _pickDate,
            ),
            const SizedBox(height: 28),
            const FormSectionHeader(
              icon: Icons.notes_rounded,
              title: 'Notes',
              subtitle: 'Optional details',
            ),
            const SizedBox(height: 16),
            FormInputField(
              controller: _notesCtrl,
              label: 'Notes (Optional)',
              hint: 'e.g. SBI Mutual Fund SWP',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 36),
            FormSaveButton(
              label: 'Create Investment',
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
