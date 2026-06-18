import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/dispatch/data/delivery_program_dto.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/core/api_client.dart';

class DispatchRepository {
  final ApiClient _api;
  DispatchRepository(this._api);

  Future<List<DeliveryProgramDto>> getPrograms() async {
    final res = await _api.get('/programs');
    return (res.data as List)
        .map((j) => DeliveryProgramDto.fromJson(j))
        .toList();
  }

  Future<DeliveryProgramDto> getProgram(int id) async {
    final res = await _api.get('/programs/$id');
    if (res.statusCode == 200) {
      return DeliveryProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to load program');
  }

  Future<void> deleteProgram(int id) async {
    final res = await _api.delete('/programs/$id');
    if (res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to delete program');
  }

  Future<void> deleteOrder(int programId, int orderId) async {
    final res = await _api.delete('/programs/$programId/orders/$orderId');
    if (res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to delete order');
  }

  Future<DeliveryProgramDto> addOrders(int programId, List<int> orders) async {
    final res = await _api.post(
      '/programs/$programId/orders',
      orders.map((o) => {'id': o}).toList(),
    );
    return DeliveryProgramDto.fromJson(res.data);
  }

  Future<DeliveryProgramDto> updateProgram(
    int id,
    DeliveryProgramDto program,
  ) async {
    final res = await _api.put('/programs/$id', program.toJson());
    if (res.statusCode == 200) {
      return DeliveryProgramDto.fromJson(res.data);
    }
    throw Exception('Failed to update program');
  }

  /// Returns all orders
  Future<List<OrderDto>> getOrders() async {
    final res = await _api.get('/orders');
    return (res.data as List).map((j) => OrderDto.fromJson(j)).toList();
  }

  /// Creates a single order
  Future<OrderDto> createOrder(OrderDto order) async {
    final res = await _api.post('/orders', order.toJson());
    return OrderDto.fromJson(res.data);
  }

  /// Creates orders first, then creates a program linking those orders
  Future<DeliveryProgramDto> createProgramWithOrders(
    List<OrderDto> newOrders,
    String? notes, {
    String? plannedDate,
  }) async {
    final createdOrders = <OrderDto>[];
    for (final order in newOrders) {
      final created = await createOrder(order);
      createdOrders.add(created);
    }
    return createProgram(createdOrders, notes, plannedDate: plannedDate);
  }

  /// Optimizes a program (creates sub-programs/routes)
  Future<DeliveryProgramDto> optimizeProgram(int programId) async {
    final res = await _api.post('/optimization/programs/$programId', {});
    return DeliveryProgramDto.fromJson(res.data);
  }

  Future<DeliveryProgramDto> createProgram(
    List<OrderDto>? orders,
    String? notes, {
    String? plannedDate,
  }) async {
    final res = await _api.post('/programs', {
      if (orders != null) 'orders': orders,
      if (notes != null) 'notes': notes,
      if (plannedDate != null) 'plannedDate': plannedDate,
    });
    return DeliveryProgramDto.fromJson(res.data);
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository(ref.watch(ApiClientProvider));
});
