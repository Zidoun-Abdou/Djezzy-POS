/// API Configuration for Djezzy POS
class ApiConfig {
  // Base URL for the API server
  static const String baseUrl = 'http://194.163.133.249';

  // API endpoints
  static const String tokenEndpoint = '/api/token/';
  static const String tokenRefreshEndpoint = '/api/token/refresh/';
  static const String currentUserEndpoint = '/api/user/me/';
  static const String offersEndpoint = '/api/offers/';
  static const String activeOffersEndpoint = '/api/offers/active/';
  static const String phoneNumbersEndpoint = '/api/phone-numbers/';
  static const String availableNumbersEndpoint = '/api/phone-numbers/available/';
  static const String contractsEndpoint = '/api/contracts/';

  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
