class Fmt {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String rupiah(num? v) {
    final n = (v ?? 0).round();
    final neg = n < 0;
    final digits = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${neg ? '-' : ''}Rp $buf';
  }

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  static String jam(String? iso) {
    final d = _parse(iso);
    if (d == null) return '--.--';
    return '${_two(d.hour)}.${_two(d.minute)}';
  }

  static String durasi(int? minutes) {
    final m = minutes ?? 0;
    if (m <= 0) return '0m';
    final h = m ~/ 60, mm = m % 60;
    if (h == 0) return '${mm}m';
    return '${h}j ${mm}m';
  }

  static String tanggal(String? iso) {
    final d = _parse(iso);
    if (d == null) return '-';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static String rentang(String? startIso, String? endIso) {
    final a = _parse(startIso), b = _parse(endIso);
    if (a == null || b == null) return '-';
    if (a.month == b.month && a.year == b.year) {
      return '${a.day} – ${b.day} ${_months[b.month - 1]} ${b.year}';
    }
    return '${tanggal(startIso)} – ${tanggal(endIso)}';
  }

  static int jumlahHari(String? startIso, String? endIso) {
    final a = _parse(startIso), b = _parse(endIso);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays.abs() + 1;
  }

  static (String, String) sel(String? iso) {
    final d = _parse(iso);
    if (d == null) return ('--', '');
    return (_two(d.day), _days[d.weekday - 1].toUpperCase());
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
