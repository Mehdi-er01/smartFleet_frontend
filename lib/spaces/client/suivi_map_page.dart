import 'package:flutter/material.dart';
import 'order_dto.dart';

class SuiviMapPage extends StatelessWidget {
  final OrderDTO? activeOrder;

  const SuiviMapPage({super.key, required this.activeOrder});

  @override
  Widget build(BuildContext context) {
    if (activeOrder == null) {
      return const Scaffold(body: Center(child: Text("Aucun colis en cours d'acheminement")));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Simulation conteneur Map (Google Maps / OpenStreetMap)
          Container(
            color: const Color(0xFFE3ECEF),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 8),
                  Text("Coordonnées de livraison : \nLat : ${activeOrder!.deliveryLatitude} | Lng : ${activeOrder!.deliveryLongitude}", 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
            ),
          ),
          // Carte flotteur d'informations colis inférieurs
          Positioned(
            bottom: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Suivi ${activeOrder!.orderNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(activeOrder!.estimatedDeliveryTime ?? "En calcul", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.orangeAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Destination finale : ${activeOrder!.deliveryAddress}", style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}