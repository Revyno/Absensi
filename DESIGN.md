# Technical Design Document

# HRIS & Employee Attendance Management System

## 1. System Architecture

Sistem menggunakan arsitektur Client-Server.

```text
┌─────────────────────┐
│                     │
│   Flutter Mobile    │
│                     │
│ Employee Application│
│                     │
└──────────┬──────────┘
           │
           │ HTTPS / REST API
           │
           ▼
┌─────────────────────┐
│                     │
│    Golang API       │
│                     │
│      Go Fiber       │
│                     │
├─────────────────────┤
│ Authentication      │
│ Authorization       │
│ Attendance          │
│ Leave               │
│ Payroll             │
│ BPJS                │
│ Employee            │
│                     │
└──────────┬──────────┘
           │
           │
           ▼
┌─────────────────────┐
│                     │
│     PostgreSQL      │
│                     │
└─────────────────────┘
```

---

# 2. Backend Architecture

Backend menggunakan modular architecture.

```text
Client
   │
   ▼
Handler
   │
   ▼
Service
   │
   ▼
Repository
   │
   ▼
Database
```

Penjelasan:

### Handler

Bertanggung jawab menerima HTTP request.

Contoh:

```text
POST /auth/login
```

Handler melakukan:

* Parse request.
* Validate request.
* Call service.
* Return response.

---

### Service

Berisi business logic.

Contoh:

```text
AttendanceService
```

Menangani:

* Validasi check-in.
* Validasi check-out.
* Perhitungan jam kerja.
* Validasi attendance.

---

### Repository

Menangani komunikasi database.

Contoh:

```text
EmployeeRepository
```

Repository melakukan:

* Query employee.
* Insert employee.
* Update employee.
* Delete employee.

---

# 3. Recommended Project Structure

```text
hris-backend/

├── cmd/
│   └── api/
│       └── main.go
│
├── internal/
│
│   ├── auth/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── model.go
│   │   └── dto.go
│
│   ├── employee/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── model.go
│   │   └── dto.go
│
│   ├── attendance/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── model.go
│   │   └── dto.go
│
│   ├── leave/
│   │
│   ├── payroll/
│   │
│   ├── bpjs/
│   │
│   ├── middleware/
│   │   ├── jwt.go
│   │   └── role.go
│   │
│   ├── config/
│   │   └── config.go
│   │
│   └── database/
│       └── postgres.go
│
├── migrations/
│
├── docs/
│
├── .env
├── go.mod
└── go.sum
```

---

# 4. Authentication Architecture

Sistem menggunakan:

* Access Token.
* Refresh Token.
* JWT.

```text
┌─────────────┐
│   Flutter   │
└──────┬──────┘
       │
       │ Login
       ▼
┌─────────────┐
│   Go Fiber  │
│    API      │
└──────┬──────┘
       │
       │ Validate
       ▼
┌─────────────┐
│ PostgreSQL  │
└──────┬──────┘
       │
       │ User Valid
       ▼
┌─────────────┐
│ Generate    │
│ JWT Token   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│                     │
│ Access Token        │
│ Refresh Token       │
│                     │
└─────────────────────┘
       │
       ▼
    Flutter
```

---

# 5. JWT Design

## Access Token

Digunakan untuk mengakses API.

Header:

```http
Authorization: Bearer ACCESS_TOKEN
```

JWT Payload:

```json
{
  "sub": "user_id",
  "employee_id": "employee_id",
  "role": "employee",
  "iat": 123456789,
  "exp": 123457149
}
```

Recommended expiration:

```text
Access Token

15 - 30 Minutes
```

---

## Refresh Token

Digunakan untuk mendapatkan access token baru.

Recommended expiration:

```text
7 - 30 Days
```

Flow:

```text
Access Token Expired
        │
        ▼
Flutter
        │
        ▼
POST /auth/refresh
        │
        ▼
Validate Refresh Token
        │
        ▼
Generate New Access Token
```

---

# 6. JWT Authentication Flow

## Login

```text
Flutter
   │
   │ Email + Password
   ▼
POST /api/v1/auth/login
   │
   ▼
Auth Handler
   │
   ▼
Auth Service
   │
   ├── Find User
   │
   ├── Verify Password
   │
   └── Generate JWT
          │
          ▼
       Response
```

Response:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "token_type": "Bearer"
  }
}
```

---

# 7. JWT Middleware

Middleware digunakan untuk protected route.

```text
Request
   │
   ▼
JWT Middleware
   │
   ├── Invalid Token
   │       │
   │       ▼
   │    401 Unauthorized
   │
   └── Valid Token
           │
           ▼
       API Handler
```

Pseudo code:

```go
func JWTMiddleware() fiber.Handler {
    return func(c *fiber.Ctx) error {

        token := c.Get("Authorization")

        if token == "" {
            return c.Status(401).JSON(fiber.Map{
                "message": "Unauthorized",
            })
        }

        // Validate JWT

        return c.Next()
    }
}
```

---

# 8. Role-Based Access Control

Roles:

```text
SUPER_ADMIN
HR
MANAGER
EMPLOYEE
```

Flow:

```text
Request
   │
   ▼
JWT Validation
   │
   ▼
Get User Role
   │
   ▼
Role Middleware
   │
   ├── Allowed
   │      │
   │      ▼
   │   Continue
   │
   └── Forbidden
          │
          ▼
      403 Forbidden
```

Contoh:

```text
POST /employees

Allowed:

SUPER_ADMIN
HR
```

```text
POST /attendance/check-in

Allowed:

EMPLOYEE
```

---

# 9. Database Design

## users

```text
users

id
email
password
role
is_active
created_at
updated_at
```

---

## employees

```text
employees

id
user_id
employee_code
full_name
phone
department_id
position_id
join_date
employment_status
created_at
updated_at
```

---

## departments

```text
departments

id
name
created_at
```

---

## positions

```text
positions

id
department_id
name
created_at
```

---

## attendance

```text
attendances

id
employee_id
attendance_date

check_in
check_out

working_minutes

status

created_at
updated_at
```

---

## leave_types

```text
leave_types

id
name
description
```

---

## leave_requests

```text
leave_requests

id
employee_id
leave_type_id

start_date
end_date

reason

status

approved_by

approved_at

created_at
updated_at
```

---

## payroll_periods

```text
payroll_periods

id

name

start_date
end_date

status

created_at
updated_at
```

---

## payrolls

```text
payrolls

id

employee_id

payroll_period_id

basic_salary

total_allowance

total_bonus

total_deduction

gross_salary

net_salary

status

created_at
updated_at
```

---

## bpjs

```text
bpjs

id

employee_id

bpjs_number

bpjs_type

employee_contribution

company_contribution

status
```

---

# 10. Database Relationship

```text
users
  │
  │ 1 : 1
  │
employees
  │
  ├────────── attendances
  │
  ├────────── leave_requests
  │
  ├────────── payrolls
  │
  └────────── bpjs
```

---

# 11. Attendance Flow

## Check-In

```text
Employee
   │
   ▼
Flutter
   │
   ▼
POST /attendance/check-in
   │
   ▼
JWT Validation
   │
   ▼
Get Employee ID
   │
   ▼
Validate Attendance
   │
   ├── Already Check-In?
   │
   └── Valid
          │
          ▼
Create Attendance
          │
          ▼
Return Response
```

---

## Check-Out

```text
Employee
   │
   ▼
POST /attendance/check-out
   │
   ▼
JWT Validation
   │
   ▼
Find Today's Attendance
   │
   ▼
Calculate Working Duration
   │
   ▼
Update Attendance
```

---

# 12. Payroll Architecture

```text
Attendance
     │
     ▼
Attendance Summary
     │
     ▼
Payroll Engine
     │
     ├── Basic Salary
     │
     ├── Allowances
     │
     ├── Overtime
     │
     ├── Bonus
     │
     ├── BPJS
     │
     └── Deduction
            │
            ▼
        Net Salary
```

Formula:

```text
Gross Salary

=

Basic Salary
+
Allowance
+
Overtime
+
Bonus
```

```text
Net Salary

=

Gross Salary
-
BPJS
-
Tax
-
Deduction
```

---

# 13. API Endpoint Design

## Authentication

```text
POST /api/v1/auth/login

POST /api/v1/auth/logout

POST /api/v1/auth/refresh

GET /api/v1/auth/me
```

---

## Employees

```text
GET /api/v1/employees

POST /api/v1/employees

GET /api/v1/employees/:id

PUT /api/v1/employees/:id

DELETE /api/v1/employees/:id
```

---

## Attendance

```text
POST /api/v1/attendance/check-in

POST /api/v1/attendance/check-out

GET /api/v1/attendance

GET /api/v1/attendance/history
```

---

## Leave

```text
GET /api/v1/leaves

POST /api/v1/leaves

GET /api/v1/leaves/:id

PUT /api/v1/leaves/:id

POST /api/v1/leaves/:id/approve

POST /api/v1/leaves/:id/reject
```

---

## Payroll

```text
GET /api/v1/payrolls

POST /api/v1/payrolls

GET /api/v1/payrolls/:id

POST /api/v1/payrolls/:id/publish
```

---

## BPJS

```text
GET /api/v1/bpjs

POST /api/v1/bpjs

GET /api/v1/bpjs/:id

PUT /api/v1/bpjs/:id
```

---

# 14. API Response Standard

## Success

```json
{
  "success": true,
  "message": "Success",
  "data": {}
}
```

---

## Error

```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "email": [
      "Email is required"
    ]
  }
}
```

---

# 15. Security

## Password

Password harus menggunakan:

```text
bcrypt
```

Flow:

```text
Password
   │
   ▼
bcrypt Hash
   │
   ▼
PostgreSQL
```

---

## JWT Secret

Gunakan environment variable:

```env
JWT_SECRET=your-super-secret-key
```

Jangan pernah commit JWT secret ke GitHub.

---

## Environment

Contoh:

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

---

# 16. Flutter Integration

Flutter menggunakan API:

```text
Flutter
    │
    ▼
Dio HTTP Client
    │
    ▼
JWT Interceptor
    │
    ▼
Go Fiber API
```

Flow:

```text
Request
   │
   ▼
Dio Interceptor
   │
   ├── Get Access Token
   │
   └── Add Authorization Header
          │
          ▼
       API Request
```

Header:

```http
Authorization: Bearer JWT_TOKEN
```

---

# 17. Token Storage

Flutter menyimpan token menggunakan:

```text
flutter_secure_storage
```

Jangan menyimpan token sensitif menggunakan storage yang tidak aman.

Data:

```text
access_token
refresh_token
```

---

# 18. Recommended Flutter Architecture

```text
lib/

├── core/
│   ├── api/
│   ├── storage/
│   ├── constants/
│   └── utils/
│
├── features/
│
│   ├── auth/
│   │
│   ├── attendance/
│   │
│   ├── leave/
│   │
│   ├── payroll/
│   │
│   └── profile/
│
├── shared/
│
└── main.dart
```

---

# 19. Recommended Development Flow

```text
1. Setup PostgreSQL

        ↓

2. Create Database Schema

        ↓

3. Setup Go Fiber

        ↓

4. Setup Configuration

        ↓

5. Setup JWT Authentication

        ↓

6. Create Employee Module

        ↓

7. Create Attendance Module

        ↓

8. Create Leave Module

        ↓

9. Create Payroll Module

        ↓

10. Create Flutter Application
```

---

# 20. Deployment Architecture

```text
Internet
    │
    ▼
Nginx
    │
    ▼
Go Fiber API
    │
    ▼
PostgreSQL
```

Recommended:

```text
Ubuntu Server

Docker

Nginx

Go Fiber

PostgreSQL
```

Production:

```text
https://api.company.com
```

Flutter:

```text
https://api.company.com/api/v1
```

---

# 21. Future Architecture

Untuk pengembangan sistem:

```text
Flutter
Web Dashboard
       │
       ▼
    API Gateway
       │
       ▼
    Go Backend
       │
       ├── Auth
       ├── Employee
       ├── Attendance
       ├── Payroll
       ├── Leave
       └── Notification
```

Sistem awal direkomendasikan menggunakan:

```text
Modular Monolith
```

Bukan microservices.

Alasannya:

* Lebih mudah dikembangkan.
* Lebih murah.
* Cocok untuk tim kecil.
* Lebih mudah deployment.
* Lebih mudah debugging.

Microservices dapat dipertimbangkan ketika sistem dan jumlah pengguna sudah berkembang secara signifikan.
