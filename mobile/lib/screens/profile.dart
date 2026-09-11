import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class _ProfileData {
  final Employee employee;
  final List<Bpjs> bpjs;
  _ProfileData(this.employee, this.bpjs);
}

class ProfileTab extends StatefulWidget {
  final Me me;
  final Future<void> Function() onLogout;
  const ProfileTab({super.key, required this.me, required this.onLogout});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<_ProfileData>? _f;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<_ProfileData> _load() async {
    final emp = await Api.i.myProfile();
    List<Bpjs> b = [];
    try {
      b = await Api.i.bpjs();
    } catch (_) {}
    return _ProfileData(emp, b);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _f = f);
    await f;
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar akun?', style: T.sans(16, weight: FontWeight.w700)),
        content: Text('Anda perlu login kembali untuk mengakses aplikasi.',
            style: T.sans(13, color: C.muted, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: T.sans(13, color: C.muted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Keluar',
                  style: T.sans(13, weight: FontWeight.w700, color: C.coral))),
        ],
      ),
    );
    if (ok == true) await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.paper,
      body: RefreshIndicator(
        color: C.teal,
        onRefresh: _refresh,
        child: FutureBuilder<_ProfileData>(
          future: _f,
          builder: (context, snap) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(snap.data?.employee)),
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

  Widget _header(Employee? e) {
    final name = e?.fullName ?? widget.me.employee?.fullName ?? widget.me.email;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 48),
      decoration: const BoxDecoration(
        color: C.deepTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: C.mint, borderRadius: BorderRadius.circular(20)),
            child: Text(Fmt.initials(name),
                style: T.sans(26, weight: FontWeight.w800, color: C.deepTeal)),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: T.sans(18, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(e?.positionName ?? widget.me.role,
              style: T.sans(12.5, color: C.mint.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _body(_ProfileData d) {
    final e = d.employee;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          AppCard(
            child: Column(
              children: [
                _row('NIK', e.employeeCode, mono: true),
                _row('Email', e.email ?? widget.me.email),
                _row('Telepon', e.phone ?? '-', mono: true),
                _row('Departemen', e.departmentName ?? '-'),
                _row('Posisi', e.positionName ?? '-'),
                _row('Bergabung', Fmt.tanggal(e.joinDate)),
                _row('Gaji pokok', Fmt.rupiah(e.basicSalary), mono: true),
                _row('Status', statusLabel(e.employmentStatus), last: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('BPJS'),
          if (d.bpjs.isEmpty)
            const EmptyState('Belum ada data BPJS.',
                icon: Icons.health_and_safety_outlined)
          else
            ...d.bpjs.map(_bpjsCard),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: C.coral.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout_rounded, color: C.coral, size: 18),
            label: Text('Keluar',
                style: T.sans(14, weight: FontWeight.w700, color: C.coral)),
          ),
        ]),
      ),
    );
  }

  Widget _bpjsCard(Bpjs b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BPJS ${b.type ?? ''}'.trim(),
                      style: T.sans(14, weight: FontWeight.w700)),
                  StatusChip(b.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(b.number ?? '-',
                  style: T.mono(13, weight: FontWeight.w600, color: C.muted)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _mini(
                      'Iuran karyawan', Fmt.rupiah(b.employeeContribution)),
                ),
                Expanded(
                  child: _mini(
                      'Iuran perusahaan', Fmt.rupiah(b.companyContribution)),
                ),
              ]),
            ],
          ),
        ),
      );

  Widget _mini(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.sans(11, color: C.muted)),
          const SizedBox(height: 2),
          Text(value, style: T.mono(12.5, weight: FontWeight.w600)),
        ],
      );

  Widget _row(String label, String value,
      {bool mono = false, bool last = false}) {
    return Container(
      decoration: BoxDecoration(
        border:
            last ? null : const Border(bottom: BorderSide(color: C.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 96,
              child: Text(label, style: T.sans(12.5, color: C.muted))),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: mono
                    ? T.mono(12.5, weight: FontWeight.w600)
                    : T.sans(12.5, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
