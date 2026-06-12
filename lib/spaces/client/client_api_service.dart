import 'dart:convert';
import 'package:http/http.dart' as http;
import 'order_dto.dart';

class ClientApiService {
  // 10.0.2.2 si tu utilises l'émulateur Android standard, sinon localhost ou ton IP
// Pour Flutter Web (Chrome), localhost:8080 est correct, 
// mais vérifie bien la syntaxe exacte avec les deux points :
static const String baseUrl = 'http://localhost:8080/api';

  Future<List<OrderDTO>> getTestOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/test'),
      headers: {'accept': '*/*'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      // On mappe chaque élément du tableau JSON en un objet OrderDTO
      return body.map((dynamic item) => OrderDTO.fromJson(item)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des commandes de test');
    }
  }
}