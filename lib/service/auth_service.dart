
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/login_request_dto.dart';
import 'package:smartfleet_frontend/dto/register_request_dto.dart';
import 'package:smartfleet_frontend/dto/user_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';
import 'package:smartfleet_frontend/service/storage_service.dart';

class AuthService {
    final ApiClient _apiClient;
    AuthService(this._apiClient);
    Future<UserDto?> register(RegisterRequestDto registerRequest) async {
      
      var response = await _apiClient.post('/auth/register', registerRequest.toJson());
    
      if(response.statusCode! >= 200 && response.statusCode! < 300) {
        return UserDto.fromJson(response.data);
      } else {
        return null;
      }
    }
    Future<bool> login(LoginRequestDto loginRequest) async {
      var response = await _apiClient.post('/auth/login', loginRequest.toJson());
      if(response.statusCode! >= 200 && response.statusCode! < 300) {
        await StorageService.saveToken(response.data['token']);
        return true;
      } else {
        return false;
      }
    }

    Future<UserDto?> getCurrentUser() async {
      try {
        var response = await _apiClient.get('/auth/me');
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          return UserDto.fromJson(response.data);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(ApiClientProvider);
  return AuthService(apiClient);
});