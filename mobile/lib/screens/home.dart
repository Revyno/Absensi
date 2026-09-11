import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../services/notifications.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'approvals.dart';
import 'checkin_sheet.dart';

class _HomeData {
  final Attendance? today;
  final List<Attendance> recent;
  final List<Leave> pending;
  _HomeData(this.today, this.recent, this.pending);
}

class HomeTab extends StatefulWidget {
  final Me me;
  final ValueChanged<int> onNavigate;
  const HomeTab({super.key, required this.me, required this.onNavigate});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<_HomeData>? _f;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  bool _isToday(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<_HomeData> _load() async {
    final history = await Api.i.attendanceHistory(limit: 10);
    Attendance? today;
    for (final a in history) {
      if (_isToday(a.date)) {
        today = a;
        break;
      }
    }
    final recent = history.where((a) => a.id != today?.id).take(4).toList();
    List<Leave> pending = [];
    if (widget.me.isManager) {
      try {
        pending = await Api.i.leaves(status: 'PENDING', limit: 5);
      } catch (_) {}
    }
    return _HomeData(today, recent, pending);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _f = f);
    await f;
  }

  Future<void> _checkInFlow() async {
    final ok = await showCheckInSheet(context);
    if (ok == true) {
      if (mounted) showToast(context, 'Berhasil check-in');
      await _refresh();
    }
  }

  Future<void> _checkOut() async {
    setState(() => _busy = true);
    try {
      final a = await Api.i.checkOut();
      await NotificationService.i
          .show('Check-out berhasil', 'Pulang ${a.checkOut ?? ''}');
      if (mounted) showToast(context, 'Berhasil check-out');
      await _refresh();
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.paper,
      child: RefreshIndicator(
        color: C.teal,
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _f,
          builder: (context, snap) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                if (snap.connectionState != ConnectionState.done)
                  const SliverToBoxAdapter(child: LoadingState())
                else if (snap.hasError)
                  SliverToBoxAdapter(
                      child: ErrorState('${snap.error}', onRetry: _refresh))
                else
                  _body(snap.data!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero() {
    final name = widget.me.employee?.fullName ?? widget.me.email;
    final role = widget.me.employee?.positionName ?? widget.me.role;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 76),
      decoration: const BoxDecoration(
        color: C.deepTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang',
                    style: T.sans(12,
                        color: C.mint.withValues(alpha: 0.85),
                        weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(name,
                    style: T.sans(20,
                        weight: FontWeight.w800, color: Colors.white)),
                Text(role,
                    style: T.sans(12, color: C.mint.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: C.mint, borderRadius: BorderRadius.circular(14)),
            child: Text(Fmt.initials(name),
                style: T.sans(15, weight: FontWeight.w700, color: C.deepTeal)),
          ),
        ],
      ),
    );
  }

  Widget _body(_HomeData d) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Transform.translate(
            offset: const Offset(0, -56),
            child: _todayCard(d.today),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.me.isManager && d.pending.isNotEmpty) ...[
                  _approvalCard(d.pending),
                  const SizedBox(height: 20),
                ],
                const SectionHeader('Aksi cepat'),
                _quickActions(),
                const SizedBox(height: 20),
                SectionHeader('Aktivitas terakhir',
                    trailing: TextButton(
                      onPressed: () => widget.onNavigate(1),
                      child: Text('Semua',
                          style: T.sans(12,
                              weight: FontWeight.w600, color: C.teal)),
                    )),
                if (d.recent.isEmpty)
                  const EmptyState('Belum ada aktivitas absensi.')
                else
                  ...d.recent.map(_activityRow),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _todayCard(Attendance? a) {
    final checkedIn = a?.checkIn != null;
    final checkedOut = a?.checkOut != null;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Absensi hari ini',
                  style: T.sans(14, weight: FontWeight.w700)),
              StatusChip(a?.status ?? '',
                  label: a == null ? 'Belum absen' : null),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: StatCell('Masuk', Fmt.jam(a?.checkIn))),
            const SizedBox(width: 9),
            Expanded(child: StatCell('Pulang', Fmt.jam(a?.checkOut))),
            const SizedBox(width: 9),
            Expanded(
                child: StatCell('Total', Fmt.durasi(a?.workingMinutes),
                    valueColor: C.teal)),
          ]),
          const SizedBox(height: 14),
          if (!checkedIn)
            PrimaryButton(
                label: 'Check-in sekarang',
                icon: Icons.login_rounded,
                loading: _busy,
                onPressed: _checkInFlow)
          else if (!checkedOut)
            PrimaryButton(
                label: 'Check-out',
                icon: Icons.logout_rounded,
                loading: _busy,
                onPressed: _checkOut)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: C.mint, borderRadius: BorderRadius.circular(16)),
              child: Text('Absensi hari ini selesai',
                  style:
                      T.sans(13, weight: FontWeight.w700, color: C.deepTeal)),
            ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.place_outlined, size: 15, color: C.muted),
            const SizedBox(width: 6),
            Text('Kantor Pusat · terverifikasi',
                style: T.sans(11.5, color: C.muted)),
          ]),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final items = [
      (Icons.event_available_rounded, 'Ajukan Cuti', 'Kelola izin & cuti', 2),
      (Icons.receipt_long_rounded, 'Slip Gaji', 'Lihat penghasilan', 3),
      (Icons.access_time_rounded, 'Riwayat', 'Absensi bulan ini', 1),
      (Icons.badge_outlined, 'Profil', 'Data & BPJS', 4),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: items
          .map((it) => AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => widget.onNavigate(it.$4),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: C.mint, borderRadius: BorderRadius.circular(11)),
                    child: Icon(it.$1, size: 19, color: C.deepTeal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(it.$2,
                            style: T.sans(13, weight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(it.$3,
                            style: T.sans(11, color: C.muted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
              ))
          .toList(),
    );
  }

  Widget _activityRow(Attendance a) {
    final (day, wd) = Fmt.sel(a.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 38,
          child: Column(children: [
            Text(day, style: T.mono(15, weight: FontWeight.w600)),
            Text(wd,
                style: T.sans(10, color: C.muted, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Fmt.jam(a.checkIn)} – ${Fmt.jam(a.checkOut)}',
                  style: T.mono(13, weight: FontWeight.w600)),
              Text('Durasi ${Fmt.durasi(a.workingMinutes)}',
                  style: T.sans(11, color: C.muted)),
            ],
          ),
        ),
        StatusChip(a.status),
      ]),
    );
  }

  Widget _approvalCard(List<Leave> pending) {
    return AppCard(
      color: C.ink,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.approval_rounded, color: C.mint, size: 18),
                const SizedBox(width: 8),
                Text('Menunggu persetujuan',
                    style: T.sans(13,
                        weight: FontWeight.w700, color: Colors.white)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: C.coral, borderRadius: BorderRadius.circular(999)),
                child: Text('${pending.length}',
                    style: T.mono(12,
                        color: Colors.white, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              '${pending.first.employeeName ?? 'Karyawan'} · ${pending.first.typeName ?? 'Cuti'}',
              style: T.sans(12, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Tinjau permintaan',
            color: C.teal,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApprovalsScreen())),
          ),
        ],
      ),
    );
  }
}
