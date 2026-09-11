import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'approvals.dart';

class LeavesTab extends StatefulWidget {
  final Me me;
  const LeavesTab({super.key, required this.me});
  @override
  State<LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends State<LeavesTab> {
  Future<List<Leave>>? _f;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _f = Api.i.leaves(limit: 40);
  }

  Future<void> _refresh() async {
    final f = Api.i.leaves(limit: 40);
    setState(() => _f = f);
    await f;
  }

  Future<void> _cancel(Leave l) async {
    setState(() => _busyId = l.id);
    try {
      await Api.i.cancelLeave(l.id);
      if (mounted) showToast(context, 'Pengajuan dibatalkan');
      await _refresh();
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openApply() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ApplyLeaveSheet(),
    );
    if (ok == true) {
      if (mounted) showToast(context, 'Pengajuan cuti terkirim');
      _refresh();
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
        title: Text('Cuti', style: T.sans(20, weight: FontWeight.w800)),
        actions: [
          if (widget.me.isManager)
            IconButton(
              tooltip: 'Persetujuan',
              icon: const Icon(Icons.approval_rounded, color: C.deepTeal),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApprovalsScreen())),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApply,
        backgroundColor: C.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Ajukan',
            style: T.sans(13, weight: FontWeight.w700, color: Colors.white)),
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
                EmptyState('Belum ada pengajuan cuti.',
                    icon: Icons.beach_access_rounded)
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length,
              itemBuilder: (_, i) => _card(items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Leave l) {
    final isPending = l.status.toUpperCase() == 'PENDING';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(l.typeName ?? 'Cuti',
                      style: T.sans(14, weight: FontWeight.w700)),
                ),
                StatusChip(l.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: C.muted),
              const SizedBox(width: 6),
              Text(Fmt.rentang(l.startDate, l.endDate),
                  style: T.mono(12, color: C.ink, weight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text('· ${Fmt.jumlahHari(l.startDate, l.endDate)} hari',
                  style: T.sans(11.5, color: C.muted)),
            ]),
            if ((l.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(l.reason!, style: T.sans(12, color: C.muted, height: 1.4)),
            ],
            if (widget.me.isManager && (l.employeeName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Oleh ${l.employeeName}',
                  style: T.sans(11.5, weight: FontWeight.w600, color: C.teal)),
            ],
            if (isPending && !widget.me.isManager) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busyId == l.id ? null : () => _cancel(l),
                  icon: _busyId == l.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: C.coral))
                      : const Icon(Icons.close_rounded,
                          size: 16, color: C.coral),
                  label: Text('Batalkan',
                      style: T.sans(12.5,
                          weight: FontWeight.w700, color: C.coral)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplyLeaveSheet extends StatefulWidget {
  const _ApplyLeaveSheet();
  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  final _reason = TextEditingController();
  List<LeaveType> _types = [];
  LeaveType? _type;
  DateTime? _start;
  DateTime? _end;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final t = await Api.i.leaveTypes();
      setState(() {
        _types = t;
        _type = t.isNotEmpty ? t.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick({required bool start}) async {
    final now = DateTime.now();
    final init = start ? (_start ?? now) : (_end ?? _start ?? now);
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _start = d;
        if (_end != null && _end!.isBefore(d)) _end = d;
      } else {
        _end = d;
      }
    });
  }

  Future<void> _submit() async {
    if (_type == null || _start == null || _end == null) {
      setState(() => _error = 'Lengkapi tipe cuti dan tanggal.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Api.i.createLeave(
        leaveTypeId: _type!.id,
        startDate: _iso(_start!),
        endDate: _iso(_end!),
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = '$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            Text('Ajukan cuti', style: T.sans(18, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (_loading)
              const LoadingState()
            else ...[
              Text('Tipe cuti', style: T.label),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: C.paper, borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeaveType>(
                    value: _type,
                    isExpanded: true,
                    items: _types
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.name, style: T.sans(13.5))))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _dateField(
                        'Mulai',
                        _start == null ? null : _iso(_start!),
                        () => _pick(start: true))),
                const SizedBox(width: 10),
                Expanded(
                    child: _dateField(
                        'Selesai',
                        _end == null ? null : _iso(_end!),
                        () => _pick(start: false))),
              ]),
              const SizedBox(height: 12),
              Text('Alasan', style: T.label),
              const SizedBox(height: 6),
              TextField(
                controller: _reason,
                maxLines: 3,
                style: T.sans(13.5),
                decoration: InputDecoration(
                  hintText: 'Contoh: Liburan keluarga',
                  hintStyle: T.sans(13, color: C.muted),
                  filled: true,
                  fillColor: C.paper,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: T.sans(12, color: C.coral)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Kirim pengajuan',
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: C.paper, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: T.sans(10.5, color: C.muted)),
            const SizedBox(height: 2),
            Text(value ?? 'Pilih',
                style: value == null
                    ? T.sans(13, color: C.muted)
                    : T.mono(13, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
