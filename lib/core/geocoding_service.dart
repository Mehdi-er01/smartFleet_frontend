import 'package:dio/dio.dart';

/// Simple geocoding service using the free Nominatim OpenStreetMap API.
/// No API key required.
class GeocodingService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'User-Agent': 'SmartFleetApp/1.0'},
  ));

  /// Returns (lat, lon) for the given address string, or null if not found.
  static Future<({double lat, double lon})?> geocode(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final resp = await _dio.get('/search', queryParameters: {
        'q': address,
        'format': 'json',
        'limit': 1,
      });
      if (resp.data is List && (resp.data as List).isNotEmpty) {
        final first = (resp.data as List).first;
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lon = double.tryParse(first['lon']?.toString() ?? '');
        if (lat != null && lon != null) return (lat: lat, lon: lon);
      }
    } catch (_) {}
    return null;
  }
}
