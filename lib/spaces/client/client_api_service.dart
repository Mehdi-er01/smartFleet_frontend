import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfleet_frontend/service/storage_service.dart';
import 'order_dto.dart';

class ClientApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'accept': '*/*',
      'content-type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<OrderDTO>> getTestOrders() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/test'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => OrderDTO.fromJson(item)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des commandes de test');
    }
  }

  Future<bool> approveOrder(int orderId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/approve'),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<bool> rejectOrder(int orderId, String reason) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/reject'),
      headers: headers,
      body: jsonEncode(reason),
    );
    return response.statusCode == 200;
  }
}