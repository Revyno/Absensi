import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api i = Api._();

  static const _kBase = 'base_url';
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  static const defaultBase = 'http://localhost:3000';

  late final Dio _dio;
  late SharedPreferences _prefs;
  String? _access;
  String? _refresh;

  String get baseUrl => _prefs.getString(_kBase) ?? defaultBase;
  bool get isLoggedIn => (_access ?? '').isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _access = _prefs.getString(_kAccess);
    _refresh = _prefs.getString(_kRefresh);
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      validateStatus: (_) => true,
    ));
  }

  Future<void> setBaseUrl(String url) async {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    await _prefs.setString(_kBase, u);
  }

  Map<String, dynamic> get _authHeader =>
      _access == null ? {} : {'Authorization': 'Bearer $_access'};

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) {
    return _dio.request(
      '$baseUrl$path',
      queryParameters: query,
      data: body,
      options: Options(
        method: method,
        headers: auth ? _authHeader : null,
        contentType: 'application/json',
      ),
    );
  }

  Future<dynamic> _req(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final cacheable = method == 'GET';
    Response res;
    try {
      res = await _send(method, path, query: query, body: body, auth: auth);
    } on DioException catch (e) {
      if (cacheable) {
        final cached = _readCache(path, query);
        if (cached != null) return cached;
      }
      throw ApiException(
          'Tidak bisa menghubungi server.\n$baseUrl\n(${e.type.name})');
    }

    final code = res.statusCode ?? 0;
    if (code == 401 && auth && retry && (_refresh ?? '').isNotEmpty) {
      if (await _tryRefresh()) {
        return _req(method, path,
            query: query, body: body, auth: auth, retry: false);
      }
    }

    final data = res.data;
    if (code >= 200 && code < 300) {
      final out =
          (data is Map && data.containsKey('data')) ? data['data'] : data;
      if (cacheable) _writeCache(path, query, out);
      return out;
    }
    final msg =
        (data is Map ? data['message'] : null)?.toString() ?? 'Error $code';
    throw ApiException(msg, code);
  }

  String _cacheKey(String path, Map<String, dynamic>? query) {
    final q = (query == null || query.isEmpty)
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return 'cache:$path$q';
  }

  void _writeCache(String path, Map<String, dynamic>? query, dynamic data) {
    try {
      _prefs.setString(_cacheKey(path, query), jsonEncode(data));
    } catch (_) {}
  }

  dynamic _readCache(String path, Map<String, dynamic>? query) {
    final raw = _prefs.getString(_cacheKey(path, query));
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _tryRefresh() async {
    try {
      final res = await _send('POST', '/api/v1/auth/refresh',
          body: {'refresh_token': _refresh}, auth: false);
      if (res.statusCode == 200 && res.data is Map) {
        await _storeTokens(res.data['data']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _storeTokens(dynamic data) async {
    if (data is! Map) return;
    _access = data['access_token']?.toString();
    _refresh = data['refresh_token']?.toString();
    await _prefs.setString(_kAccess, _access ?? '');
    await _prefs.setString(_kRefresh, _refresh ?? '');
  }

  Future<void> login(String email, String password) async {
    final data = await _req('POST', '/api/v1/auth/login',
        body: {'email': email, 'password': password}, auth: false);
    await _storeTokens(data);
    if (!isLoggedIn) throw ApiException('Login gagal.');
  }

  Future<void> logout() async {
    _access = null;
    _refresh = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
  }

  Future<Me> me() async => Me.fromJson(
      Map<String, dynamic>.from(await _req('GET', '/api/v1/auth/me')));

  Future<Employee> myProfile() async => Employee.fromJson(
      Map<String, dynamic>.from(await _req('GET', '/api/v1/employees/me')));

  Future<Attendance> checkIn() async =>
      Attendance.fromJson(Map<String, dynamic>.from(
          await _req('POST', '/api/v1/attendance/check-in')));

  Future<Attendance> checkOut() async =>
      Attendance.fromJson(Map<String, dynamic>.from(
          await _req('POST', '/api/v1/attendance/check-out')));

  Future<List<Attendance>> attendanceHistory({int limit = 30}) async {
    final list = await _req('GET', '/api/v1/attendance/history',
        query: {'limit': limit});
    return _mapList(list, Attendance.fromJson);
  }

  Future<List<LeaveType>> leaveTypes() async =>
      _mapList(await _req('GET', '/api/v1/leave-types'), LeaveType.fromJson);

  Future<List<Leave>> leaves({String? status, int limit = 30}) async {
    final list = await _req('GET', '/api/v1/leaves',
        query: {'limit': limit, if (status != null) 'status': status});
    return _mapList(list, Leave.fromJson);
  }

  Future<void> createLeave({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) =>
      _req('POST', '/api/v1/leaves', body: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      });

  Future<void> cancelLeave(String id) =>
      _req('POST', '/api/v1/leaves/$id/cancel');
  Future<void> approveLeave(String id) =>
      _req('POST', '/api/v1/leaves/$id/approve');
  Future<void> rejectLeave(String id) =>
      _req('POST', '/api/v1/leaves/$id/reject');

  Future<List<Payroll>> payrolls({int limit = 30}) async => _mapList(
      await _req('GET', '/api/v1/payrolls', query: {'limit': limit}),
      Payroll.fromJson);

  Future<Payroll> payroll(String id) async => Payroll.fromJson(
      Map<String, dynamic>.from(await _req('GET', '/api/v1/payrolls/$id')));

  Future<List<Bpjs>> bpjs() async =>
      _mapList(await _req('GET', '/api/v1/bpjs'), Bpjs.fromJson);

  static List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList();
  }
}
