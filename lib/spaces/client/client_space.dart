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

  Future<void> _onApproveOrder(int id) async {
    try {
      final success = await _apiService.approveOrder(id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livraison approuvée avec succès !'), backgroundColor: Colors.green),
          );
          setState(() {
            _ordersFuture = _apiService.getTestOrders();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de l'approbation de la livraison."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onRejectOrder(int id, String reason) async {
    try {
      final success = await _apiService.rejectOrder(id, reason);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livraison refusée avec succès.'), backgroundColor: Colors.orange),
          );
          setState(() {
            _ordersFuture = _apiService.getTestOrders();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du refus de la livraison.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    HomeTabPage(
      activeOrders: todayOrders,
      onApprove: _onApproveOrder,
      onReject: _onRejectOrder,
    ),
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
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_rounded, index: 0, label: 'Home'),
            _buildNavItem(icon: Icons.history_rounded, index: 1, label: 'History'),
            _buildNavItem(icon: Icons.map_rounded, index: 2, label: 'Map'),
            _buildNavItem(icon: Icons.person_rounded, index: 3, label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}