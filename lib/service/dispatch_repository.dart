import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/delivery_program_dto.dart';
import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class DispatchRepository {
  final ApiClient _api;
  DispatchRepository(this._api);

  // ─── PROGRAMS ──────────────────────────────────────────
  // Backend: GET /programs → List<DeliveryProgramDTO>
  // Backend: POST /programs → DeliveryProgramDTO (expects orders with existing IDs)
  // Backend: POST /optimization/programs/{id} → DeliveryProgramDTO

  Future<List<DeliveryProgramDto>> getPrograms() async {
    final res = await _api.get('/programs');
    return (res.data as List)
        .map((j) => DeliveryProgramDto.fromJson(j))
        .toList();
  }

  /// Returns all orders
  /// Backend: GET /orders → List<OrderDTO>
  Future<List<OrderDto>> getOrders() async {
    final res = await _api.get('/orders');
    return (res.data as List).map((j) => OrderDto.fromJson(j)).toList();
  }

  /// Creates a new delivery program.
  /// Backend expects orders with existing IDs. Orders without IDs are ignored.
  /// The flow should be: create orders first via POST /orders, then create program.
  Future<DeliveryProgramDto> createProgram(
    List<OrderDto> orders,
    String? notes, {
    String? plannedDate,
  }) async {
    final res = await _api.post('/programs', {
      'orders': orders.map((o) => {'id': o.id}).toList(),
      if (notes != null) 'notes': notes,
      if (plannedDate != null) 'plannedDate': plannedDate,
    });
    return DeliveryProgramDto.fromJson(res.data);
  }

  /// Creates a single order via the backend
  /// Backend: POST /orders → OrderDTO
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
    // Step 1: Create each order to get server-assigned IDs
    final createdOrders = <OrderDto>[];
    for (final order in newOrders) {
      final created = await createOrder(order);
      createdOrders.add(created);
    }

    // Step 2: Create the program linking orders by ID
    return createProgram(createdOrders, notes, plannedDate: plannedDate);
  }

  /// Optimizes a program (creates sub-programs/routes)
  /// Backend: POST /optimization/programs/{id} → DeliveryProgramDTO
  Future<DeliveryProgramDto> optimizeProgram(int programId) async {
    final res = await _api.post('/optimization/programs/$programId', {});
    return DeliveryProgramDto.fromJson(res.data);
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository(ref.watch(ApiClientProvider));
});
