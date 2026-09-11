import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/api.dart';
import '../services/location.dart';
import '../services/notifications.dart';
import '../theme.dart';
import '../widgets/ui.dart';

Future<bool?> showCheckInSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CheckInSheet(),
    );

const _expectedQr = 'NUSATEK-HQ';

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet();
  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  int _m = 0;
  static const _labels = ['GPS', 'Selfie', 'QR'];

  bool _verified = false;
  bool _working = false;
  bool _posting = false;
  String? _detail;
  String? _error;
  String? _selfiePath;
  MobileScannerController? _scanner;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  void _pick(int i) {
    if (i == _m) return;
    _scanner?.dispose();
    _scanner = null;
    setState(() {
      _m = i;
      _verified = false;
      _detail = null;
      _error = null;
      _selfiePath = null;
    });
  }

  Future<void> _verifyGps() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final pos = await LocationService.i.current();
      final d = LocationService.i.distanceTo(pos);
      final ok = d <= LocationService.i.radius;
      setState(() {
        _verified = ok;
        _detail =
            ok ? 'Dalam radius · ${d.toStringAsFixed(0)} m dari kantor' : null;
        _error = ok
            ? null
            : 'Di luar radius (${d.toStringAsFixed(0)} m). Batas ${LocationService.i.radius.toStringAsFixed(0)} m.';
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pinOffice() async {
    setState(() => _working = true);
    try {
      final pos = await LocationService.i.current();
      await LocationService.i.setOffice(pos.latitude, pos.longitude);
      setState(() {
        _verified = true;
        _detail = 'Kantor di-set ke lokasi ini · 0 m';
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _verifySelfie() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        imageQuality: 70,
      );
      if (x == null) {
        setState(() => _error = 'Selfie dibatalkan.');
        return;
      }
      setState(() {
        _selfiePath = x.path;
        _verified = true;
        _detail = 'Selfie terekam';
      });
    } catch (e) {
      setState(() => _error = 'Kamera tidak tersedia: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _onQr(BarcodeCapture cap) {
    if (_verified) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
    if (raw == null) return;
    if (raw.trim() == _expectedQr) {
      _scanner?.stop();
      setState(() {
        _verified = true;
        _detail = 'QR kantor cocok';
        _error = null;
      });
    } else {
      setState(() => _error = 'QR tidak dikenali: $raw');
    }
  }

  Future<void> _submit() async {
    setState(() => _posting = true);
    try {
      final a = await Api.i.checkIn();
      await NotificationService.i.show(
          'Check-in berhasil', 'Masuk ${a.checkIn ?? ''} · ${_labels[_m]}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showToast(context, '$e', error: true);
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: C.border,
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Verifikasi check-in',
                  style: T.sans(17, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Pilih satu metode untuk memastikan kehadiran.',
                  style: T.sans(12, color: C.muted)),
              const SizedBox(height: 14),
              SegmentedTabs(labels: _labels, index: _m, onChanged: _pick),
              const SizedBox(height: 14),
              AspectRatio(aspectRatio: 16 / 11, child: _viewport()),
              const SizedBox(height: 12),
              _status(),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Check-in sekarang',
                icon: Icons.login_rounded,
                loading: _posting,
                onPressed: _verified ? _submit : null,
              ),
              if (!_isMobile) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _verified = true;
                      _detail = 'Dilewati (mode dev)';
                      _error = null;
                    }),
                    child: Text('Lewati verifikasi (dev)',
                        style: T.sans(12, color: C.muted)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewport() {
    switch (_m) {
      case 1:
        return _frame(
          _selfiePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(_selfiePath!), fit: BoxFit.cover),
                )
              : _hint(Icons.face_rounded, 'Ketuk untuk ambil selfie'),
          onTap: _working ? null : _verifySelfie,
        );
      case 2:
        _scanner ??= MobileScannerController();
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(controller: _scanner, onDetect: _onQr),
        );
      default:
        return _frame(
          _hint(Icons.my_location_rounded,
              _verified ? 'Lokasi terverifikasi' : 'Ketuk untuk cek lokasi'),
          onTap: _working ? null : _verifyGps,
        );
    }
  }

  Widget _frame(Widget child, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: C.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
          ),
          child: Center(
            child: _working
                ? const CircularProgressIndicator(
                    color: C.teal, strokeWidth: 2.4)
                : child,
          ),
        ),
      );

  Widget _hint(IconData icon, String text) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _verified ? C.teal : C.muted, size: 30),
          const SizedBox(height: 8),
          Text(text, style: T.sans(12, color: C.muted)),
        ],
      );

  Widget _status() {
    if (_error != null) {
      return _pill(Icons.error_outline_rounded, _error!, C.coral);
    }
    if (_verified) {
      return Column(
        children: [
          _pill(Icons.verified_rounded, _detail ?? 'Terverifikasi', C.teal),
          if (_m == 0 && _isMobile) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _working ? null : _pinOffice,
              icon:
                  const Icon(Icons.push_pin_outlined, size: 15, color: C.muted),
              label: Text('Jadikan lokasi ini kantor',
                  style: T.sans(11.5, color: C.muted)),
            ),
          ],
        ],
      );
    }
    return _pill(Icons.info_outline_rounded, 'Belum terverifikasi', C.muted);
  }

  Widget _pill(IconData icon, String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: T.sans(11.5, weight: FontWeight.w600, color: color))),
        ]),
      );
}
