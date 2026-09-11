# NUSATEK HRIS — Mobile (Flutter)

Employee app untuk backend `hris-backend`. Satu desain, jalan di iOS, Android, web, Windows.
Mengikuti design system di `HRIS Employee App.dc.html` (palet teal, angka mono, kartu absensi menembus hero).

## Jalankan

1. **Backend hidup dulu** (dari `../backend`): `go run ./cmd/api` → `http://localhost:3000`.
   Butuh `DATABASE_URL` (Neon) di `backend/.env`. Seed demo: `go run ./cmd/seed`.
2. **App:**
   ```
   flutter pub get
   flutter run           # pilih device
   flutter run -d chrome # web (CORS backend sudah aktif)
   ```

## Base URL API

Default `http://localhost:3000` — cocok untuk **web, Windows desktop, iOS simulator**.
Ubah lewat tombol **"Ubah server API"** di layar login (tersimpan di device):

| Target | Base URL |
|---|---|
| Web / Windows / iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| HP fisik (satu WiFi) | `http://<IP-PC>:3000` |

## Akun demo (seed, sandi `password123`)

| Peran | Email |
|---|---|
| Karyawan | `budi@lsi.com` |
| Manajer | `manager@lsi.com` (lihat kartu + layar Persetujuan) |
| HR | `hr@lsi.com` |

## Yang sudah terhubung ke API

- Login / refresh token otomatis (retry 401), logout.
- Beranda: absensi hari ini + **check-in / check-out live**, aksi cepat, aktivitas terakhir, antrean approval (manajer).
- Absensi: riwayat + preview 3 metode. Check-in lewat **verifikasi nyata** (GPS geofence / selfie kamera depan / scan QR kantor).
- Cuti: daftar, **ajukan** (tipe + tanggal + alasan), batalkan; **setujui/tolak** (manajer).
- Slip gaji: daftar + detail slip (hanya yang sudah *published* untuk EMPLOYEE).
- Profil: data karyawan + BPJS.

## Catatan

- **Slip gaji karyawan kosong** sampai HR mem-*publish* payroll — seed membuatnya `draft`.
  Login HR → `POST /api/v1/payrolls/{id}/publish`, atau tes daftar via akun manajer/HR.
- Font (Plus Jakarta Sans, IBM Plex Mono) via `google_fonts` → butuh internet saat pertama render.

## Verifikasi lapangan (baru)

- **GPS** (`geolocator`): jarak ke titik kantor; check-in hanya dalam radius (default Sudirman, 150 m).
  Ada tombol **"Jadikan lokasi ini kantor"** untuk set titik saat testing.
- **Selfie** (`image_picker`): kamera depan; foto jadi bukti (client-side, tak dikirim — endpoint tak terima body).
- **QR** (`mobile_scanner`): cocokkan QR kantor (token `NUSATEK-HQ`).
- **Notifikasi lokal** (`flutter_local_notifications`): konfirmasi saat check-in/out + pengingat harian (Asia/Jakarta).
  Bukan FCM/push server — butuh Firebase + endpoint push (belum ada). Local notif sbagai gantinya.
- **Cache offline**: respons GET terakhir disimpan di `shared_preferences`, disajikan saat jaringan mati.

Izin: Android `AndroidManifest.xml` (lokasi/kamera/notif) + core library desugaring di `build.gradle.kts`
(wajib untuk flutter_local_notifications 17). iOS `Info.plist` (NSLocation/NSCamera usage).
Di web/desktop capture tak selalu ada → sheet punya **"Lewati verifikasi (dev)"** agar alur API tetap teruji.
