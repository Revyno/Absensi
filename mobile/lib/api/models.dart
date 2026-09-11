String? _s(dynamic v) => v?.toString();
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class Employee {
  final String id;
  final String employeeCode;
  final String fullName;
  final String? phone;
  final String? employmentStatus;
  final double basicSalary;
  final String? joinDate;
  final String? departmentName;
  final String? positionName;
  final String? email;
  final String? role;

  Employee.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        employeeCode = _s(j['employee_code']) ?? '-',
        fullName = _s(j['full_name']) ?? '-',
        phone = _s(j['phone']),
        employmentStatus = _s(j['employment_status']),
        basicSalary = _d(j['basic_salary']),
        joinDate = _s(j['join_date']),
        departmentName = _s((j['department'] ?? const {})['name']),
        positionName = _s((j['position'] ?? const {})['name']),
        email = _s((j['user'] ?? const {})['email']),
        role = _s((j['user'] ?? const {})['role']);
}

class Me {
  final String id;
  final String email;
  final String role;
  final Employee? employee;

  Me.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        email = _s(j['email']) ?? '-',
        role = _s(j['role']) ?? 'EMPLOYEE',
        employee = j['employee'] is Map
            ? Employee.fromJson(Map<String, dynamic>.from(j['employee']))
            : null;

  bool get isManager =>
      role == 'MANAGER' || role == 'HR' || role == 'SUPER_ADMIN';
}

class Attendance {
  final String id;
  final String? date;
  final String? checkIn;
  final String? checkOut;
  final int workingMinutes;
  final String status;
  final String? employeeName;

  Attendance.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        date = _s(j['attendance_date']),
        checkIn = _s(j['check_in']),
        checkOut = _s(j['check_out']),
        workingMinutes = _i(j['working_minutes']),
        status = _s(j['status']) ?? '',
        employeeName = _s((j['employee'] ?? const {})['full_name']);
}

class LeaveType {
  final String id;
  final String name;
  LeaveType.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        name = _s(j['name']) ?? '-';
}

class Leave {
  final String id;
  final String? startDate;
  final String? endDate;
  final String? reason;
  final String status;
  final String? typeName;
  final String? employeeName;

  Leave.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        startDate = _s(j['start_date']),
        endDate = _s(j['end_date']),
        reason = _s(j['reason']),
        status = _s(j['status']) ?? 'PENDING',
        typeName = _s((j['leave_type'] ?? const {})['name']),
        employeeName = _s((j['employee'] ?? const {})['full_name']);
}

class Payroll {
  final String id;
  final double basicSalary,
      totalAllowance,
      totalOvertime,
      totalBonus,
      totalDeduction,
      grossSalary,
      netSalary;
  final String status;
  final String? periodName;

  Payroll.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        basicSalary = _d(j['basic_salary']),
        totalAllowance = _d(j['total_allowance']),
        totalOvertime = _d(j['total_overtime']),
        totalBonus = _d(j['total_bonus']),
        totalDeduction = _d(j['total_deduction']),
        grossSalary = _d(j['gross_salary']),
        netSalary = _d(j['net_salary']),
        status = _s(j['status']) ?? 'draft',
        periodName = _s((j['payroll_period'] ?? const {})['name']);
}

class Bpjs {
  final String id;
  final String? number;
  final String? type;
  final double employeeContribution, companyContribution;
  final String status;

  Bpjs.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']) ?? '',
        number = _s(j['bpjs_number']),
        type = _s(j['bpjs_type']),
        employeeContribution = _d(j['employee_contribution']),
        companyContribution = _d(j['company_contribution']),
        status = _s(j['status']) ?? 'active';
}
