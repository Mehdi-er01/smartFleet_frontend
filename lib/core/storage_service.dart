// lib/service/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Create a single instance of the secure storage
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Define your key to prevent typos
  static const String _tokenKey = 'jwt_token';

  // Save the token (Call this after successful login)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get the token (Used by Dio)
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete the token (Call this on logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}