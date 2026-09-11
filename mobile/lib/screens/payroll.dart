import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class PayrollTab extends StatefulWidget {
  const PayrollTab({super.key});
  @override
  State<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<PayrollTab> {
  Future<List<Payroll>>? _f;

  @override
  void initState() {
    super.initState();
    _f = Api.i.payrolls(limit: 40);
  }

  Future<void> _refresh() async {
    final f = Api.i.payrolls(limit: 40);
    setState(() => _f = f);
    await f;
  }

  void _open(Payroll p) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PayslipSheet(p),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.paper,
      appBar: AppBar(
        backgroundColor: C.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Slip Gaji', style: T.sans(20, weight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: C.teal,
        onRefresh: _refresh,
        child: FutureBuilder<List<Payroll>>(
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
                EmptyState(
                    'Belum ada slip gaji terbit.\nSlip muncul setelah HR mempublikasikan payroll.',
                    icon: Icons.receipt_long_rounded)
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

  Widget _card(Payroll p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _open(p),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: C.mint, borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.payments_rounded, color: C.deepTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.periodName ?? 'Periode gaji',
                    style: T.sans(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Gaji bersih', style: T.sans(11.5, color: C.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.rupiah(p.netSalary),
                  style: T.mono(14, weight: FontWeight.w700, color: C.teal)),
              const SizedBox(height: 4),
              StatusChip(p.status),
            ],
          ),
        ]),
      ),
    );
  }
}

class _PayslipSheet extends StatelessWidget {
  final Payroll p;
  const _PayslipSheet(this.p);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: C.border, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slip gaji',
                          style: T.sans(11,
                              weight: FontWeight.w600,
                              color: C.muted,
                              spacing: 0.5)),
                      Text(p.periodName ?? 'Periode',
                          style: T.sans(18, weight: FontWeight.w800)),
                    ],
                  ),
                ),
                StatusChip(p.status),
              ],
            ),
            const SizedBox(height: 18),
            _row('Gaji pokok', p.basicSalary),
            _row('Tunjangan', p.totalAllowance, color: C.accent),
            _row('Lembur', p.totalOvertime),
            if (p.totalBonus != 0) _row('Bonus', p.totalBonus),
            const _Divider(),
            _row('Total kotor', p.grossSalary, bold: true),
            _row('Potongan', -p.totalDeduction, color: C.coral),
            const _Divider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                  color: C.mint, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gaji bersih',
                      style: T.sans(14,
                          weight: FontWeight.w700, color: C.deepTeal)),
                  Text(Fmt.rupiah(p.netSalary),
                      style: T.mono(17,
                          weight: FontWeight.w700, color: C.deepTeal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: T.sans(13,
                  weight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? C.ink : C.muted)),
          Text(Fmt.rupiah(value),
              style: T.mono(13.5,
                  weight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? (bold ? C.ink : C.ink))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: C.divider),
      );
}
