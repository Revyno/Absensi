import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const teal = Color(0xFF0E6E63);
  static const deepTeal = Color(0xFF0A4F47);
  static const mint = Color(0xFFDCEFEA);
  static const ink = Color(0xFF10221F);

  static const canvas = Color(0xFFEDEAE3);
  static const paper = Color(0xFFF4F1EA);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF5A6B68);
  static const border = Color(0x1410221F);
  static const divider = Color(0x0F10221F);

  static const accent = Color(0xFFC8891C);
  static const coral = Color(0xFFE8613C);
}

class StatusStyle {
  final Color bg;
  final Color fg;
  const StatusStyle(this.bg, this.fg);

  static const present = StatusStyle(Color(0xFFDCEFEA), Color(0xFF0A4F47));
  static const late = StatusStyle(Color(0xFFFBEBD2), Color(0xFF8A5D0B));
  static const leave = StatusStyle(Color(0xFFE4E9F5), Color(0xFF39508C));
  static const wfh = StatusStyle(Color(0xFFEDE7F6), Color(0xFF5B4A8A));
  static const rejected = StatusStyle(Color(0xFFFBE0D8), Color(0xFFC2482A));
  static const neutral = StatusStyle(Color(0xFFE9E6DE), Color(0xFF5A6B68));

  static StatusStyle of(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'PRESENT':
      case 'HADIR':
      case 'APPROVED':
      case 'ACTIVE':
      case 'PUBLISHED':
        return present;
      case 'LATE':
      case 'TERLAMBAT':
      case 'PENDING':
      case 'DRAFT':
        return late;
      case 'LEAVE':
      case 'CUTI':
      case 'DONE':
      case 'CANCELLED':
        return leave;
      case 'WFH':
        return wfh;
      case 'REJECTED':
      case 'INACTIVE':
        return rejected;
      default:
        return neutral;
    }
  }
}

String statusLabel(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PRESENT':
      return 'Hadir';
    case 'LATE':
      return 'Terlambat';
    case 'PENDING':
      return 'Menunggu';
    case 'APPROVED':
      return 'Disetujui';
    case 'REJECTED':
      return 'Ditolak';
    case 'CANCELLED':
      return 'Dibatalkan';
    case 'ACTIVE':
      return 'Aktif';
    case 'DRAFT':
      return 'Draft';
    case 'PUBLISHED':
      return 'Terbit';
    default:
      return raw == null || raw.isEmpty ? '-' : raw;
  }
}

class T {
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = C.ink,
    double? height,
    double? spacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = C.ink,
  }) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);

  static TextStyle get hero =>
      sans(30, weight: FontWeight.w800, color: Colors.white, spacing: -0.5);
  static TextStyle get title => sans(14, weight: FontWeight.w700);
  static TextStyle get cardTitle => sans(13, weight: FontWeight.w700);
  static TextStyle get body => sans(13, height: 1.5, color: C.ink);
  static TextStyle get label =>
      sans(12, weight: FontWeight.w500, color: C.muted);
  static TextStyle get overline =>
      sans(11, weight: FontWeight.w600, color: C.muted, spacing: 0.08 * 11);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: C.teal);
  return base.copyWith(
    scaffoldBackgroundColor: C.paper,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: C.ink, displayColor: C.ink),
    splashFactory: InkRipple.splashFactory,
  );
}

const kCardShadow = [
  BoxShadow(color: Color(0x1A10221F), blurRadius: 30, offset: Offset(0, 10)),
];
