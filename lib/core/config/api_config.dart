/// API Configuration
/// Centralized configuration for API endpoints and settings
class ApiConfig {
  // Network IP for physical device testing
  // Update this if your IP changes, or use environment variables
  static const String localNetworkIp = String.fromEnvironment(
    'API_LOCAL_IP',
    defaultValue: '192.168.0.69',
  );

  // API base paths
  static const String apiVersion = 'v1';
  static const int defaultPort = 8000;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Pagination defaults
  static const int defaultPageSize = 20;
  
  // Map configuration
  static const double defaultZoomLevel = 13.0;
  static const double locationZoomLevel = 16.0;
}

