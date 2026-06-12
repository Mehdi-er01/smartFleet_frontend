// import 'package:flutter/material.dart';
// import 'package:smartfleet_frontend/models/order_model.dart';

// class DetailsCommandePage extends StatelessWidget {
//   final OrderModel order;

//   const DetailsCommandePage({super.key, required this.order});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Commande ${order.orderNumber}"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Statut: ${order.status}"),
//             const SizedBox(height: 10),

//             Text("Départ: ${order.fromLocation}"),
//             Text("Destination: ${order.toLocation}"),
//             const SizedBox(height: 10),

//             Text("Position actuelle: ${order.currentLocation}"),
//             const SizedBox(height: 10),

//             Text("Livreur: ${order.driverName}"),
//             Text("Véhicule: ${order.vehicle}"),
//             const SizedBox(height: 10),

//             Text("Temps estimé: ${order.estimatedTime}"),

//             const SizedBox(height: 20),

//             LinearProgressIndicator(
//               value: order.progress,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }