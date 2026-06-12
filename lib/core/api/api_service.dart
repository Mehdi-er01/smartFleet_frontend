// import 'dart:convert';
// import 'package:http/http.dart' as http;


// class OrderApi {
//   static const String baseUrl = "http://localhost:8080/api/orders";

//   static Future<List<OrderModel>> getOrders() async {
//     final res = await http.get(Uri.parse(baseUrl));

//     final List data = jsonDecode(res.body);

//     return data.map((e) => OrderModel.fromJson(e)).toList();
//   }
// }