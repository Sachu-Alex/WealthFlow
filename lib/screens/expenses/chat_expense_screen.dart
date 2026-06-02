import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';

// ─── Conversation model ───────────────────────────────────────────────────────

enum _Step { awaitCategory, awaitAmount, awaitNote, done }

enum _MsgKind { botText, botCategories, botAmounts, botSuccess, userText }

class _Msg {
  final String id;
  final _MsgKind kind;
  final String text;
  // extra payload
  final List<ExpenseCategory>? categories;
  final List<double>? amounts;
  final String? successCategory;
  final String? successEmoji;
  final double? successAmount;

  _Msg._({
    required this.id,
    required this.kind,
    this.text = '',
    this.categories,
    this.amounts,
    this.successCategory,
    this.successEmoji,
    this.successAmount,
  });

  factory _Msg.botText(String text) => _Msg._(
        id: _uid(),
        kind: _MsgKind.botText,
        text: text,
      );

  factory _Msg.botCategories() => _Msg._(
        id: _uid(),
        kind: _MsgKind.botCategories,
        categories: kExpenseCategories,
      );

  factory _Msg.botAmounts(List<double> amounts, String text) => _Msg._(
        id: _uid(),
        kind: _MsgKind.botAmounts,
        text: text,
        amounts: amounts,
      );

  factory _Msg.botSuccess(String category, String emoji, double amount) =>
      _Msg._(
        id: _uid(),
        kind: _MsgKind.botSuccess,
        successCategory: category,
        successEmoji: emoji,
        successAmount: amount,
      );

  factory _Msg.userText(String text) => _Msg._(
        id: _uid(),
        kind: _MsgKind.userText,
        text: text,
      );

  static int _counter = 0;
  static String _uid() => 'msg_${++_counter}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatExpenseScreen extends ConsumerStatefulWidget {
  const ChatExpenseScreen({super.key});

  @override
  ConsumerState<ChatExpenseScreen> createState() => _ChatExpenseScreenState();
}

class _ChatExpenseScreenState extends ConsumerState<ChatExpenseScreen>
    with TickerProviderStateMixin {
  final List<_Msg> _msgs = [];
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  _Step _step = _Step.awaitCategory;
  ExpenseCategory? _selectedCat;
  double? _selectedAmount;
  bool _botTyping = false;
  bool _saving = false;
  // Track which interactive messages are still active
  bool _categoriesActive = false;
  bool _amountsActive = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Conversation flow ─────────────────────────────────────────────────────

  Future<void> _startConversation() async {
    await _pause(350);
    _push(_Msg.botText('Hey! 👋 What did you spend on today?'));
    await _pause(500);
    setState(() => _categoriesActive = true);
    _push(_Msg.botCategories());
  }

  Future<void> _onCategoryTap(ExpenseCategory cat) async {
    if (_step != _Step.awaitCategory) return;
    _step = _Step.awaitAmount;
    setState(() => _categoriesActive = false);

    _selectedCat = cat;
    _push(_Msg.userText('${cat.emoji}  ${cat.name}'));

    await _typing(700);
    _push(_Msg.botText('${cat.emoji} Nice! How much did you spend on **${cat.name}**?'));
    await _pause(300);
    setState(() => _amountsActive = true);
    _push(_Msg.botAmounts(cat.amountPresets,
        'Tap an amount or type a custom value below.'));
  }

  Future<void> _onAmountTap(double amount) async {
    if (_step != _Step.awaitAmount) return;
    _step = _Step.awaitNote;
    setState(() => _amountsActive = false);

    _selectedAmount = amount;
    _push(_Msg.userText('₹${_fmtAmt(amount)}'));

    await _typing(600);
    _push(_Msg.botText(
        '📝 Got it! Any note for this? (e.g. "lunch with team")\nOr tap **Skip** below.'));
    setState(() {});
    _focusNode.requestFocus();
  }

  Future<void> _onCustomAmount() async {
    final raw = _textCtrl.text.replaceAll(RegExp(r'[₹, ]'), '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _shake();
      return;
    }
    _textCtrl.clear();
    _focusNode.unfocus();
    await _onAmountTap(amount);
  }

  Future<void> _onNoteSubmit({bool skip = false}) async {
    if (_step != _Step.awaitNote) return;
    _step = _Step.done;

    final note = skip ? null : _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim();
    _textCtrl.clear();
    _focusNode.unfocus();

    if (note != null) _push(_Msg.userText(note));

    setState(() => _saving = true);
    await ref.read(expensesProvider.notifier).addExpense(
          category: _selectedCat!.name,
          categoryColor: _selectedCat!.color.toARGB32(),
          amount: _selectedAmount!,
          note: note,
          date: DateTime.now(),
        );
    setState(() => _saving = false);

    await _typing(500);
    _push(_Msg.botSuccess(
        _selectedCat!.name, _selectedCat!.emoji, _selectedAmount!));
  }

  Future<void> _onAddAnother() async {
    _step = _Step.awaitCategory;
    _selectedCat = null;
    _selectedAmount = null;

    await _typing(400);
    _push(_Msg.botText('Sure! What else did you spend on? 😊'));
    await _pause(400);
    setState(() => _categoriesActive = true);
    _push(_Msg.botCategories());
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _push(_Msg msg) {
    if (!mounted) return;
    setState(() => _msgs.add(msg));
    _scrollToBottom();
  }

  Future<void> _typing(int ms) async {
    setState(() => _botTyping = true);
    _scrollToBottom();
    await Future.delayed(Duration(milliseconds: ms));
    if (mounted) setState(() => _botTyping = false);
  }

  Future<void> _pause(int ms) =>
      Future.delayed(Duration(milliseconds: ms));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmtAmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K' : v.toInt().toString();

  void _shake() {
    HapticFeedback.lightImpact();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF0FDF9),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _msgs.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _msgs.length,
                    itemBuilder: (ctx, i) => _buildMessage(_msgs[i], isDark),
                  ),
          ),

          // Bot typing indicator
          if (_botTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  _BotAvatar(),
                  const SizedBox(width: 8),
                  _TypingDots(isDark: isDark),
                ],
              ),
            ),

          // Saving indicator
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          // Input bar — context-aware
          _buildInputBar(theme, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_comment_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Expense',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(
                'Conversational mode',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF0FDF9),
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildMessage(_Msg msg, bool isDark) {
    return _AnimatedMessageEntry(
      key: ValueKey(msg.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: switch (msg.kind) {
          _MsgKind.botText => _BotTextBubble(text: msg.text, isDark: isDark),
          _MsgKind.botCategories => _CategoryPickerBubble(
              categories: msg.categories!,
              active: _categoriesActive,
              onTap: _onCategoryTap,
              isDark: isDark,
            ),
          _MsgKind.botAmounts => _AmountPickerBubble(
              text: msg.text,
              amounts: msg.amounts!,
              active: _amountsActive,
              onTap: _onAmountTap,
              isDark: isDark,
            ),
          _MsgKind.botSuccess => _SuccessBubble(
              category: msg.successCategory!,
              emoji: msg.successEmoji!,
              amount: msg.successAmount!,
              isDark: isDark,
              onAddAnother: _onAddAnother,
              onViewExpenses: () => context.pop(),
            ),
          _MsgKind.userText => _UserBubble(text: msg.text),
        },
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    // Show nothing when done or still in category-pick step
    if (_step == _Step.done || _step == _Step.awaitCategory) {
      return const SizedBox();
    }

    final hint = _step == _Step.awaitAmount
        ? 'Custom amount (e.g. 350)…'
        : 'Add a note… (optional)';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2233) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
        ),
        child: Row(
          children: [
            // Skip button — only on note step
            if (_step == _Step.awaitNote) ...[
              GestureDetector(
                onTap: () => _onNoteSubmit(skip: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Text input
            Expanded(
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                keyboardType: _step == _Step.awaitAmount
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                inputFormatters: _step == _Step.awaitAmount
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
                    : null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _step == _Step.awaitAmount
                    ? _onCustomAmount()
                    : _onNoteSubmit(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFF1F5F9),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _step == _Step.awaitAmount
                  ? _onCustomAmount
                  : () => _onNoteSubmit(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Widgets ─────────────────────────────────────────────────────────

class _AnimatedMessageEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedMessageEntry({super.key, required this.child});

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0369A1)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.add_comment_rounded, color: Colors.white, size: 14),
      );
}

class _BotTextBubble extends StatelessWidget {
  final String text;
  final bool isDark;

  const _BotTextBubble({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Parse **bold** markdown
    final spans = _parseBold(text, context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2233) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Text.rich(
              TextSpan(children: spans),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white : const Color(0xFF0A1628),
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  List<InlineSpan> _parseBold(String text, BuildContext ctx) {
    final parts = text.split(RegExp(r'\*\*'));
    return List.generate(parts.length, (i) {
      return TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
        ),
      );
    });
  }
}

class _CategoryPickerBubble extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final bool active;
  final ValueChanged<ExpenseCategory> onTap;
  final bool isDark;

  const _CategoryPickerBubble({
    required this.categories,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              return _CategoryChip(
                cat: cat,
                active: active,
                onTap: active ? () => onTap(cat) : null,
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final ExpenseCategory cat;
  final bool active;
  final VoidCallback? onTap;
  final bool isDark;

  const _CategoryChip({
    required this.cat,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final active = widget.active;

    return GestureDetector(
      onTapDown: active ? (_) => _ctrl.forward() : null,
      onTapUp: active
          ? (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          opacity: active ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? cat.color.withValues(alpha: 0.18)
                  : cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cat.color.withValues(alpha: active ? 0.5 : 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, color: cat.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    color: cat.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _AmountPickerBubble extends StatelessWidget {
  final String text;
  final List<double> amounts;
  final bool active;
  final ValueChanged<double> onTap;
  final bool isDark;

  const _AmountPickerBubble({
    required this.text,
    required this.amounts,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _BotAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2233) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amounts.map((amt) {
              return _AmountChip(
                amount: amt,
                active: active,
                onTap: active ? () => onTap(amt) : null,
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatefulWidget {
  final double amount;
  final bool active;
  final VoidCallback? onTap;
  final bool isDark;

  const _AmountChip({
    required this.amount,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AmountChip> createState() => _AmountChipState();
}

class _AmountChipState extends State<_AmountChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.active ? (_) => _ctrl.forward() : null,
      onTapUp: widget.active
          ? (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.93)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)),
        child: AnimatedOpacity(
          opacity: widget.active ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF0D9488).withValues(alpha: 0.18)
                  : const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0D9488)
                    .withValues(alpha: widget.active ? 0.5 : 0.2),
              ),
            ),
            child: Text(
              '₹${formatCurrency(widget.amount).replaceAll('₹', '')}',
              style: const TextStyle(
                color: Color(0xFF0D9488),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessBubble extends StatelessWidget {
  final String category;
  final String emoji;
  final double amount;
  final bool isDark;
  final VoidCallback onAddAnother;
  final VoidCallback onViewExpenses;

  const _SuccessBubble({
    required this.category,
    required this.emoji,
    required this.amount,
    required this.isDark,
    required this.onAddAnother,
    required this.onViewExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2233) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expense saved! 🎉',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Successfully logged',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF16A34A).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Expense summary
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '-${formatCurrency(amount)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onViewExpenses,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF0D9488),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAddAnother,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0369A1)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '+ Add More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  final bool isDark;
  const _TypingDots({required this.isDark});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400)),
    );
    _anims = _ctrls.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 130), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F2233) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: widget.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
