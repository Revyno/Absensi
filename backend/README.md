# HRIS Backend

Go Fiber + GORM + PostgreSQL (Neon). Implementasi PRD: auth, employee, department, position, attendance, leave, payroll, BPJS.

## Jalankan

```bash
cd backend
cp .env.example .env        # lalu isi DATABASE_URL dari Neon + ganti JWT_SECRET
go run ./cmd/api
```

Saat start: auto-migrate semua tabel + seed akun `SUPER_ADMIN` (default `admin@hris.local` / `admin123`). Server di `:3000`.

Cek: `GET http://localhost:3000/health`

### DATABASE_URL (Neon)
Dashboard Neon → **Connection Details** → copy string:
```
postgresql://user:password@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require
```

## Auth cepat

```bash
# login
curl -X POST localhost:3000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@hris.local","password":"admin123"}'
# pakai access_token -> header: Authorization: Bearer <token>
```

## Endpoints (`/api/v1`)

| Modul | Endpoint | Role |
|---|---|---|
| Auth | `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `GET /auth/me` | public / authed |
| Employee | `GET /employees` · `POST /employees` · `GET /employees/me` · `GET/PUT/DELETE /employees/:id` | authed / HR+admin tulis |
| Department | `GET/POST /departments` · `GET/PUT/DELETE /departments/:id` | authed / HR+admin tulis |
| Position | `GET/POST /positions` · `GET/PUT/DELETE /positions/:id` | authed / HR+admin tulis |
| Attendance | `POST /attendance/check-in` · `POST /attendance/check-out` · `GET /attendance` · `GET /attendance/history` | authed |
| Leave type | `GET /leave-types` · `POST /leave-types` | authed / HR+admin tulis |
| Leave | `GET /leaves` · `POST /leaves` · `GET /leaves/:id` · `POST /leaves/:id/cancel` · `POST /leaves/:id/approve` · `POST /leaves/:id/reject` | approve/reject: Manager+ |
| Payroll period | `GET /payroll-periods` · `POST /payroll-periods` | Manager+ / HR+admin tulis |
| Payroll | `GET /payrolls` · `POST /payrolls` · `GET /payrolls/:id` · `POST /payrolls/:id/publish` | HR+admin tulis; employee lihat published miliknya |
| BPJS | `GET/POST /bpjs` · `GET/PUT /bpjs/:id` | authed / HR+admin tulis |

Response standar: `{ "success", "message", "data" }`; list menambah `meta` (page/limit/total). List mendukung `?page`, `?limit`, dan filter (`?search`, `?employee_id`, `?status`, `?date` tergantung modul).

## Struktur

Layered per modul (`handler → service → repository`), model terpusat di `internal/models` agar relasi GORM lintas-modul tanpa import cycle.

```
cmd/api/main.go            bootstrap: config → db → migrate → seed → router
internal/
  config/   database/      env loader, koneksi + auto-migrate
  models/                  semua GORM model + AllModels()
  common/                  response, validator, jwt, pagination, date, context
  middleware/              JWTProtected, RequireRole
  auth/ employee/ attendance/ leave/ payroll/   handler+service+repository+dto
  department/ position/ bpjs/                    thin CRUD (1 file)
  router/                  wiring semua route
```

## Catatan / simplifikasi

- **Data layer GORM** (bukan raw SQL di DESIGN.md) → auto-migrate, lebih sedikit kode. Tetap parameterized.
- **Models terpusat** (bukan `model.go` per modul) → hindari import cycle.
- **department/position/bpjs** thin (handler langsung ke DB) karena CRUD sederhana.
- **Payslip** = `GET /payrolls/:id` (belum PDF/email — future roadmap).
- **Late detection** pakai ambang jam 09:00 hardcoded (`attendance/service.go`) → pindah ke company policy saat multi-shift.
- **BPJS** belum auto-masuk ke `total_deduction` payroll (HR input manual) → enhancement berikutnya.
- Approval: 1 tahap (Manager **atau** HR/admin). Flow 2-tahap (Manager → HR) di DESIGN belum diimplement.
- Logout stateless (client buang token); belum ada refresh-token revocation/blacklist.

## Test

```bash
go test ./...   # payroll formula
```
