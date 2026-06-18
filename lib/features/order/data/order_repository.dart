import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/api_client.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';

class OrderRepository {
  final ApiClient _apiClient;
  OrderRepository(this._apiClient);

  Future<List<OrderDto>> getOrders() async {
    final res = await _apiClient.get('/orders');
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return (res.data as List).map((j) => OrderDto.fromJson(j)).toList();
    }
    throw Exception('Failed to load orders');
  }

  Future<OrderDto> getOrder(int id) async {
    final res = await _apiClient.get('/orders/$id');
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return OrderDto.fromJson(res.data);
    }
    throw Exception('Failed to load order');
  }

  Future<OrderDto> createOrder(OrderDto order) async {
    final res = await _apiClient.post('/orders', order.toJson());
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return OrderDto.fromJson(res.data);
    }
    throw Exception('Failed to create order');
  }

  Future<OrderDto> rejectOrder(int id) async {
    final res = await _apiClient.post('/orders/$id/reject', {});
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return OrderDto.fromJson(res.data);
    }
    throw Exception('Failed to reject order');
  }

  Future<OrderDto> approveOrder(int id) async {
    final res = await _apiClient.post('/orders/$id/approve', {});
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return OrderDto.fromJson(res.data);
    }
    throw Exception('Failed to approve order');
  }

  Future<OrderDto> updateOrderStatus(int id, String status) async {
    final res = await _apiClient.post('/orders/$id/status', {'status': status});
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return OrderDto.fromJson(res.data);
    }
    throw Exception('Failed to update order status');
  }
}

final orderRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(ApiClientProvider);
  return OrderRepository(apiClient);
});
