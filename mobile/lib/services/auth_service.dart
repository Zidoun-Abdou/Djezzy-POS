import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Authentication service for handling JWT tokens
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current user data
  Map<String, dynamic>? get userData => _userData;

  /// Initialize auth service - check for stored tokens
  Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(ApiConfig.accessTokenKey);
    _refreshToken = prefs.getString(ApiConfig.refreshTokenKey);
    final userDataStr = prefs.getString(ApiConfig.userDataKey);
    if (userDataStr != null) {
      _userData = jsonDecode(userDataStr);
    }

    if (_accessToken != null && _refreshToken != null) {
      // Try to refresh token to verify it's still valid
      return await refreshToken();
    }
    return false;
  }

  /// Login with username and password
  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];

        // Save tokens
        await _saveTokens();

        // Fetch user data
        await fetchUserData();

        return LoginResult.success();
      } else if (response.statusCode == 401) {
        return LoginResult.error('Nom d\'utilisateur ou mot de passe incorrect');
      } else {
        return LoginResult.error('Erreur de connexion. Veuillez reessayer.');
      }
    } catch (e) {
      return LoginResult.error('Impossible de se connecter au serveur');
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefreshEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        if (data['refresh'] != null) {
          _refreshToken = data['refresh'];
        }
        await _saveTokens();
        return true;
      }
    } catch (e) {
      // Token refresh failed
    }

    // Clear invalid tokens
    await logout();
    return false;
  }

  /// Fetch current user data
  Future<void> fetchUserData() async {
    if (_accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.currentUserEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        _userData = jsonDecode(response.body);
        await _saveUserData();
      }
    } catch (e) {
      // Failed to fetch user data
    }
  }

  /// Logout - clear all tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.accessTokenKey);
    await prefs.remove(ApiConfig.refreshTokenKey);
    await prefs.remove(ApiConfig.userDataKey);
  }

  /// Save tokens to storage
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(ApiConfig.accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(ApiConfig.refreshTokenKey, _refreshToken!);
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    if (_userData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.userDataKey, jsonEncode(_userData));
    }
  }

  /// Make authenticated HTTP GET request
  Future<http.Response> authenticatedGet(String endpoint) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    var response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
    ).timeout(ApiConfig.connectionTimeout);

    // If unauthorized, try to refresh token and retry
    if (response.statusCode == 401) {
      if (await refreshToken()) {
        response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ).timeout(ApiConfig.connectionTimeout);
      }
    }

    return response;
  }

  /// Make authenticated HTTP POST request
  Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    var response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(body),
    ).timeout(ApiConfig.connectionTimeout);

    // If unauthorized, try to refresh token and retry
    if (response.statusCode == 401) {
      if (await refreshToken()) {
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode(body),
        ).timeout(ApiConfig.connectionTimeout);
      }
    }

    return response;
  }
}

/// Login result class
class LoginResult {
  final bool success;
  final String? error;

  LoginResult.success() : success = true, error = null;
  LoginResult.error(this.error) : success = false;
}
