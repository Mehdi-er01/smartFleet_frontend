import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class DriverRepository {
  final ApiClient _api;

  DriverRepository(this._api);

  Future<SubProgramDto?> getActiveRoute() async {
    try {
      final res = await _api.get('/subprograms/my-active');
      if (res.data != null) {
        return SubProgramDto.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }

  Future<SubProgramDto?> startRoute(int subprogramId) async {
    try {
      final res = await _api.put('/subprograms/$subprogramId/start', {});
      if (res.data != null) {
        return SubProgramDto.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<SubProgramDto>> getRouteHistory() async {
    try {
      final res = await _api.get('/subprograms/my-subprograms');
      if (res.data is List) {
        return (res.data as List).map((j) => SubProgramDto.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.watch(ApiClientProvider));
});
