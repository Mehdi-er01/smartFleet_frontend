import 'package:flutter/material.dart';
import 'order_dto.dart';

class HomeTabPage extends StatelessWidget {
  final List<OrderDTO> activeOrders;
  
  const HomeTabPage({super.key, required this.activeOrders});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 24),
          const Text(
            'Mes commandes en cours',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          if (activeOrders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Aucune livraison prévue pour aujourd'hui."),
              ),
            )
          else
            Column(
              children: activeOrders.map((order) => _buildDeliveryCard(order)).toList(),
            ),
          const SizedBox(height: 100), // Espace pour la Navbar mobile
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bonjour, Amine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Casablanca, Maroc', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(OrderDTO order) {
    final isEnRoute = order.status == "IN_PROGRESS";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isEnRoute ? Colors.orange.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: isEnRoute ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 12),
          Text("📝 Description : ${order.deliveryDescription ?? 'Aucune spécification'}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("📦 Poids : ${order.weightKg} kg"),
              Text("📐 Volume : ${order.volumeM2} m²"),
            ],
          )
        ],
      ),
    );
  }
}