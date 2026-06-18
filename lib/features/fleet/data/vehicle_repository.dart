import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/fleet/data/driver_dto.dart';
import 'package:smartfleet_frontend/features/fleet/data/vehicle_dto.dart';
import 'package:smartfleet_frontend/core/api_client.dart';

class FleetRepository {
  final ApiClient _api;
  FleetRepository(this._api);

  // ─── DRIVERS ───────────────────────────────────────────

  /// Returns drivers assigned to the current manager
  Future<List<DriverDto>> getMyDrivers() async {
    final res = await _api.get('/drivers/my-drivers');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  /// Returns drivers not assigned to any manager
  Future<List<DriverDto>> getUnassignedDrivers() async {
    final res = await _api.get('/drivers/unassigned');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  /// Assigns a driver to the current manager
  Future<void> assignDriver(int driverId) async {
    await _api.post('/drivers/$driverId/assign', {});
  }

  /// Unassigns a driver from the current manager
  Future<void> unassignDriver(int driverId) async {
    await _api.post('/drivers/$driverId/unassign', {});
  }

  /// Returns GPS locations of manager's drivers
  Future<List<DriverDto>> getDriverLocations() async {
    final res = await _api.get('/drivers/my-drivers/locations');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  // ─── VEHICLES ──────────────────────────────────────────

  /// Returns all vehicles for the current manager
  Future<List<VehicleDto>> getVehicles() async {
    final res = await _api.get('/vehicles');
    if (res != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      return (res.data as List).map((j) => VehicleDto.fromJson(j)).toList();
    }
    throw Exception('Failed to load vehicles');
  }

  Future<List<VehicleDto>> getActiveVehicles() async {
    final res = await _api.get('/vehicles/active');
    if (res != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      return (res.data as List).map((j) => VehicleDto.fromJson(j)).toList();
    }
    throw Exception('Failed to load active vehicles');
  }

  /// Creates a new vehicle for the current manager
  Future<VehicleDto> createVehicle(VehicleDto vehicle) async {
    final res = await _api.post('/vehicles', vehicle.toJson());
    return VehicleDto.fromJson(res.data);
  }

  /// Updates an existing vehicle
  Future<VehicleDto> updateVehicle(int id, VehicleDto vehicle) async {
    final res = await _api.put('/vehicles/$id', vehicle.toJson());
    return VehicleDto.fromJson(res.data);
  }

  /// Toggles vehicle active/inactive status
  Future<void> toggleVehicleActive(int id, bool active) async {
    await _api.patch(
      '/vehicles/$id/toggle',
      queryParameters: {'active': active},
    );
  }
}

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository(ref.watch(ApiClientProvider));
});
