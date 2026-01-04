import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Visit Service
/// Handles visit creation, check-in, check-out, and management
class VisitService {
  final ApiService _apiService = ApiService();

  /// Create a new visit for a location
  Future<Map<String, dynamic>?> createVisit({
    required int locationId,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'location_id': locationId,
        'status': 'planned',
      };

      if (scheduledDate != null) {
        body['scheduled_date'] = scheduledDate.toIso8601String();
      } else {
        body['scheduled_date'] = DateTime.now().toIso8601String();
      }

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _apiService.post('/visits', body: body);
      final data = _apiService.parseResponse(response);

      if (data['success'] == true) {
        return data['data']['visit'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create visit: $e');
    }
  }

  /// Check in to a visit
  Future<bool> checkIn({
    required int visitId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      // Get current location if not provided
      Position? position;
      if (latitude == null || longitude == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          throw Exception('Failed to get location: $e');
        }
      }

      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _apiService.post(
        '/visits/$visitId/check-in',
        body: body,
      );
      final data = _apiService.parseResponse(response);

      return data['success'] == true;
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  /// Check out from a visit
  Future<bool> checkOut({
    required int visitId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      // Get current location if not provided
      Position? position;
      if (latitude == null || longitude == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          throw Exception('Failed to get location: $e');
        }
      }

      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _apiService.post(
        '/visits/$visitId/check-out',
        body: body,
      );
      final data = _apiService.parseResponse(response);

      return data['success'] == true;
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  /// Get today's visits
  Future<List<Map<String, dynamic>>> getTodayVisits() async {
    try {
      final response = await _apiService.get('/visits/today');
      final data = _apiService.parseResponse(response);

      if (data['success'] == true) {
        final visits = data['data']['visits'] as List<dynamic>;
        return visits.map((v) => Map<String, dynamic>.from(v)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get today\'s visits: $e');
    }
  }

  /// Get visit by ID
  Future<Map<String, dynamic>?> getVisit(int visitId) async {
    try {
      final response = await _apiService.get('/visits/$visitId');
      final data = _apiService.parseResponse(response);

      if (data['success'] == true) {
        return data['data']['visit'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get visit: $e');
    }
  }

  /// Get visit statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await _apiService.get('/visits/statistics');
      final data = _apiService.parseResponse(response);

      if (data['success'] == true) {
        return data['data']['statistics'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}

