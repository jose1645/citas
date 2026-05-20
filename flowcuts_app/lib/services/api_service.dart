import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  int? _shopId;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.keyToken);
    _shopId = prefs.getInt(AppConstants.keyShopId) ?? AppConstants.defaultShopId;
  }

  int get shopId => _shopId ?? AppConstants.defaultShopId;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ── Headers ────────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyToken, data['token']);
      await prefs.setInt(AppConstants.keyUserId, data['user_id']);
      await prefs.setString(AppConstants.keyUsername, data['username']);
      await prefs.setBool(AppConstants.keyIsOwner, data['is_owner'] ?? false);
      await prefs.setInt(AppConstants.keyShopId, AppConstants.defaultShopId);
      _shopId = AppConstants.defaultShopId;
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['detail'] ?? 'Error al iniciar sesión'};
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Future<DashboardStats> getDashboard([int? shopId]) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/mobile/dashboard/$id'),
      headers: _headers,
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar dashboard: ${response.statusCode}');
  }

  // ── Appointments ───────────────────────────────────────────────────────────
  Future<List<Appointment>> getAppointments({String? date, String? status, int? shopId}) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('${AppConstants.baseUrl}/mobile/appointments/$id')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: _headers).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Appointment.fromJson(j)).toList();
    }
    throw Exception('Error al cargar citas: ${response.statusCode}');
  }

  Future<Appointment> createAppointment({
    required int staffId,
    required int serviceId,
    required String clientName,
    required String clientPhone,
    required String startTime,
    int? shopId,
  }) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/mobile/appointments'),
      headers: _headers,
      body: jsonEncode({
        'shop_id': id,
        'staff_id': staffId,
        'service_id': serviceId,
        'client_name': clientName,
        'client_phone': clientPhone,
        'start_time': startTime,
      }),
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      return Appointment.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear cita: ${response.body}');
  }

  Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/mobile/appointments/$appointmentId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    ).timeout(AppConstants.timeout);

    return response.statusCode == 200;
  }

  Future<bool> deleteAppointment(int appointmentId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/mobile/appointments/$appointmentId'),
      headers: _headers,
    ).timeout(AppConstants.timeout);
    return response.statusCode == 200;
  }

  // ── Staff ──────────────────────────────────────────────────────────────────
  Future<List<Staff>> getStaff([int? shopId]) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/mobile/staff/$id'),
      headers: _headers,
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Staff.fromJson(j)).toList();
    }
    throw Exception('Error al cargar staff: ${response.statusCode}');
  }

  // ── Services ───────────────────────────────────────────────────────────────
  Future<List<Service>> getServices([int? shopId]) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/mobile/services/$id'),
      headers: _headers,
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Service.fromJson(j)).toList();
    }
    throw Exception('Error al cargar servicios: ${response.statusCode}');
  }

  // ── Shop ───────────────────────────────────────────────────────────────────
  Future<BarberShop> getShop([int? shopId]) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/shops/$id'),
      headers: _headers,
    ).timeout(AppConstants.timeout);

    if (response.statusCode == 200) {
      return BarberShop.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar barbería: ${response.statusCode}');
  }

  Future<bool> updateShop({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? businessHours,
    int? shopId,
  }) async {
    final id = shopId ?? _shopId ?? AppConstants.defaultShopId;
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (businessHours != null) body['business_hours'] = businessHours;

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/mobile/shops/$id'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(AppConstants.timeout);

    return response.statusCode == 200;
  }
}
