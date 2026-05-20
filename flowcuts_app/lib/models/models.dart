class Appointment {
  final int id;
  final String clientName;
  final String clientPhone;
  final String serviceName;
  final double servicePrice;
  final String staffName;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.serviceName,
    required this.servicePrice,
    required this.staffName,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      clientPhone: json['client_phone'] ?? '',
      serviceName: json['service_name'] ?? '',
      servicePrice: (json['service_price'] ?? 0).toDouble(),
      staffName: json['staff_name'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      status: json['status'] ?? 'scheduled',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_name': clientName,
    'client_phone': clientPhone,
    'service_name': serviceName,
    'service_price': servicePrice,
    'staff_name': staffName,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  Appointment copyWith({String? status}) {
    return Appointment(
      id: id,
      clientName: clientName,
      clientPhone: clientPhone,
      serviceName: serviceName,
      servicePrice: servicePrice,
      staffName: staffName,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class Staff {
  final int id;
  final String name;
  final bool isActive;
  final int shopId;

  Staff({
    required this.id,
    required this.name,
    required this.isActive,
    required this.shopId,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? true,
      shopId: json['shop_id'] ?? 0,
    );
  }
}

class Service {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String? imageUrl;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 30,
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class BarberShop {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? businessHours;

  BarberShop({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.businessHours,
  });

  factory BarberShop.fromJson(Map<String, dynamic> json) {
    return BarberShop(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      businessHours: json['business_hours'],
    );
  }
}

class DashboardStats {
  final int shopId;
  final String shopName;
  final int todayAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int cancelledAppointments;
  final int totalAppointmentsMonth;
  final int totalStaff;
  final int totalServices;

  DashboardStats({
    required this.shopId,
    required this.shopName,
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.cancelledAppointments,
    required this.totalAppointmentsMonth,
    required this.totalStaff,
    required this.totalServices,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      shopId: json['shop_id'],
      shopName: json['shop_name'] ?? '',
      todayAppointments: json['today_appointments'] ?? 0,
      pendingAppointments: json['pending_appointments'] ?? 0,
      confirmedAppointments: json['confirmed_appointments'] ?? 0,
      cancelledAppointments: json['cancelled_appointments'] ?? 0,
      totalAppointmentsMonth: json['total_appointments_month'] ?? 0,
      totalStaff: json['total_staff'] ?? 0,
      totalServices: json['total_services'] ?? 0,
    );
  }
}
