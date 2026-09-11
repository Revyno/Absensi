# AGENTS.md

Panduan untuk AI agent yang bekerja di repo ini. Disintesis dari [PRD.md](PRD.md) dan [DESIGN.md](DESIGN.md).

## Project

**HRIS & Attendance Management System** — manajemen karyawan, absensi, izin/cuti/sakit, approval, payroll, dan BPJS.

- Backend: **Golang + Go Fiber**, **PostgreSQL**, auth **JWT**.
- Mobile: **Flutter / Dart** (client karyawan), HTTP via **Dio** + JWT interceptor.
- API: **REST/JSON**, prefix `/api/v1`.
- Arsitektur awal: **Modular Monolith** (bukan microservices). Dokumentasi: Swagger/OpenAPI. Deploy: Docker + Nginx + Linux.

> Status repo saat ini: spec-only (`PRD.md`, `DESIGN.md`). Belum ada kode. Ikuti struktur & konvensi di bawah saat mulai implementasi.

## Backend architecture

Layered per modul: `Handler → Service → Repository → Database`.

- **Handler** — parse + validate request, call service, return response.
- **Service** — business logic (validasi check-in/out, hitung jam kerja, payroll engine).
- **Repository** — akses DB (query/insert/update/delete). Parameterized query wajib.

Struktur (`internal/<modul>/` berisi `handler.go service.go repository.go model.go dto.go`):

```text
hris-backend/
├── cmd/api/main.go
├── internal/
│   ├── auth/  employee/  attendance/  leave/  payroll/  bpjs/
│   ├── middleware/   (jwt.go, role.go)
│   ├── config/config.go
│   └── database/postgres.go
├── migrations/
├── docs/
├── .env   go.mod   go.sum
```

Flutter: `lib/core/{api,storage,constants,utils}`, `lib/features/{auth,attendance,leave,payroll,profile}`, `lib/shared`, `main.dart`.

## Roles (RBAC)

`SUPER_ADMIN`, `HR`, `MANAGER`, `EMPLOYEE`. Enforce via `role.go` middleware setelah JWT validation.

- `POST /employees` → SUPER_ADMIN, HR
- `POST /attendance/check-in` → EMPLOYEE
- Approval izin/cuti → MANAGER lalu HR.

## API endpoints (`/api/v1`)

| Grup | Endpoints |
|---|---|
| Auth | `POST /auth/login` · `POST /auth/logout` · `POST /auth/refresh` · `GET /auth/me` |
| Employees | `GET/POST /employees` · `GET/PUT/DELETE /employees/:id` |
| Attendance | `POST /attendance/check-in` · `POST /attendance/check-out` · `GET /attendance` · `GET /attendance/history` |
| Leave | `GET/POST /leaves` · `GET/PUT /leaves/:id` · `POST /leaves/:id/approve` · `POST /leaves/:id/reject` |
| Payroll | `GET/POST /payrolls` · `GET /payrolls/:id` · `POST /payrolls/:id/publish` |
| BPJS | `GET/POST /bpjs` · `GET/PUT /bpjs/:id` |

### Response standard

```json
{ "success": true,  "message": "Success", "data": {} }
{ "success": false, "message": "Validation error", "errors": { "email": ["Email is required"] } }
```

## Auth / JWT

- Access token 15–30 menit; refresh token 7–30 hari. Header: `Authorization: Bearer <token>`.
- Payload: `sub`, `employee_id`, `role`, `iat`, `exp`.
- Refresh via `POST /api/v1/auth/refresh`.
- Flutter simpan token di `flutter_secure_storage` (jangan storage tidak aman).

## Database

`users (1:1) employees`; `employees 1:N` → `attendances`, `leave_requests`, `payrolls`, `bpjs`. `departments 1:N positions`.

Tabel inti: `users, employees, departments, positions, attendances, leave_types, leave_requests, payroll_periods, payrolls, bpjs`.

### Aturan bisnis penting

- Check-in hanya 1x/hari; check-out hanya setelah check-in. `working_minutes` dihitung saat check-out.
- Leave status: `Pending → Approved/Rejected/Cancelled`. Employee boleh cancel saat masih Pending. Simpan `approved_by`, `approved_at`.
- Payroll: `Gross = Basic + Allowance + Overtime + Bonus`; `Net = Gross − BPJS − Tax − Deduction`. Draft → publish; employee hanya lihat yang published.

## Security (wajib)

- Password hash **bcrypt** (atau Argon2). Tidak pernah simpan plaintext.
- `JWT_SECRET` dari env; **jangan commit** secret ke git.
- Parameterized query (cegah SQL injection), input validation, RBAC, HTTPS di production.

### .env

```env
APP_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hris
DB_USER=postgres
DB_PASSWORD=password
JWT_SECRET=change-this-secret
ACCESS_TOKEN_DURATION=15m
REFRESH_TOKEN_DURATION=168h
```

## Non-functional

- API response < 500ms; pagination untuk data besar; DB indexing; connection pooling.
- Scalable ke multi department/location/branch/company.

## Development order

1. PostgreSQL → 2. schema/migrations → 3. Go Fiber setup → 4. config → 5. JWT auth → 6. employee → 7. attendance → 8. leave → 9. payroll → 10. Flutter app.

**MVP:** auth+JWT, employee & role mgmt, attendance check-in/out + history, leave request + approval, basic payroll, payslip.
**Pasca-MVP:** GPS/geofencing, face recognition, push/email notification, advanced payroll, multi-branch.
