import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});
  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  Future<List<Attendance>>? _f;

  @override
  void initState() {
    super.initState();
    _f = Api.i.attendanceHistory(limit: 40);
  }

  Future<void> _refresh() async {
    final f = Api.i.attendanceHistory(limit: 40);
    setState(() => _f = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.paper,
      appBar: _bar('Absensi'),
      body: RefreshIndicator(
        color: C.teal,
        onRefresh: _refresh,
        child: FutureBuilder<List<Attendance>>(
          future: _f,
          builder: (context, snap) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const _MethodPreview(),
                const SizedBox(height: 20),
                const SectionHeader('Riwayat absensi'),
                if (snap.connectionState != ConnectionState.done)
                  const LoadingState()
                else if (snap.hasError)
                  ErrorState('${snap.error}', onRetry: _refresh)
                else if (snap.data!.isEmpty)
                  const EmptyState('Belum ada riwayat absensi.',
                      icon: Icons.history_rounded)
                else
                  ...snap.data!.map(_row),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(Attendance a) {
    final (day, wd) = Fmt.sel(a.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 38,
          child: Column(children: [
            Text(day, style: T.mono(16, weight: FontWeight.w600)),
            Text(wd,
                style: T.sans(10, color: C.muted, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.tanggal(a.date),
                  style: T.sans(12.5, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                  'Masuk ${Fmt.jam(a.checkIn)} · Pulang ${Fmt.jam(a.checkOut)} · ${Fmt.durasi(a.workingMinutes)}',
                  style: T.mono(11, color: C.muted, weight: FontWeight.w500)),
            ],
          ),
        ),
        StatusChip(a.status),
      ]),
    );
  }
}

class _MethodPreview extends StatefulWidget {
  const _MethodPreview();
  @override
  State<_MethodPreview> createState() => _MethodPreviewState();
}

class _MethodPreviewState extends State<_MethodPreview> {
  int _m = 0;
  static const _labels = ['GPS', 'Selfie', 'QR'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metode absensi', style: T.sans(14, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          SegmentedTabs(
              labels: _labels,
              index: _m,
              onChanged: (i) => setState(() => _m = i)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: _viewport(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.paper, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.place_rounded, size: 18, color: C.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kantor Pusat NUSATEK',
                        style: T.sans(12.5, weight: FontWeight.w600)),
                    Text('Jl. Jend. Sudirman · 24 m dari titik',
                        style: T.mono(11,
                            color: C.muted, weight: FontWeight.w500)),
                  ],
                ),
              ),
              const StatusChip('ACTIVE', label: 'Dalam radius'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _viewport() {
    switch (_m) {
      case 1:
        return _dark(
          child: Container(
            width: 130,
            height: 160,
            decoration: BoxDecoration(
              border:
                  Border.all(color: C.mint.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(90),
            ),
          ),
          badge: 'REC',
          badgeColor: C.coral,
          icon: Icons.face_rounded,
        );
      case 2:
        return _dark(
          child: SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(painter: _QrPainter()),
          ),
          badge: 'SCAN',
          badgeColor: C.mint,
          icon: Icons.qr_code_scanner_rounded,
        );
      default:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: const Color(0xFFE8EDE8),
            child: CustomPaint(
              painter: _MapPainter(),
              child: const Center(
                child:
                    Icon(Icons.location_on_rounded, color: C.coral, size: 34),
              ),
            ),
          ),
        );
    }
  }

  Widget _dark({
    required Widget child,
    required String badge,
    required Color badgeColor,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF12201E),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: child),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(badge,
                    style: T.mono(9.5,
                        color: badgeColor == C.mint ? C.deepTeal : Colors.white,
                        weight: FontWeight.w700)),
              ),
            ),
            Positioned(
              bottom: 12,
              child: Icon(icon, color: C.mint.withValues(alpha: 0.5), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final block = Paint()..color = const Color(0xFFDDE4DD);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8;
    for (var x = 20.0; x < size.width; x += 46) {
      for (var y = 16.0; y < size.height; y += 42) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 30, 26), const Radius.circular(4)),
            block);
      }
    }
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), road);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), road);
    final ring = Paint()
      ..color = C.teal.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), 46, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.mint
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 26.0;
    final w = size.width, h = size.height;
    canvas.drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(0, 0)
          ..lineTo(len, 0),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(w - len, 0)
          ..lineTo(w, 0)
          ..lineTo(w, len),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(0, h - len)
          ..lineTo(0, h)
          ..lineTo(len, h),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(w - len, h)
          ..lineTo(w, h)
          ..lineTo(w, h - len),
        p);
    canvas.drawLine(
        Offset(6, h * 0.5),
        Offset(w - 6, h * 0.5),
        Paint()
          ..color = C.coral
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

PreferredSizeWidget _bar(String title) => AppBar(
      backgroundColor: C.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Text(title, style: T.sans(20, weight: FontWeight.w800)),
    );
