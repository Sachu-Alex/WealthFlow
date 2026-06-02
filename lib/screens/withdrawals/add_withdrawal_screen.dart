import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart';
import '../../providers/investment_provider.dart';
import '../../providers/withdrawal_provider.dart';
import '../../widgets/form_widgets.dart';

class AddWithdrawalScreen extends ConsumerStatefulWidget {
  final String investmentId;
  const AddWithdrawalScreen({super.key, required this.investmentId});

  @override
  ConsumerState<AddWithdrawalScreen> createState() =>
      _AddWithdrawalScreenState();
}

class _AddWithdrawalScreenState
    extends ConsumerState<AddWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
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
      await ref
          .read(withdrawalsProvider(widget.investmentId).notifier)
          .addWithdrawal(
            amount: amount,
            withdrawalDate: _selectedDate,
            remarks: _remarksCtrl.text.trim().isEmpty
                ? null
                : _remarksCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final investmentAsync =
        ref.watch(investmentByIdProvider(widget.investmentId));
    final statsAsync =
        ref.watch(investmentStatsProvider(widget.investmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Withdrawal'),
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
            // Balance summary banner
            investmentAsync.when(
              data: (inv) => statsAsync.when(
                data: (stats) => _BalanceBanner(
                  investorName: inv?.investorName ?? '',
                  remaining: stats.remainingBalance,
                  withdrawn: stats.totalWithdrawn,
                  initial: inv?.initialAmount ?? 0,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const FormSectionHeader(
              icon: Icons.south_rounded,
              title: 'Withdrawal Amount',
              subtitle: 'How much are you withdrawing?',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'e.g. 5000',
                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Amount is required';
                }
                final parsed =
                    double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid positive amount';
                }
                final stats = ref
                    .read(investmentStatsProvider(widget.investmentId))
                    .valueOrNull;
                if (stats != null && parsed > stats.remainingBalance) {
                  return 'Exceeds available balance (${formatCurrency(stats.remainingBalance)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FormDateField(
              date: _selectedDate,
              label: 'Withdrawal Date',
              onTap: _pickDate,
            ),
            const SizedBox(height: 28),
            const FormSectionHeader(
              icon: Icons.notes_rounded,
              title: 'Remarks',
              subtitle: 'Optional note for this withdrawal',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'e.g. Monthly SWP transfer',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 36),
            FormSaveButton(
              label: 'Record Withdrawal',
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

class _BalanceBanner extends StatelessWidget {
  final String investorName;
  final double remaining;
  final double withdrawn;
  final double initial;

  const _BalanceBanner({
    required this.investorName,
    required this.remaining,
    required this.withdrawn,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress =
        initial > 0 ? (remaining / initial).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF334155))
            : Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investorName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(remaining),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Withdrawn',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    formatCurrency(withdrawn),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  const Color(0xFF16A34A).withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF16A34A)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
