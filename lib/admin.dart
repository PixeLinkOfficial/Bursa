import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flags.dart';
import 'format.dart';
import 'rates.dart';
import 'theme.dart';

// Login for the rates editor. Rates live on this TV only, so a simple fixed
// login is enough; change these two values to change it.
const _adminUser = 'admin';
const _adminPassword = '123';

/// Lets the TV remote's up/down buttons move out of a text box to the next
/// control instead of getting stuck inside it.
Widget tvField(Widget field) => Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown):
            DirectionalFocusIntent(TraversalDirection.down, ignoreTextFields: false),
        SingleActivator(LogicalKeyboardKey.arrowUp):
            DirectionalFocusIntent(TraversalDirection.up, ignoreTextFields: false),
      },
      child: field,
    );

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_user.text.trim().toLowerCase() == _adminUser && _pass.text.trim() == _adminPassword) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'دخول المسؤول',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 4),
              const Text(
                'أدخل بيانات الحساب لتعديل الأسعار',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              tvField(TextField(
                controller: _user,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              )),
              const SizedBox(height: 12),
              tvField(TextField(
                controller: _pass,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                onSubmitted: (_) => _submit(),
              )),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: _submit, child: const Text('دخول'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
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

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _buy = <String, TextEditingController>{};
  final _sell = <String, TextEditingController>{};
  final _bad = <TextEditingController>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = RatesStore.instance.data.value;
    for (final p in allPairs) {
      final q = current.of(p);
      _buy[p.key] = TextEditingController(text: inputText(q.buy));
      _sell[p.key] = TextEditingController(text: inputText(q.sell));
    }
  }

  @override
  void dispose() {
    for (final c in [..._buy.values, ..._sell.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Empty box = no price yet (shows "—"); anything else must be a number.
  double? _read(TextEditingController c, Set<TextEditingController> bad) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    final v = parseRate(t);
    if (v == null || v < 0) bad.add(c);
    return v;
  }

  Future<void> _save() async {
    if (_saving) return;
    final bad = <TextEditingController>{};
    final quotes = <String, Quote>{};
    for (final p in allPairs) {
      quotes[p.key] = Quote(_read(_buy[p.key]!, bad), _read(_sell[p.key]!, bad));
    }
    setState(() {
      _bad
        ..clear()
        ..addAll(bad);
    });
    final messenger = ScaffoldMessenger.of(context);
    if (bad.isNotEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('يرجى إدخال أرقام صحيحة فقط')));
      return;
    }
    setState(() => _saving = true);
    final ok = await RatesStore.instance.save(RatesData(quotes, DateTime.now()));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'تم حفظ الأسعار' : 'تم تحديث الشاشة، لكن تعذّر الحفظ الدائم'),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الأسعار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        children: [
          for (final p in allPairs)
            _PairEditor(
              pair: p,
              buy: _buy[p.key]!,
              sell: _sell[p.key]!,
              buyBad: _bad.contains(_buy[p.key]),
              sellBad: _bad.contains(_sell[p.key]),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('حفظ الأسعار'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairEditor extends StatelessWidget {
  const _PairEditor({
    required this.pair,
    required this.buy,
    required this.sell,
    required this.buyBad,
    required this.sellBad,
  });

  final PairInfo pair;
  final TextEditingController buy;
  final TextEditingController sell;
  final bool buyBad;
  final bool sellBad;

  Widget _field(TextEditingController c, String label, bool bad) => tvField(TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: InputDecoration(labelText: label, errorText: bad ? 'رقم غير صحيح' : null),
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                FlagIcon(pair.from.flag, height: 22),
                const SizedBox(width: 6),
                FlagIcon(pair.to.flag, height: 22),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${pair.from.name} ← ${pair.to.name}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text),
                      ),
                      Text(pair.unitLabel, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _field(buy, 'شراء', buyBad)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _field(sell, 'بيع', sellBad)),
        ],
      ),
    );
  }
}
