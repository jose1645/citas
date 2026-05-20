import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  DashboardStats? _dashboard;
  List<Appointment> _appointments = [];
  List<Staff> _staff = [];
  List<Service> _services = [];
  BarberShop? _shop;
  DateTime _selectedDate = DateTime.now();
  String? _statusFilter;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardStats? get dashboard => _dashboard;
  List<Appointment> get appointments => _appointments;
  List<Staff> get staff => _staff;
  List<Service> get services => _services;
  BarberShop? get shop => _shop;
  DateTime get selectedDate => _selectedDate;
  String? get statusFilter => _statusFilter;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      _dashboard = await _api.getDashboard();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Appointments ───────────────────────────────────────────────────────────
  Future<void> loadAppointments({String? date, String? status}) async {
    _setLoading(true);
    _setError(null);
    try {
      _appointments = await _api.getAppointments(date: date, status: status);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAppointmentsForDate(DateTime date) async {
    _selectedDate = date;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await loadAppointments(date: dateStr, status: _statusFilter);
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadAppointmentsForDate(_selectedDate);
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      final success = await _api.updateAppointmentStatus(id, status);
      if (success) {
        _appointments = _appointments.map((a) {
          return a.id == id ? a.copyWith(status: status) : a;
        }).toList();
        notifyListeners();
        // Also refresh dashboard counts
        loadDashboard();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteAppointment(int id) async {
    try {
      final success = await _api.deleteAppointment(id);
      if (success) {
        _appointments = _appointments.where((a) => a.id != id).toList();
        notifyListeners();
        loadDashboard();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> createAppointment({
    required int staffId,
    required int serviceId,
    required String clientName,
    required String clientPhone,
    required String startTime,
  }) async {
    try {
      await _api.createAppointment(
        staffId: staffId,
        serviceId: serviceId,
        clientName: clientName,
        clientPhone: clientPhone,
        startTime: startTime,
      );
      await loadAppointmentsForDate(_selectedDate);
      await loadDashboard();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Staff ──────────────────────────────────────────────────────────────────
  Future<void> loadStaff() async {
    _setLoading(true);
    _setError(null);
    try {
      _staff = await _api.getStaff();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Services ───────────────────────────────────────────────────────────────
  Future<void> loadServices() async {
    _setLoading(true);
    _setError(null);
    try {
      _services = await _api.getServices();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Shop ───────────────────────────────────────────────────────────────────
  Future<void> loadShop() async {
    _setLoading(true);
    _setError(null);
    try {
      _shop = await _api.getShop();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateShop({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? businessHours,
  }) async {
    _setLoading(true);
    try {
      final success = await _api.updateShop(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        businessHours: businessHours,
      );
      if (success) await loadShop();
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
