class AppConstants {
  // API Base URL — cambiar según el entorno
  static const String baseUrl = 'https://barber.synteck.org/api';
  // static const String baseUrl = 'http://10.0.2.2:8051/api'; // Android emulator local
  // static const String baseUrl = 'http://localhost:8051/api'; // iOS simulator local

  // Default shop ID (se sobreescribe tras login)
  static const int defaultShopId = 1;

  // Storage keys
  static const String keyToken = 'flowcuts_token';
  static const String keyUserId = 'flowcuts_user_id';
  static const String keyUsername = 'flowcuts_username';
  static const String keyShopId = 'flowcuts_shop_id';
  static const String keyIsOwner = 'flowcuts_is_owner';

  // App Info
  static const String appName = 'FlowCuts';
  static const String appTagline = 'Tu barbería en control';
  static const String version = '1.0.0';

  // Request timeout
  static const Duration timeout = Duration(seconds: 15);

  // Appointment statuses
  static const List<Map<String, String>> statuses = [
    {'value': 'scheduled', 'label': 'Pendiente'},
    {'value': 'confirmed', 'label': 'Confirmada'},
    {'value': 'completed', 'label': 'Completada'},
    {'value': 'cancelled', 'label': 'Cancelada'},
  ];
}
