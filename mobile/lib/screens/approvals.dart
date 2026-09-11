import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  Future<List<Leave>>? _f;
  final _decided = <String, String>{};
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _f = Api.i.leaves(status: 'PENDING', limit: 50);
  }

  Future<void> _refresh() async {
    final f = Api.i.leaves(status: 'PENDING', limit: 50);
    setState(() => _f = f);
    await f;
  }

  Future<void> _decide(Leave l, bool approve) async {
    setState(() => _busyId = l.id);
    try {
      approve ? await Api.i.approveLeave(l.id) : await Api.i.rejectLeave(l.id);
      setState(() => _decided[l.id] = approve ? 'APPROVED' : 'REJECTED');
      if (mounted) {
        showToast(context, approve ? 'Cuti disetujui' : 'Cuti ditolak');
      }
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.paper,
      appBar: AppBar(
        backgroundColor: C.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Persetujuan', style: T.sans(20, weight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: C.teal,
        onRefresh: _refresh,
        child: FutureBuilder<List<Leave>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingState();
            }
            if (snap.hasError) {
              return ListView(
                  children: [ErrorState('${snap.error}', onRetry: _refresh)]);
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return ListView(children: const [
                EmptyState('Tidak ada permintaan menunggu.',
                    icon: Icons.done_all_rounded)
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              itemBuilder: (_, i) => _card(items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Leave l) {
    final decided = _decided[l.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: C.mint, borderRadius: BorderRadius.circular(12)),
                child: Text(Fmt.initials(l.employeeName),
                    style:
                        T.sans(14, weight: FontWeight.w700, color: C.deepTeal)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.employeeName ?? 'Karyawan',
                        style: T.sans(14, weight: FontWeight.w700)),
                    Text(l.typeName ?? 'Cuti',
                        style: T.sans(12, color: C.muted)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: C.paper, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Tanggal', Fmt.rentang(l.startDate, l.endDate)),
                  const SizedBox(height: 6),
                  _detail('Durasi',
                      '${Fmt.jumlahHari(l.startDate, l.endDate)} hari'),
                  if ((l.reason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _detail('Alasan', l.reason!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (decided != null)
              Align(
                alignment: Alignment.centerRight,
                child: StatusChip(decided),
              )
            else
              Row(children: [
                Expanded(
                  child: OutlineButton2(
                    label: 'Tolak',
                    color: C.coral,
                    onPressed: _busyId == l.id ? null : () => _decide(l, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Setujui',
                    loading: _busyId == l.id,
                    onPressed: () => _decide(l, true),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _detail(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 64, child: Text(k, style: T.sans(11.5, color: C.muted))),
          Expanded(
              child: Text(v, style: T.sans(12.5, weight: FontWeight.w600))),
        ],
      );
}
