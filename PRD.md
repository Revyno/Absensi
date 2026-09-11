# Product Requirements Document (PRD)

## 1. Product Overview

### Product Name

**HRIS & Attendance Management System**

### Product Description

HRIS & Attendance Management System adalah aplikasi manajemen sumber daya manusia yang dirancang untuk membantu perusahaan dalam mengelola data karyawan, absensi, perizinan, cuti, sakit, payroll, dan informasi BPJS.

Sistem terdiri dari aplikasi mobile berbasis Flutter yang digunakan oleh karyawan serta backend API berbasis Golang dan Go Fiber. Sistem akan menyediakan akses berdasarkan peran pengguna seperti Administrator, Human Resources (HR), Manager, dan Employee.

Tujuan utama sistem adalah mendigitalisasi proses administrasi HR dan absensi karyawan agar proses monitoring, approval, dan perhitungan payroll menjadi lebih terstruktur, akurat, dan efisien.

---

# 2. Problem Statement

Proses manajemen karyawan secara manual memiliki beberapa permasalahan, antara lain:

* Absensi karyawan masih dilakukan secara manual.
* Monitoring kehadiran membutuhkan waktu.
* Pengajuan izin dan sakit dilakukan melalui komunikasi manual.
* Approval izin membutuhkan proses administratif.
* Perhitungan payroll dapat mengalami kesalahan.
* Data karyawan tersebar di beberapa sistem.
* HR membutuhkan dashboard untuk memonitor data karyawan.
* Karyawan membutuhkan akses terhadap informasi payroll dan riwayat absensi.

Sistem ini dirancang untuk menyelesaikan permasalahan tersebut melalui platform digital terintegrasi.

---

# 3. Product Goals

Tujuan utama produk:

1. Digitalisasi absensi karyawan.
2. Mempermudah pengajuan izin, cuti, dan sakit.
3. Menyediakan sistem approval.
4. Membantu HR dalam manajemen karyawan.
5. Mengintegrasikan absensi dengan payroll.
6. Menyediakan informasi payroll kepada karyawan.
7. Menyimpan data BPJS karyawan.
8. Menyediakan sistem akses berdasarkan role.
9. Menyediakan API yang dapat digunakan oleh aplikasi Flutter.
10. Menyediakan sistem autentikasi yang aman menggunakan JWT.

---

# 4. Target Users

## 4.1 Super Admin

Super Admin memiliki akses penuh terhadap sistem.

Tanggung jawab:

* Mengelola pengguna.
* Mengelola role.
* Mengelola permission.
* Mengelola data perusahaan.
* Mengelola konfigurasi sistem.
* Melihat seluruh data sistem.

---

## 4.2 HR Administrator

HR bertanggung jawab terhadap manajemen sumber daya manusia.

Fitur:

* Mengelola data karyawan.
* Mengelola department.
* Mengelola jabatan.
* Memantau absensi.
* Mengelola cuti.
* Mengelola izin.
* Mengelola data BPJS.
* Mengelola payroll.
* Generate payslip.

---

## 4.3 Manager

Manager bertanggung jawab terhadap manajemen karyawan dalam tim.

Fitur:

* Melihat anggota tim.
* Melihat absensi anggota tim.
* Melakukan approval izin.
* Melakukan approval cuti.
* Melihat laporan tim.

---

## 4.4 Employee

Employee menggunakan aplikasi Flutter untuk aktivitas sehari-hari.

Fitur:

* Login.
* Check-in.
* Check-out.
* Melihat status absensi.
* Melihat riwayat absensi.
* Mengajukan izin.
* Mengajukan cuti.
* Mengajukan sakit.
* Melihat status approval.
* Melihat payroll.
* Melihat payslip.
* Melihat informasi BPJS.
* Mengelola profil.

---

# 5. Core Features

## 5.1 Authentication

Sistem menyediakan autentikasi menggunakan JWT.

Fitur:

* Login.
* Logout.
* Refresh token.
* Access token.
* Password hashing.
* Role-based access control.
* Token validation.
* Protected API routes.

---

## 5.2 Employee Management

HR dapat mengelola data karyawan.

Data utama:

* Employee ID.
* Full name.
* Email.
* Phone number.
* Department.
* Position.
* Employment status.
* Join date.
* Salary information.

Fitur:

* Create employee.
* View employee.
* Update employee.
* Deactivate employee.
* Search employee.
* Filter employee.

---

## 5.3 Attendance Management

Karyawan dapat melakukan absensi melalui aplikasi.

Fitur:

* Check-in.
* Check-out.
* Attendance history.
* Working hours calculation.
* Late detection.
* Early leave detection.
* Attendance status.

Data absensi:

* Check-in time.
* Check-out time.
* Working duration.
* Attendance date.
* Status.

Future features:

* GPS location.
* Geofencing.
* Selfie verification.
* Device validation.

---

## 5.4 Leave Management

Karyawan dapat mengajukan permohonan.

Jenis:

* Cuti.
* Izin.
* Sakit.
* Dinas luar.
* Work From Home.

Data:

* Leave type.
* Start date.
* End date.
* Reason.
* Attachment.
* Status.

Status:

* Pending.
* Approved.
* Rejected.
* Cancelled.

---

## 5.5 Approval System

Sistem menyediakan approval workflow.

Flow:

Employee Request

↓

Manager Approval

↓

HR Approval

↓

Final Status

Approval dapat dikonfigurasi berdasarkan:

* Department.
* Position.
* Leave type.
* Organization policy.

---

## 5.6 Payroll Management

Payroll digunakan untuk menghitung gaji karyawan.

Komponen:

### Income

* Basic salary.
* Position allowance.
* Transport allowance.
* Meal allowance.
* Overtime.
* Bonus.
* Incentive.

### Deduction

* BPJS.
* Tax.
* Attendance deduction.
* Late deduction.
* Other deduction.

Formula:

Gross Salary

=

Basic Salary

*

Allowances

*

Overtime

*

Bonus

Net Salary

=

Gross Salary

*

BPJS

*

Tax

*

Other Deductions

---

## 5.7 Payslip

Karyawan dapat melihat payslip.

Informasi:

* Payroll period.
* Basic salary.
* Allowances.
* Overtime.
* Bonus.
* Deductions.
* BPJS contribution.
* Tax deduction.
* Net salary.

Future features:

* Download PDF.
* Email payslip.
* Payslip archive.

---

## 5.8 BPJS Management

HR dapat mengelola informasi BPJS karyawan.

Data:

* BPJS number.
* BPJS type.
* Contribution.
* Company contribution.
* Employee contribution.
* Registration status.

---

# 6. User Flow

## 6.1 Login

Employee

↓

Open Flutter Application

↓

Enter Email and Password

↓

API Authentication

↓

JWT Generated

↓

Access Dashboard

---

## 6.2 Attendance

Employee

↓

Open Attendance Page

↓

Check-in

↓

API Validation

↓

Attendance Created

↓

Employee Working

↓

Check-out

↓

Working Hours Calculated

↓

Attendance Completed

---

## 6.3 Leave Request

Employee

↓

Create Leave Request

↓

Status: Pending

↓

Manager Review

↓

Approved / Rejected

↓

Employee Notification

---

## 6.4 Payroll

HR

↓

Create Payroll Period

↓

Calculate Attendance

↓

Calculate Allowances

↓

Calculate Deduction

↓

Calculate BPJS

↓

Generate Payroll

↓

Publish Payslip

↓

Employee Access Payslip

---

# 7. Functional Requirements

## Authentication

* User dapat login.
* User dapat logout.
* Sistem menggunakan JWT.
* Sistem mendukung refresh token.
* Password harus di-hash.
* API protected menggunakan middleware.
* Role harus divalidasi.

---

## Employee

* HR dapat membuat data employee.
* HR dapat mengubah data employee.
* HR dapat menonaktifkan employee.
* Employee dapat melihat profil sendiri.

---

## Attendance

* Employee dapat check-in.
* Employee dapat check-out.
* Employee hanya dapat check-in satu kali per hari.
* Employee hanya dapat check-out setelah check-in.
* Sistem menghitung durasi kerja.
* Sistem menyimpan riwayat absensi.

---

## Leave

* Employee dapat membuat request.
* Employee dapat membatalkan request pending.
* Manager dapat melakukan approval.
* HR dapat melihat seluruh request.
* Sistem menyimpan approval history.

---

## Payroll

* HR dapat membuat payroll period.
* Sistem dapat menghitung payroll.
* Payroll dapat disimpan sebagai draft.
* Payroll dapat dipublish.
* Employee dapat melihat payroll yang telah dipublish.

---

# 8. Non-Functional Requirements

## Security

* Password hashing menggunakan bcrypt atau Argon2.
* JWT menggunakan secret key yang aman.
* Refresh token disimpan secara aman.
* API menggunakan HTTPS pada production.
* Authorization menggunakan RBAC.
* Input validation diterapkan.
* SQL injection dicegah melalui parameterized query.

---

## Performance

Target:

* API response time < 500ms untuk operasi normal.
* Pagination untuk data besar.
* Database indexing.
* Efficient query.
* Connection pooling.

---

## Scalability

Sistem harus dapat dikembangkan untuk:

* Multi department.
* Multi location.
* Multi branch.
* Multi company.
* Thousands of employees.

---

# 9. Success Metrics

Keberhasilan sistem diukur melalui:

* Akurasi data absensi.
* Kecepatan proses payroll.
* Pengurangan proses manual.
* Pengurangan kesalahan administrasi.
* Jumlah pengguna aktif.
* Response time API.
* Success rate check-in/check-out.

---

# 10. Future Roadmap

## Phase 1

* Authentication.
* Employee management.
* Attendance.
* Leave request.

## Phase 2

* Approval workflow.
* Payroll.
* Payslip.
* BPJS.

## Phase 3

* GPS attendance.
* Geofencing.
* Face verification.
* Push notification.
* Email notification.

## Phase 4

* Multi company.
* Multi branch.
* Analytics dashboard.
* AI HR assistant.
* Advanced reporting.

---

# 11. Technology Stack

## Backend

* Golang
* Go Fiber
* PostgreSQL
* JWT

## Database

* PostgreSQL

## Mobile

* Flutter
* Dart

## API

* REST API
* JSON

## Documentation

* Swagger / OpenAPI

## Deployment

* Docker
* Nginx
* Linux Server

---

# 12. MVP Scope

Fitur awal yang akan dikembangkan:

* Authentication.
* JWT.
* Employee management.
* Role management.
* Attendance check-in.
* Attendance check-out.
* Attendance history.
* Leave request.
* Leave approval.
* Basic payroll.
* Payslip.

Fitur berikut dapat dikembangkan setelah MVP selesai:

* GPS.
* Geofencing.
* Face recognition.
* Push notification.
* Advanced payroll.
* Multi branch.
