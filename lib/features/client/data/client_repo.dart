import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/api_client.dart';
import 'package:smartfleet_frontend/features/client/data/client_dto.dart';

class ClientRepo {
  final ApiClient _apiClient;
  ClientRepo(this._apiClient);
  Future<ClientDto> getClient(int id) async {
    final response = await _apiClient.get('/clients/$id');
    if (response.statusCode == 200) {
      return ClientDto.fromJson(response.data);
    } else {
      throw Exception('Failed to load client');
    }
  }

  Future<List<ClientDto>> getClients() async {
    final response = await _apiClient.get('/clients');
    if (response.statusCode == 200) {
      return List<ClientDto>.from(
        response.data.map((x) => ClientDto.fromJson(x)),
      );
    } else {
      throw Exception('Failed to load clients');
    }
  }

  /// Searches clients locally by name, email, or company
  Future<List<ClientDto>> searchClients(String query) async {
    final all = await getClients();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where(
          (c) =>
              (c.name?.toLowerCase().contains(q) ?? false) ||
              (c.email?.toLowerCase().contains(q) ?? false) ||
              (c.companyName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}

final clientRepoProvider = Provider(
  (ref) => ClientRepo(ref.watch(ApiClientProvider)),
);
