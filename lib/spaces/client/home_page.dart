// import 'package:flutter/material.dart';
// import 'package:smartfleet_frontend/models/order_model.dart';

// class HomePage extends StatelessWidget {
//   final List<OrderModel> orders;

//   const HomePage({super.key, required this.orders});

//   @override
//   Widget build(BuildContext context) {
//     final today = DateTime.now();

//     final todayOrders = orders.where((o) {
//       if (o.createdAt == null) return false;

//       final d = DateTime.parse(o.createdAt!);

//       return d.year == today.year &&
//           d.month == today.month &&
//           d.day == today.day;
//     }).toList();

//     final active = todayOrders.isNotEmpty ? todayOrders.first : null;

//     return Center(
//       child: active == null
//           ? const Text("Aucune commande aujourd’hui")
//           : Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(active.orderNumber,
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     Text(active.status),
//                     Text(active.deliveryAddress),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }