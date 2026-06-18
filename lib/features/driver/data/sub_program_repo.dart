import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/api_client.dart';
import 'package:smartfleet_frontend/features/driver/data/sub_program_dto.dart';

class SubProgramRepo {
  final ApiClient _apiClient;
  SubProgramRepo(this._apiClient);

  Future<SubProgramDto> getSubProgram(int id) async {
    final res = await _apiClient.get('/subprograms/$id');
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return SubProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to load sub program');
  }

  Future<List<SubProgramDto>> getMySubPrograms() async {
    final res = await _apiClient.get('/subprograms/my-subprograms');
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return (res.data as List).map((j) => SubProgramDto.fromJson(j)).toList();
    }
    throw Exception('Failed to load sub programs');
  }

  Future<SubProgramDto> getSubProgramActive() async {
    final res = await _apiClient.get('/subprograms/my-active');
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return SubProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to load active sub program');
  }

  /// POST /subprograms/{id}/calculate-route
  Future<SubProgramDto> subProgramRouteCalculation(int id) async {
    final res = await _apiClient.post('/subprograms/$id/calculate-route', {});
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return SubProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to calculate sub program route');
  }

  Future<SubProgramDto> startSubProgram(int id) async {
    final res = await _apiClient.put('/subprograms/$id/start', {});
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return SubProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to start sub program');
  }
}

final subProgramProvider = Provider((ref) {
  final apiClient = ref.watch(ApiClientProvider);
  return SubProgramRepo(apiClient);
});
