import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:dio/dio.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class DriverRepository {
  final ApiClient _apiClient;

  DriverRepository(this._apiClient);

  Future<SubProgramDto?> getActiveSubProgram() async {
    try {
      var response = await _apiClient.get('/subprograms/my-active');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return SubProgramDto.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // 404 = no active subprogram (normal case), other errors = return null gracefully
      if (e is DioException && (e.response?.statusCode == 404 || e.response?.statusCode == 403)) {
        return null;
      }
      // Re-throw only for non-network errors so we don't silently swallow real bugs
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot reach server. Check your connection.');
      }
      return null;
    }
  }

  Future<List<SubProgramDto>> getMySubPrograms() async {
    try {
      var response = await _apiClient.get('/subprograms/my-subprograms');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => SubProgramDto.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 404 || e.response?.statusCode == 403)) {
        return [];
      }
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot reach server. Check your connection.');
      }
      return [];
    }
  }

  Future<List<OrderDto>> getOrdersByIds(List<int> orderIds) async {
    try {
      List<OrderDto> orders = [];
      for (int id in orderIds) {
        var response = await _apiClient.get('/orders/$id');
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          orders.add(OrderDto.fromJson(response.data));
        }
      }
      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<OrderDto> updateOrderStatus(int orderId, String status) async {
    try {
      var response = await _apiClient.put('/orders/$orderId/status?status=$status', {});
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return OrderDto.fromJson(response.data);
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }

  Future<SubProgramDto> startSubProgram(int subProgramId) async {
    try {
      var response = await _apiClient.put('/subprograms/$subProgramId/start', {});
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return SubProgramDto.fromJson(response.data);
      } else {
        throw Exception('Failed to start subprogram');
      }
    } catch (e) {
      throw Exception('Error starting subprogram: $e');
    }
  }
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final apiClient = ref.watch(ApiClientProvider);
  return DriverRepository(apiClient);
});
