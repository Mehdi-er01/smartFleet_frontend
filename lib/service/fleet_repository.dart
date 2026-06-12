import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/driver_dto.dart';
import 'package:smartfleet_frontend/dto/vehicle_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class FleetRepository {
  final ApiClient _api;
  FleetRepository(this._api);

  // ─── DRIVERS ───────────────────────────────────────────

  /// Returns drivers assigned to the current manager
  Future<List<DriverDto>> getMyDrivers() async {
    try {
      final res = await _api.get('/drivers/my-drivers');
      return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
    } catch (_) {
      return _mockMyDrivers;
    }
  }

  /// Returns drivers not assigned to any manager
  Future<List<DriverDto>> getUnassignedDrivers() async {
    try {
      final res = await _api.get('/drivers/unassigned');
      return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
    } catch (_) {
      return _mockUnassignedDrivers;
    }
  }

  /// Assigns a driver to the current manager
  Future<void> assignDriver(int driverId) async {
    try {
      await _api.post('/drivers/$driverId/assign', {});
    } catch (_) {
      // Mock: silently succeed
    }
  }

  /// Unassigns a driver from the current manager
  Future<void> unassignDriver(int driverId) async {
    try {
      await _api.post('/drivers/$driverId/unassign', {});
    } catch (_) {
      // Mock: silently succeed
    }
  }

  // ─── VEHICLES ──────────────────────────────────────────

  /// Returns all vehicles for the current manager
  Future<List<VehicleDto>> getVehicles() async {
    try {
      final res = await _api.get('/vehicles');
      return (res.data as List).map((j) => VehicleDto.fromJson(j)).toList();
    } catch (_) {
      return _mockVehicles;
    }
  }

  /// Creates a new vehicle for the current manager
  Future<VehicleDto> createVehicle(VehicleDto vehicle) async {
    try {
      final res = await _api.post('/vehicles', vehicle.toJson());
      return VehicleDto.fromJson(res.data);
    } catch (_) {
      return VehicleDto(
        id: DateTime.now().millisecondsSinceEpoch,
        registrationNumber: vehicle.registrationNumber,
        brand: vehicle.brand,
        model: vehicle.model,
        year: vehicle.year,
        maxVolumeM2: vehicle.maxVolumeM2,
        maxPayloadKg: vehicle.maxPayloadKg,
        managerId: vehicle.managerId,
        active: vehicle.active,
      );
    }
  }

  /// Updates an existing vehicle
  Future<VehicleDto> updateVehicle(int id, VehicleDto vehicle) async {
    try {
      final res = await _api.put('/vehicles/$id', vehicle.toJson());
      return VehicleDto.fromJson(res.data);
    } catch (_) {
      return vehicle;
    }
  }

  /// Toggles vehicle active/inactive status
  Future<void> toggleVehicleActive(int id, bool active) async {
    try {
      await _api.patch(
        '/vehicles/$id/toggle',
        queryParameters: {'active': active},
      );
    } catch (_) {
      // Mock: silently succeed
    }
  }

  // ─── MOCK DATA ─────────────────────────────────────────

  static final List<DriverDto> _mockMyDrivers = [
    const DriverDto(
      id: 1,
      email: 'ahmed@smartfleet.com',
      name: 'Ahmed R.',
      phone: '+212 600-111111',
      licenseNumber: 'LIC-2042',
      available: true,
      active: true,
      managerId: 1,
    ),
    const DriverDto(
      id: 2,
      email: 'fatima@smartfleet.com',
      name: 'Fatima Z.',
      phone: '+212 611-222222',
      licenseNumber: 'LIC-3089',
      available: false,
      active: true,
      managerId: 1,
    ),
    const DriverDto(
      id: 3,
      email: 'youssef@smartfleet.com',
      name: 'Youssef B.',
      phone: '+212 622-333333',
      licenseNumber: 'LIC-1567',
      available: true,
      active: true,
      managerId: 1,
    ),
  ];

  static final List<DriverDto> _mockUnassignedDrivers = [
    const DriverDto(
      id: 4,
      email: 'karim@smartfleet.com',
      name: 'Karim M.',
      phone: '+212 633-444444',
      licenseNumber: 'LIC-4201',
      available: true,
      active: true,
    ),
    const DriverDto(
      id: 5,
      email: 'sara@smartfleet.com',
      name: 'Sara L.',
      phone: '+212 644-555555',
      licenseNumber: 'LIC-5890',
      available: true,
      active: true,
    ),
    const DriverDto(
      id: 6,
      email: 'omar@smartfleet.com',
      name: 'Omar K.',
      phone: '+212 655-666666',
      licenseNumber: 'LIC-6732',
      available: true,
      active: true,
    ),
    const DriverDto(
      id: 7,
      email: 'nadia@smartfleet.com',
      name: 'Nadia H.',
      phone: '+212 666-777777',
      licenseNumber: 'LIC-7145',
      available: false,
      active: false,
    ),
    const DriverDto(
      id: 8,
      email: 'hassan@smartfleet.com',
      name: 'Hassan T.',
      phone: '+212 677-888888',
      licenseNumber: 'LIC-8923',
      available: true,
      active: true,
    ),
  ];

  static final List<VehicleDto> _mockVehicles = [
    const VehicleDto(
      id: 1,
      registrationNumber: '1234-A-15',
      brand: 'Volvo',
      model: 'FH16',
      year: 2021,
      maxVolumeM2: 82.0,
      maxPayloadKg: 25000,
      currentLoadM2: 30.0,
      currentLoadKg: 9500,
      managerId: 1,
      active: true,
    ),
    const VehicleDto(
      id: 2,
      registrationNumber: '5678-B-26',
      brand: 'Scania',
      model: 'R500',
      year: 2019,
      maxVolumeM2: 75.0,
      maxPayloadKg: 20000,
      managerId: 1,
      active: true,
    ),
    const VehicleDto(
      id: 3,
      registrationNumber: '9012-C-50',
      brand: 'Mercedes',
      model: 'Actros',
      year: 2020,
      maxVolumeM2: 78.0,
      maxPayloadKg: 22000,
      currentLoadM2: 10.0,
      currentLoadKg: 3200,
      managerId: 1,
      active: false,
    ),
    const VehicleDto(
      id: 4,
      registrationNumber: '3456-D-75',
      brand: 'DAF',
      model: 'XF',
      year: 2022,
      maxVolumeM2: 68.0,
      maxPayloadKg: 18000,
      managerId: 1,
      active: true,
    ),
    const VehicleDto(
      id: 5,
      registrationNumber: '7890-E-90',
      brand: 'MAN',
      model: 'TGX',
      year: 2017,
      maxVolumeM2: 60.0,
      maxPayloadKg: 15000,
      managerId: 1,
      active: false,
    ),
  ];
}

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository(ref.watch(ApiClientProvider));
});
