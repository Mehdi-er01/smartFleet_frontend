// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:smartfleet_frontend/models/order_model.dart';
// import 'package:smartfleet_frontend/spaces/client/client_space.dart' hide OrderModel;
// // import '../models/order_model.dart';

// class OrderApi {
//   static const String baseUrl =
//       "http://10.0.2.2:8080/api/orders/test"; // IMPORTANT

//   static Future<List<OrderModel>> getOrders() async {
//     final res = await http.get(Uri.parse(baseUrl));

//     print("STATUS = ${res.statusCode}");
//     print("BODY = ${res.body}");

//     if (res.statusCode == 200) {
//       final List data = jsonDecode(res.body);
//       return data.map((e) => OrderModel.fromJson(e)).toList();
//     } else {
//       throw Exception("API ERROR");
//     }
//   }
// }