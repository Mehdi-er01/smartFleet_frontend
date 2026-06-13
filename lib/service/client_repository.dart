import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/service/api_client.dart';
import 'package:smartfleet_frontend/spaces/client/order_dto.dart';

class ClientRepository {
  final ApiClient _apiClient;

  ClientRepository(this._apiClient);

  Future<List<OrderDTO>> getOrders() async {
    try {
      var response = await _apiClient.get('/orders');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        List<dynamic> data = response.data;
        return data.map((json) => OrderDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error fetching client orders: $e');
    }
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final apiClient = ref.watch(ApiClientProvider);
  return ClientRepository(apiClient);
});
