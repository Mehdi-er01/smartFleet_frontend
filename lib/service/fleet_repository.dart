import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/driver_dto.dart';
import 'package:smartfleet_frontend/dto/vehicle_dto.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class FleetRepository {
  final ApiClient _api;
  FleetRepository(this._api);

  // ─── DRIVERS ───────────────────────────────────────────
  // Backend: GET /drivers/my-drivers → List<UserDTO>
  // Backend: GET /drivers/unassigned → List<UserDTO>

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
  /// Backend: POST /drivers/{id}/assign → UserDTO
  Future<void> assignDriver(int driverId) async {
    await _api.post('/drivers/$driverId/assign', {});
  }

  /// Unassigns a driver from the current manager
  /// Backend: POST /drivers/{id}/unassign → UserDTO
  Future<void> unassignDriver(int driverId) async {
    await _api.post('/drivers/$driverId/unassign', {});
  }

  /// Returns GPS locations of manager's drivers
  /// Backend: GET /drivers/my-drivers/locations → List<DriverDTO>
  Future<List<DriverDto>> getDriverLocations() async {
    final res = await _api.get('/drivers/my-drivers/locations');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  // ─── VEHICLES ──────────────────────────────────────────
  // Backend: GET /vehicles → List<VehicleDTO>
  // Backend: POST /vehicles → VehicleDTO
  // Backend: PUT /vehicles/{id} → VehicleDTO
  // Backend: PATCH /vehicles/{id}/toggle?active= → void

  /// Returns all vehicles for the current manager
  Future<List<VehicleDto>> getVehicles() async {
    final res = await _api.get('/vehicles');
    return (res.data as List).map((j) => VehicleDto.fromJson(j)).toList();
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
