import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin.dart';
import 'flags.dart';
import 'format.dart';
import 'rates.dart';
import 'theme.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Design grid: everything on the board is laid out for a 1080-unit-tall
/// screen and scaled to the real TV, so it looks the same on any TV size.
const double _designHeight = 1080;

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _menuFocus = FocusNode(debugLabel: 'menu');
  Timer? _idle;

  static final _wakeKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idle?.cancel();
    _menuFocus.dispose();
    super.dispose();
  }

  bool get _boardInFront =>
      (ModalRoute.of(context)?.isCurrent ?? true) && !(_scaffoldKey.currentState?.isDrawerOpen ?? false);

  /// TV remote: any arrow / OK press highlights the menu button; the remote's
  /// menu key opens the side menu directly. After 15 s idle the highlight
  /// disappears again so the board stays clean.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    _restartIdle();
    if (!mounted || !_boardInFront) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.contextMenu) {
      _openMenu();
      return true;
    }
    if (!_menuFocus.hasFocus && _wakeKeys.contains(key)) {
      _menuFocus.requestFocus();
      return true;
    }
    return false;
  }

  void _restartIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 15), () {
      if (mounted && _boardInFront && _menuFocus.hasFocus) _menuFocus.unfocus();
    });
  }

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _openAdmin() async {
    _scaffoldKey.currentState?.closeDrawer();
    final ok = await showDialog<bool>(context: context, builder: (_) => const LoginDialog());
    if (ok == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminScreen()));
    }
    _restartIdle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: MenuDrawer(onAdmin: _openAdmin),
      drawerScrimColor: const Color(0xB3000000),
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxHeight <= 0 || c.maxWidth <= 0) return const SizedBox.shrink();
          // Keep the height fixed and let the width follow the TV's shape
          // (16:9 -> 1920, a wider 2:1 screen -> 2160).
          final width = (_designHeight * c.maxWidth / c.maxHeight).clamp(1800.0, 2400.0).toDouble();
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: width,
                height: _designHeight,
                child: ValueListenableBuilder<RatesData>(
                  valueListenable: RatesStore.instance.data,
                  builder: (context, data, _) => _Board(
                    data: data,
                    menuFocus: _menuFocus,
                    onMenu: _openMenu,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.data, required this.menuFocus, required this.onMenu});

  final RatesData data;
  final FocusNode menuFocus;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 44, 56, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 132, child: _Header(menuFocus: menuFocus, onMenu: onMenu)),
          const SizedBox(height: 26),
          Expanded(flex: 132, child: RateCard(pair: usdIqd, quote: data.of(usdIqd), big: true)),
          const SizedBox(height: 26),
          Expanded(
            flex: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: RateCard(pair: eurIqd, quote: data.of(eurIqd))),
                const SizedBox(width: 26),
                Expanded(child: RateCard(pair: eurUsd, quote: data.of(eurUsd))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(height: 32, child: _Footer(updatedAt: data.updatedAt)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.menuFocus, required this.onMenu});

  final FocusNode menuFocus;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    // RTL: the first children sit on the right edge.
    return Row(
      children: [
        _MenuButton(focusNode: menuFocus, onPressed: onMenu),
        const SizedBox(width: 30),
        Image.asset('assets/images/emblem.png', height: 124, filterQuality: FilterQuality.medium),
        const SizedBox(width: 28),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRPAHA',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
                letterSpacing: 9,
                height: 1.15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'حوالات داخلية وخارجية وإيداعات',
              style: TextStyle(fontSize: 25, color: AppColors.muted, height: 1.3),
            ),
          ],
        ),
        const Spacer(),
        const _Clock(),
      ],
    );
  }
}

/// The three-line menu button. Shows a gold outline when the TV remote is on it.
class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.focusNode, required this.onPressed});

  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final lineColor = _focused ? AppColors.gold : AppColors.muted;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        focusNode: widget.focusNode,
        onTap: widget.onPressed,
        onFocusChange: (f) => setState(() => _focused = f),
        borderRadius: BorderRadius.circular(14),
        focusColor: Colors.transparent,
        hoverColor: const Color(0x14FFFFFF),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _focused ? const Color(0x1FE6B84A) : null,
            border: Border.all(color: _focused ? AppColors.gold : AppColors.line, width: _focused ? 3 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 28,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 3.5),
                  decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(2)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute || n.hour != _now.hour || n.day != _now.day) {
        setState(() => _now = n);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              clockTime(_now),
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.1,
                fontFeatures: _tabular,
              ),
            ),
            const SizedBox(width: 10),
            Text(amPm(_now), style: const TextStyle(fontSize: 28, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(arabicDate(_now), style: const TextStyle(fontSize: 24, color: AppColors.muted, height: 1.3)),
      ],
    );
  }
}

class RateCard extends StatelessWidget {
  const RateCard({super.key, required this.pair, required this.quote, this.big = false});

  final PairInfo pair;
  final Quote quote;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CurrencyLabel(pair.from, big: big),
                      const SizedBox(width: 18),
                      // arrow_forward flips automatically in Arabic, so it points from -> to.
                      Icon(Icons.arrow_forward, color: AppColors.gold, size: big ? 32 : 28),
                      const SizedBox(width: 18),
                      _CurrencyLabel(pair.to, big: big),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _UnitChip(pair.unitLabel),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Price(label: 'شراء', value: quote.buy, unit: pair.to.name, symbol: pair.symbol, big: big),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  color: AppColors.line,
                ),
                Expanded(
                  child: _Price(label: 'بيع', value: quote.sell, unit: pair.to.name, symbol: pair.symbol, big: big),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyLabel extends StatelessWidget {
  const _CurrencyLabel(this.currency, {required this.big});

  final Currency currency;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlagIcon(currency.flag, height: big ? 46 : 38),
        const SizedBox(width: 14),
        Text(
          currency.name,
          style: TextStyle(
            fontSize: big ? 32 : 27,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            height: 1.3,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          currency.code,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 22, color: AppColors.muted, letterSpacing: 1.8, height: 1.3),
        ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 22, color: AppColors.muted, height: 1.3)),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.label, required this.value, required this.unit, required this.big, this.symbol});

  final String label;
  final double? value;
  final String unit;
  final bool big;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final numSize = big ? 168.0 : 96.0;
    final numColor = value == null ? AppColors.muted : AppColors.text;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: big ? 28 : 24,
            fontWeight: FontWeight.w500,
            color: AppColors.gold,
            height: 1.3,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            TextSpan(
              children: [
                // e.g. "$108.50" — the sign is a bit smaller and gold so the number stays the focus.
                if (symbol != null && value != null)
                  TextSpan(
                    text: symbol,
                    style: TextStyle(fontSize: numSize * 0.72, color: AppColors.gold),
                  ),
                TextSpan(text: formatRate(value)),
              ],
            ),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: numSize,
              fontWeight: FontWeight.w600,
              color: numColor,
              height: 1.12,
              fontFeatures: _tabular,
            ),
          ),
        ),
        Text(unit, style: TextStyle(fontSize: big ? 26 : 22, color: AppColors.muted, height: 1.3)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 22, color: AppColors.muted, height: 1.3);
    final d = updatedAt;
    return Row(
      children: [
        if (d == null)
          const Text('لم يتم إدخال الأسعار بعد', style: style)
        else
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'آخر تحديث للأسعار: '),
                TextSpan(
                  text: '${arabicDate(d)} — ${clockTime(d)} ${amPm(d)}',
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            style: style,
          ),
        const Spacer(),
        const Text('الأسعار قابلة للتغيير', style: style),
      ],
    );
  }
}

/// The small side panel that slides in from the menu button.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key, required this.onAdmin});

  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.panel,
      width: 320,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/emblem.png', height: 44, filterQuality: FilterQuality.medium),
                  const SizedBox(width: 12),
                  const Text(
                    'PRPAHA',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.line, height: 1),
              const SizedBox(height: 16),
              DrawerItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'حساب المسؤول',
                autofocus: true,
                onTap: onAdmin,
              ),
              const SizedBox(height: 8),
              DrawerItem(
                icon: Icons.close_rounded,
                label: 'إغلاق القائمة',
                onTap: () => Scaffold.of(context).closeDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItem extends StatefulWidget {
  const DrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  State<DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<DrawerItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        autofocus: widget.autofocus,
        onTap: widget.onTap,
        onFocusChange: (f) => setState(() => _focused = f),
        borderRadius: BorderRadius.circular(12),
        focusColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _focused ? const Color(0x1FE6B84A) : null,
            border: Border.all(color: _focused ? AppColors.gold : Colors.transparent, width: 2.5),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: _focused ? AppColors.gold : AppColors.text, size: 24),
              const SizedBox(width: 14),
              Text(widget.label, style: const TextStyle(fontSize: 18, color: AppColors.text, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
