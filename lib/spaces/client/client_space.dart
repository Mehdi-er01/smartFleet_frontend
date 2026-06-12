import 'package:flutter/material.dart';
import 'client_api_service.dart';
import 'order_dto.dart';
import 'home_tab_page.dart';
import 'historique_commandes.dart'; // Vérifie bien le nom exact de ton fichier
import 'suivi_map_page.dart';
import 'profil_client_page.dart';

class ClientSpace extends StatefulWidget {
  const ClientSpace({super.key});

  @override
  State<ClientSpace> createState() => _ClientSpaceState();
}

class _ClientSpaceState extends State<ClientSpace> {
  int _currentNavIndex = 0;
  final ClientApiService _apiService = ClientApiService();
  late Future<List<OrderDTO>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    // On charge toutes les commandes une seule fois au démarrage
    _ordersFuture = _apiService.getTestOrders();
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<OrderDTO>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Erreur de connexion API : ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Aucune donnée reçue du serveur"));
            }

            final allOrders = snapshot.data!;

            // 1. CALCUL DE LA DATE D'AUJOURD'HUI (Format: AAAA-MM-JJ)
            // final now = DateTime.now();
            // final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
final DateTime now = DateTime.now();
final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
            // 2. FILTRAGE DYNAMIQUE
            // Page 1 (Aujourd'hui) : Doit être planifiée aujourd'hui ET pas encore livrée
            // final todayOrders = allOrders.where((o) {
            //   final isPlannedToday = o.estimatedDeliveryTime != null && 
            //                          o.estimatedDeliveryTime!.startsWith(todayStr);
            //   return isPlannedToday && o.status != "DELIVERED";
            // }).toList();
            final todayOrders = allOrders.where((o) {
  final bool isPlannedToday = o.estimatedDeliveryTime != null && 
                               o.estimatedDeliveryTime!.startsWith(todayStr);
  return isPlannedToday && o.status != "DELIVERED";
}).toList();

            // Page 2 (Historique) : Toutes les commandes livrées
            // final historyOrders = allOrders.where((o) => o.status == "DELIVERED").toList();
            
            // // Page 3 (Suivi Map) : La commande en cours de route prioritaire, sinon la première du jour
            // final OrderDTO? trackingOrder = allOrders.firstWhere(
            //   (o) => o.status == "IN_PROGRESS",
            //   orElse: () => todayOrders.isNotEmpty ? todayOrders.first : allOrders.first,
            // );
            final historyOrders = allOrders.where((o) {
  final bool isDelivered = o.status == "DELIVERED";
  final bool isPastDate = o.estimatedDeliveryTime != null && 
                           !o.estimatedDeliveryTime!.startsWith(todayStr) && 
                           DateTime.parse(o.estimatedDeliveryTime!).isBefore(now);
  return isDelivered || isPastDate;
}).toList();

// 4. Commande pour le suivi MAP (La première en cours, sinon la première d'aujourd'hui)
final OrderDTO? trackingOrder = allOrders.firstWhere(
  (o) => o.status == "IN_PROGRESS",
  orElse: () => todayOrders.isNotEmpty ? todayOrders.first : allOrders.first,
);

            return IndexedStack(
  index: _currentNavIndex,
  children: [
    HomeTabPage(activeOrders: todayOrders),                   // Affiche les commandes du jour
    HistoriqueCommandesPage(history: historyOrders),          // Historique vide si aucune commande n'est livrée/passée
    SuiviMapPage(activeOrder: trackingOrder),
    const ProfilClientPage(),
  ],
);
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}

// ---- NAVIGATION BAR PREMIUM RE-UTILISABLE ----
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 0),
            _buildNavItem(Icons.local_shipping_outlined, 1),
            _buildNavItem(Icons.map_outlined, 2),
            _buildNavItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 26),
      ),
    );
  }
}