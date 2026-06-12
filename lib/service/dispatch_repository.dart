import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/delivery_program_dto.dart';
import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class DispatchRepository {
  final ApiClient _api;
  DispatchRepository(this._api);

  // ─── PROGRAMS ──────────────────────────────────────────

  Future<List<DeliveryProgramDto>> getPrograms() async {
    try {
      final res = await _api.get('/programs');
      return (res.data as List)
          .map((j) => DeliveryProgramDto.fromJson(j))
          .toList();
    } catch (_) {
      return _mockPrograms;
    }
  }

  Future<DeliveryProgramDto> createProgram(
    List<OrderDto> orders,
    String? notes,
  ) async {
    try {
      final res = await _api.post('/programs', {
        'orders': orders.map((o) => o.toJson()).toList(),
        if (notes != null) 'notes': notes,
      });
      return DeliveryProgramDto.fromJson(res.data);
    } catch (_) {
      return DeliveryProgramDto(
        id: DateTime.now().millisecondsSinceEpoch,
        programNumber: 'PRG-${DateTime.now().millisecondsSinceEpoch}',
        status: 'PENDING',
        orders: orders,
        notes: notes,
      );
    }
  }

  Future<void> optimizeProgram(int programId) async {
    try {
      await _api.post('/optimization/programs/$programId', {});
    } catch (_) {
      // Mock: silently succeed
    }
  }

  // ─── MOCK DATA ─────────────────────────────────────────

  static final List<DeliveryProgramDto> _mockPrograms = [
    DeliveryProgramDto(
      id: 1,
      programNumber: 'PRG-2025-001',
      managerId: 1,
      status: 'OPTIMIZED',
      plannedDate: '2025-12-20',
      executionDate: '2025-12-20',
      orders: const [
        OrderDto(
          id: 1,
          orderNumber: 'ORD-001',
          weightKg: 500,
          volumeM2: 3,
          deliveryLatitude: 33.5731,
          deliveryLongitude: -7.5898,
          deliveryAddress: '12 Rue Hassan II, Casablanca',
          status: 'ASSIGNED',
        ),
        OrderDto(
          id: 2,
          orderNumber: 'ORD-002',
          weightKg: 1200,
          volumeM2: 8,
          deliveryLatitude: 33.5950,
          deliveryLongitude: -7.6187,
          deliveryAddress: '45 Bd Anfa, Casablanca',
          status: 'ASSIGNED',
        ),
        OrderDto(
          id: 3,
          orderNumber: 'ORD-003',
          weightKg: 300,
          volumeM2: 2,
          deliveryLatitude: 33.5800,
          deliveryLongitude: -7.6000,
          deliveryAddress: '78 Ave des FAR, Casablanca',
          status: 'IN_TRANSIT',
        ),
      ],
      subPrograms: [
        const SubProgramDto(
          id: 1,
          subProgramNumber: 'SP-001-A',
          deliveryProgramId: 1,
          driverId: 1,
          vehicleId: 1,
          orderIds: [1, 3],
          status: 'IN_PROGRESS',
          estimatedDistanceKm: 18.5,
          estimatedDurationMinutes: 45,
          totalOrdersCount: 2,
          approvedOrdersCount: 1,
          driverName: 'Ahmed R.',
          vehicleRegistration: '1234-A-15',
        ),
        const SubProgramDto(
          id: 2,
          subProgramNumber: 'SP-001-B',
          deliveryProgramId: 1,
          driverId: 2,
          vehicleId: 2,
          orderIds: [2],
          status: 'PENDING',
          estimatedDistanceKm: 12.3,
          estimatedDurationMinutes: 30,
          totalOrdersCount: 1,
          approvedOrdersCount: 0,
          driverName: 'Fatima Z.',
          vehicleRegistration: '5678-B-26',
        ),
      ],
    ),
    DeliveryProgramDto(
      id: 2,
      programNumber: 'PRG-2025-002',
      managerId: 1,
      status: 'PENDING',
      plannedDate: '2025-12-22',
      orders: const [
        OrderDto(
          id: 4,
          orderNumber: 'ORD-004',
          weightKg: 800,
          volumeM2: 5,
          deliveryLatitude: 33.5600,
          deliveryLongitude: -7.5800,
          deliveryAddress: '22 Rue Moulay Ismail, Casablanca',
          status: 'PENDING',
        ),
        OrderDto(
          id: 5,
          orderNumber: 'ORD-005',
          weightKg: 2000,
          volumeM2: 15,
          deliveryLatitude: 33.5700,
          deliveryLongitude: -7.6100,
          deliveryAddress: '10 Bd Zerktouni, Casablanca',
          status: 'PENDING',
        ),
      ],
    ),
    const DeliveryProgramDto(
      id: 3,
      programNumber: 'PRG-2025-003',
      managerId: 1,
      status: 'COMPLETED',
      plannedDate: '2025-12-15',
      executionDate: '2025-12-15',
      completionDate: '2025-12-15',
      orders: [
        OrderDto(
          id: 6,
          orderNumber: 'ORD-006',
          weightKg: 600,
          volumeM2: 4,
          deliveryLatitude: 33.5850,
          deliveryLongitude: -7.5950,
          deliveryAddress: '5 Rue Ibn Sina, Casablanca',
          status: 'DELIVERED',
          clientApproved: true,
        ),
      ],
      subPrograms: [
        SubProgramDto(
          id: 3,
          subProgramNumber: 'SP-003-A',
          deliveryProgramId: 3,
          driverId: 3,
          vehicleId: 4,
          orderIds: [6],
          status: 'COMPLETED',
          actualDistanceKm: 14.2,
          actualDurationMinutes: 38,
          totalOrdersCount: 1,
          approvedOrdersCount: 1,
          driverName: 'Youssef B.',
          vehicleRegistration: '3456-D-75',
        ),
      ],
    ),
  ];
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository(ref.watch(ApiClientProvider));
});
