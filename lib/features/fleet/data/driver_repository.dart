import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/api_client.dart';
import 'package:smartfleet_frontend/features/fleet/data/driver_dto.dart';

class FleetDriverRepository {
  final ApiClient _apiClient;
  FleetDriverRepository(this._apiClient);

  /// Returns drivers assigned to the current manager
  Future<List<DriverDto>> getMyDrivers() async {
    final res = await _apiClient.get('/drivers/my-drivers');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  /// Returns drivers not assigned to any manager
  Future<List<DriverDto>> getUnassignedDrivers() async {
    final res = await _apiClient.get('/drivers/unassigned');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  /// Assigns a driver to the current manager
  /// Backend: POST /drivers/{id}/assign → UserDTO
  Future<void> assignDriver(int driverId) async {
    await _apiClient.post('/drivers/$driverId/assign', {});
  }

  /// Unassigns a driver from the current manager
  /// Backend: POST /drivers/{id}/unassign → UserDTO
  Future<void> unassignDriver(int driverId) async {
    await _apiClient.post('/drivers/$driverId/unassign', {});
  }

  /// Returns GPS locations of manager's drivers
  /// Backend: GET /drivers/my-drivers/locations → List<DriverDTO>
  Future<List<DriverDto>> getDriverLocations() async {
    final res = await _apiClient.get('/drivers/my-drivers/locations');
    return (res.data as List).map((j) => DriverDto.fromJson(j)).toList();
  }

  Future<void> updateDriverLocation(DriverDto driver) async {
    var res = await _apiClient.put(
      '/drivers/${driver.id}/location',
      driver.toJson(),
    );
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return;
    }
    throw Exception('Failed to update driver location');
  }
}

final fleetDriverRepositoryProvider = Provider<FleetDriverRepository>((ref) {
  return FleetDriverRepository(ref.watch(ApiClientProvider));
});
