import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'attendance.dart';
import 'home.dart';
import 'leaves.dart';
import 'login.dart';
import 'payroll.dart';
import 'profile.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  Future<Me>? _meF;

  @override
  void initState() {
    super.initState();
    _meF = Api.i.me();
  }

  void _go(int i) => setState(() => _tab = i);

  Future<void> _logout() async {
    await Api.i.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Me>(
      future: _meF,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingState());
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: ErrorState('${snap.error}',
                  onRetry: () => setState(() => _meF = Api.i.me())),
            ),
          );
        }
        final me = snap.data!;
        final pages = [
          HomeTab(me: me, onNavigate: _go),
          const AttendanceTab(),
          LeavesTab(me: me),
          const PayrollTab(),
          ProfileTab(me: me, onLogout: _logout),
        ];
        return Scaffold(
          body: IndexedStack(index: _tab, children: pages),
          bottomNavigationBar: _NavBar(current: _tab, onTap: _go),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _items = [
  _NavItem(Icons.home_rounded, 'Beranda'),
  _NavItem(Icons.access_time_rounded, 'Absensi'),
  _NavItem(Icons.event_note_rounded, 'Cuti'),
  _NavItem(Icons.payments_rounded, 'Gaji'),
  _NavItem(Icons.person_rounded, 'Profil'),
];

class _NavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _NavBar({required this.current, required this.onTap});

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb;

  @override
  Widget build(BuildContext context) {
    final pad = _isIOS
        ? const EdgeInsets.fromLTRB(4, 8, 4, 26)
        : const EdgeInsets.fromLTRB(4, 10, 4, 12);
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: pad,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == current;
              final it = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _icon(active, it.icon),
                        const SizedBox(height: 4),
                        Text(it.label,
                            style: T.sans(10,
                                weight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active
                                    ? (_isIOS ? C.teal : C.deepTeal)
                                    : C.muted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _icon(bool active, IconData icon) {
    if (_isIOS) {
      return Icon(icon, size: 24, color: active ? C.teal : C.muted);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: active ? C.mint : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, size: 22, color: active ? C.deepTeal : C.muted),
    );
  }
}
