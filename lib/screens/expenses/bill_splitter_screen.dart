import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bill_splitter.dart';
import '../../providers/bill_splitter_provider.dart';

const _teal = Color(0xFF0D9488);
const _tealBright = Color(0xFF2DD4BF);
const _green = Color(0xFF22C55E);

class BillSplitterScreen extends ConsumerStatefulWidget {
  const BillSplitterScreen({super.key});

  @override
  ConsumerState<BillSplitterScreen> createState() => _BillSplitterScreenState();
}

class _BillSplitterScreenState extends ConsumerState<BillSplitterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(billSplitterProvider.notifier).reset());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billSplitterProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: state.step == SplitterStep.upload,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(billSplitterProvider.notifier).goBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Bill Splitter'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (state.step != SplitterStep.upload) {
                ref.read(billSplitterProvider.notifier).goBack();
              } else {
                context.pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: _StepBar(current: state.step),
          ),
        ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: switch (state.step) {
                SplitterStep.upload =>
                  _UploadStep(key: const ValueKey('upload')),
                SplitterStep.reviewItems =>
                  _ReviewStep(key: const ValueKey('review')),
                SplitterStep.assign =>
                  _AssignStep(key: const ValueKey('assign')),
                SplitterStep.results =>
                  _ResultsStep(key: const ValueKey('results')),
              },
            ),
            if (state.isLoading) _LoadingOverlay(message: state.loadingMessage),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final SplitterStep current;
  const _StepBar({required this.current});

  static const _labels = ['Upload', 'Items', 'Assign', 'Split'];

  @override
  Widget build(BuildContext context) {
    final idx = SplitterStep.values.indexOf(current);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(4 * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: AnimatedContainer(
                duration: 300.ms,
                height: 1.5,
                color: i ~/ 2 < idx
                    ? _teal
                    : _teal.withValues(alpha: 0.15),
              ),
            );
          }
          final si = i ~/ 2;
          final done = si < idx;
          final active = si == idx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: 300.ms,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? _teal : Colors.transparent,
                  border: Border.all(
                    color: done || active ? _teal : _teal.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : Text('${si + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : _teal.withValues(alpha: 0.35),
                          )),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _labels[si],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active
                      ? _teal
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 1: Upload ────────────────────────────────────────────────────────────

class _UploadStep extends ConsumerWidget {
  const _UploadStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billSplitterProvider);
    final notifier = ref.read(billSplitterProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Upload Receipt',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Take a photo of any itemized bill or receipt.',
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          // ── Receipt preview / drop zone ───────────────────────────────────
          GestureDetector(
            onTap: () => notifier.pickImage(ImageSource.gallery),
            child: AnimatedContainer(
              duration: 250.ms,
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F2233)
                    : const Color(0xFFEFF9F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.receiptImage != null
                      ? _teal
                      : _teal.withValues(alpha: 0.25),
                  width: state.receiptImage != null ? 2 : 1.5,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: state.receiptImage != null
                  ? Image.network(
                      state.receiptImage!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ReceiptPlaceholder(
                        label: '✓ Photo selected',
                        sublabel: 'Tap to change',
                        isDark: isDark,
                      ),
                    )
                  : _ReceiptPlaceholder(
                      label: 'Tap to upload',
                      sublabel: 'Restaurant, grocery or any itemized bill',
                      isDark: isDark,
                    ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => notifier.pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => notifier.pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms),

          if (state.error != null) ...[
            const SizedBox(height: 14),
            _ErrorCard(state.error!),
          ],

          const SizedBox(height: 24),
          _PrimaryBtn(
            label: 'Scan Receipt',
            icon: Icons.document_scanner_rounded,
            enabled: state.receiptImage != null,
            onTap: notifier.scanReceipt,
          ).animate(delay: 140.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: notifier.startManualEntry,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Enter items manually'),
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPlaceholder extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isDark;
  const _ReceiptPlaceholder(
      {required this.label, required this.sublabel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_rounded, size: 32, color: _teal),
        ),
        const SizedBox(height: 14),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(sublabel,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Step 2: Review extracted items ────────────────────────────────────────────

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billSplitterProvider);
    final notifier = ref.read(billSplitterProvider.notifier);
    final bill = state.billSummary!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              Text('Review Items',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(
                bill.items.isEmpty
                    ? 'No items found. Add them manually below.'
                    : '${bill.items.length} items found. Edit if anything looks wrong.',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(state.error!),
              ],

              const SizedBox(height: 16),

              ...bill.items.asMap().entries.map(
                    (e) => _ItemTile(
                      item: e.value,
                      isDark: isDark,
                      onDelete: () => notifier.removeItem(e.value.id),
                      onNameChanged: (name) => notifier
                          .updateItem(e.value.copyWith(name: name)),
                      onAmountChanged: (amt) {
                        final total = amt ?? e.value.total;
                        notifier.updateItem(e.value.copyWith(
                          total: total,
                          unitPrice: total / e.value.quantity,
                        ));
                      },
                    )
                        .animate(
                            delay: Duration(milliseconds: e.key * 40))
                        .fadeIn(duration: 280.ms),
                  ),

              const SizedBox(height: 8),
              // Add item button
              GestureDetector(
                onTap: notifier.addItem,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _teal.withValues(alpha: 0.3),
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: _teal),
                      SizedBox(width: 6),
                      Text('Add Item',
                          style: TextStyle(
                              color: _teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),

              if (bill.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TotalsCard(bill: bill, isDark: isDark),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _PrimaryBtn(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            enabled: bill.items.isNotEmpty,
            onTap: notifier.proceedToAssign,
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatefulWidget {
  final BillItem item;
  final bool isDark;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double?> onAmountChanged;

  const _ItemTile({
    required this.item,
    required this.isDark,
    required this.onDelete,
    required this.onNameChanged,
    required this.onAmountChanged,
  });

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amtCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _amtCtrl = TextEditingController(
        text: widget.item.total > 0
            ? widget.item.total.toStringAsFixed(2)
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF1A3349)
              : const Color(0xFFD0EDE9),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Item name',
              ),
              onChanged: widget.onNameChanged,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _amtCtrl,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _teal),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                prefixText: '₹',
                prefixStyle:
                    TextStyle(color: _teal, fontWeight: FontWeight.w700),
                hintText: '0',
              ),
              onChanged: (v) =>
                  widget.onAmountChanged(double.tryParse(v)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5)),
            onPressed: widget.onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Assign items to people ────────────────────────────────────────────

class _AssignStep extends ConsumerStatefulWidget {
  const _AssignStep({super.key});

  @override
  ConsumerState<_AssignStep> createState() => _AssignStepState();
}

class _AssignStepState extends ConsumerState<_AssignStep> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(billSplitterProvider.notifier).addParticipant(name);
    _nameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billSplitterProvider);
    final notifier = ref.read(billSplitterProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bill = state.billSummary!;

    return Column(
      children: [
        // ── Add people section ──────────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF0F2233) : const Color(0xFFEFF9F8),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Who\'s splitting?',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add person (e.g. Rahul)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF0A1628) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: _teal.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: _teal.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _teal, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _addPerson(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addPerson,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (state.participants.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: state.participants.map((name) {
                    return Chip(
                      label: Text(name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      avatar: CircleAvatar(
                        backgroundColor: _teal,
                        child: Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => notifier.removeParticipant(name),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        // ── Item assignment list ────────────────────────────────────────────
        Expanded(
          child: state.participants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Add people above to assign items',
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    Text(
                      'Tap each person who had that item:',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ...bill.items.asMap().entries.map((e) =>
                        _AssignItemCard(
                          item: e.value,
                          participants: state.participants,
                          isDark: isDark,
                        )
                            .animate(
                                delay: Duration(
                                    milliseconds: e.key * 50))
                            .fadeIn(duration: 280.ms)),
                  ],
                ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: _PrimaryBtn(
            label: 'Calculate Split',
            icon: Icons.calculate_rounded,
            enabled: state.participants.isNotEmpty,
            onTap: notifier.calculateSplit,
          ),
        ),
      ],
    );
  }
}

class _AssignItemCard extends ConsumerWidget {
  final BillItem item;
  final List<String> participants;
  final bool isDark;

  const _AssignItemCard({
    required this.item,
    required this.participants,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(billSplitterProvider.notifier);
    final sharedByAll = notifier.isSharedByAll(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1A3349) : const Color(0xFFD0EDE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name + price
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(formatCurrency(item.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _teal)),
            ],
          ),
          const SizedBox(height: 10),

          // Person chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Individual person chips
              ...participants.map((name) {
                final assigned = notifier.isAssignedTo(item.id, name);
                return GestureDetector(
                  onTap: () {
                    notifier.toggleAssignment(item.id, name);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: assigned
                          ? _teal
                          : isDark
                              ? const Color(0xFF0A1628)
                              : const Color(0xFFEFF9F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: assigned
                            ? _teal
                            : _teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (assigned)
                          const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white),
                        if (assigned) const SizedBox(width: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: assigned ? Colors.white : _teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // "Shared" chip
              GestureDetector(
                onTap: () => notifier.setSharedByAll(item.id),
                child: AnimatedContainer(
                  duration: 180.ms,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sharedByAll ? _green : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sharedByAll
                          ? _green
                          : _green.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded,
                          size: 12,
                          color: sharedByAll
                              ? Colors.white
                              : _green),
                      const SizedBox(width: 4),
                      Text(
                        'Shared',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sharedByAll ? Colors.white : _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Results ───────────────────────────────────────────────────────────

class _ResultsStep extends ConsumerWidget {
  const _ResultsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billSplitterProvider);
    final result = state.splitResult!;
    final bill = state.billSummary!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text('Split Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              Text(
                '${result.participants.length} people · ${formatCurrency(bill.grandTotal)} total',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 20),

              ...result.participants.asMap().entries.map((e) =>
                  _PersonCard(
                    participant: e.value,
                    isDark: isDark,
                    grandTotal: bill.grandTotal,
                  )
                      .animate(
                          delay: Duration(milliseconds: e.key * 80))
                      .fadeIn(duration: 320.ms)
                      .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOut)),

              if (result.sharedItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SharedBanner(items: result.sharedItems),
              ],

              const SizedBox(height: 16),
              _TotalsCard(bill: bill, isDark: isDark),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.refresh_rounded,
                  label: 'New Split',
                  onTap: () =>
                      ref.read(billSplitterProvider.notifier).reset(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final SplitParticipant participant;
  final bool isDark;
  final double grandTotal;

  const _PersonCard({
    required this.participant,
    required this.isDark,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        grandTotal > 0 ? (participant.total / grandTotal).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? const Color(0xFF1A3349) : const Color(0xFFD0EDE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_teal, _tealBright],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    participant.name.isNotEmpty
                        ? participant.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(participant.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Text(
                formatCurrency(participant.total),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: _teal,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _teal.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(_teal),
              minHeight: 4,
            ),
          ),
          if (participant.itemsConsumed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: participant.itemsConsumed.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _teal,
                          fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ],
          if (participant.taxShare > 0 || participant.serviceChargeShare > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (participant.subtotal > 0)
                  _Pill('Items: ${formatCurrency(participant.subtotal)}'),
                if (participant.taxShare > 0)
                  _Pill('Tax: ${formatCurrency(participant.taxShare)}'),
                if (participant.serviceChargeShare > 0)
                  _Pill('Svc: ${formatCurrency(participant.serviceChargeShare)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _SharedBanner extends StatelessWidget {
  final List<String> items;
  const _SharedBanner({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.people_rounded, size: 15, color: _green),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Shared equally: ${items.join(', ')}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _green,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final BillSummary bill;
  final bool isDark;
  const _TotalsCard({required this.bill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? _teal.withValues(alpha: 0.08)
            : const Color(0xFFEFF9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (bill.subtotal > 0 && bill.subtotal != bill.grandTotal)
            _TRow('Subtotal', bill.subtotal),
          if (bill.tax > 0) _TRow('Tax / GST', bill.tax),
          if (bill.serviceCharge > 0)
            _TRow('Service Charge', bill.serviceCharge),
          if (bill.tax > 0 || bill.serviceCharge > 0)
            const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Text(formatCurrency(bill.grandTotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _teal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TRow extends StatelessWidget {
  final String label;
  final double amount;
  const _TRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(formatCurrency(amount),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: 200.ms,
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [_teal, _tealBright],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : Colors.grey.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? Colors.white : Colors.grey, size: 19),
              const SizedBox(width: 9),
              Text(label,
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2233) : const Color(0xFFEFF9F8),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _teal.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: _teal),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _teal)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 15, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFDC2626))),
            ),
          ],
        ),
      );
}

class _LoadingOverlay extends StatelessWidget {
  final String message;
  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F2233)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: _teal, strokeWidth: 3),
                const SizedBox(height: 14),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('On-device · No internet needed',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
}
