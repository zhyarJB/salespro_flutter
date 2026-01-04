import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/config/api_config.dart';

class AuthService {
  // Secure storage for tokens
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // SharedPreferences for non-sensitive data (visit state, etc.)
  static SharedPreferences? _prefs;
  
  // ============================================
  // AUTOMATIC DETECTION - Works on both emulator and physical device!
  // ============================================
  // Your computer's IP address (for physical device testing)
  // Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
  // Update this if your IP changes or use environment variables
  static String get _localNetworkIp => ApiConfig.localNetworkIp;
  
  // Cache for emulator detection
  static bool? _isEmulatorCache;
  
  // Automatically detect if running on emulator or physical device
  static Future<bool> _isEmulator() async {
    if (_isEmulatorCache != null) return _isEmulatorCache!;
    
    if (kIsWeb) {
      _isEmulatorCache = false;
      return false;
    }
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Check common emulator indicators
        final model = androidInfo.model.toLowerCase();
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final brand = androidInfo.brand.toLowerCase();
        final device = androidInfo.device.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();
        
        // Emulator detection based on common patterns
        _isEmulatorCache = model.contains('sdk') ||
            model.contains('emulator') ||
            model.contains('google_sdk') ||
            model.contains('android sdk') ||
            manufacturer.contains('genymotion') ||
            manufacturer.contains('unknown') ||
            brand.contains('generic') ||
            brand.contains('unknown') ||
            device.contains('generic') ||
            hardware.contains('goldfish') ||
            hardware.contains('ranchu') ||
            hardware.contains('vbox86');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // iOS simulator detection
        final model = iosInfo.model.toLowerCase();
        _isEmulatorCache = model.contains('simulator') ||
            iosInfo.name.toLowerCase().contains('simulator') ||
            !iosInfo.utsname.machine.contains('iPhone') && !iosInfo.utsname.machine.contains('iPad');
      } else {
        _isEmulatorCache = false;
      }
    } catch (e) {
      // Default to emulator if detection fails
      _isEmulatorCache = true;
    }
    
    return _isEmulatorCache ?? true;
  }
  
  // Get base URL - automatically detects device type
  static Future<String> getBaseUrl() async {
    if (kIsWeb) {
      // For web (Chrome), use localhost
      return 'http://localhost:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
    } else {
      final isEmulator = await _isEmulator();
      
      if (isEmulator) {
        // Using emulator/simulator
        // Android emulator uses 10.0.2.2 to reach host machine
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
        } else {
          // iOS simulator uses localhost
          return 'http://localhost:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
        }
      } else {
        // Using physical device - use computer's network IP
        // Make sure phone and computer are on same WiFi
        // Start Laravel with: php artisan serve --host=0.0.0.0 --port=8000
        return 'http://${_localNetworkIp}:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
      }
    }
  }
  
  // Synchronous getter for backward compatibility
  // Note: For automatic detection, use getBaseUrl() async method instead
  // This getter defaults to emulator address
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
    } else {
      // Default to emulator for synchronous access
      // For async access with auto-detection, use getBaseUrl() instead
      return 'http://10.0.2.2:${ApiConfig.defaultPort}/api/${ApiConfig.apiVersion}';
    }
  }
  
  // Helper method to build full URL with automatic device detection
  static Future<String> buildUrl(String endpoint) async {
    final base = await getBaseUrl();
    return '$base$endpoint';
  }

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'flutter_app' 
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']?['token'];
        if (token != null) {
          await _saveToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save token securely using FlutterSecureStorage
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Get token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/refresh');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['data']?['token'];
        if (newToken != null) {
          await _saveToken(newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  // Logout - clear secure storage
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _initPrefs();
    await _prefs?.remove('visit_elapsed');
    await _prefs?.remove('visit_started');
  }

  // Example of an authenticated GET request
  Future<http.Response> getProfile() async {
    final token = await getToken();
    final baseUrl = await getBaseUrl(); // Use async method for automatic detection
    final url = Uri.parse('$baseUrl/profile');
    return http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}