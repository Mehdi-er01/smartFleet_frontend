import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/api_client.dart';
import 'package:smartfleet_frontend/features/dispatch/data/delivery_program_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/data/optimizedProgramStatsDto.dart';

class OptimizationRepo {
  final ApiClient _apiClient;
  OptimizationRepo(this._apiClient);
  //get program optimization stat
  Future<OptimizedProgramStatsDto> getProgramOptimizationStat(
    int programId,
  ) async {
    final response = await _apiClient.get(
      '/optimization/programs/$programId/stats',
    );
    if (response.statusCode == 200) {
      return OptimizedProgramStatsDto.fromJson(response.data);
    } else {
      throw Exception('Failed to load program optimization stat');
    }
  }

  Future<DeliveryProgramDto> optimizeProgram(int programId) async {
    final response = await _apiClient.post(
      '/optimization/programs/$programId',
      {},
    );
    if (response.statusCode == 200) {
      return DeliveryProgramDto.fromJson(
        response.data,
      ); // Changed from return DeliveryProgramDto(response.data);
    } else {
      throw Exception('Failed to optimize program');
    }
  }
}

final optimizationRepoProvider = Provider<OptimizationRepo>((ref) {
  return OptimizationRepo(ref.watch(ApiClientProvider));
});
