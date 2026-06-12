import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartfleet_frontend/spaces/driver/inventory_page.dart';
import 'package:smartfleet_frontend/spaces/driver/map_page.dart';

// ---------------------------------------------------------
// 1. DATA MODELS (Adaptés à tes vrais DTO Spring Boot)
// ---------------------------------------------------------

class SubProgramModel {
  final int id;
  final String subProgramNumber;
  final String status;
  final List<int> orderIds;
  final double estimatedDistanceKm;

  SubProgramModel({
    required this.id,
    required this.subProgramNumber,
    required this.status,
    required this.orderIds,
    required this.estimatedDistanceKm,
  });

  factory SubProgramModel.fromJson(Map<String, dynamic> json) {
    return SubProgramModel(
      id: json['id'] ?? 0,
      subProgramNumber: json['subProgramNumber'] ?? 'N/A',
      status: json['status'] ?? 'PENDING',
      orderIds: List<int>.from(json['orderIds'] ?? []),
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num? ?? 0.0).toDouble(),
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String deliveryAddress;
  final String deliveryDescription;
  final String status;
  final double weightKg;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.deliveryAddress,
    required this.deliveryDescription,
    required this.status,
    required this.weightKg,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? 'N/A',
      deliveryAddress: json['deliveryAddress'] ?? 'Adresse non spécifiée',
      deliveryDescription: json['deliveryDescription'] ?? '',
      status: json['status'] ?? 'PENDING',
      weightKg: (json['weightKg'] as num? ?? 0.0).toDouble(),
    );
  }
}

// ---------------------------------------------------------
// 2. MAIN PAGE
// ---------------------------------------------------------
class HomePage extends StatefulWidget {
  final String driverEmail; 
  final int driverId; 
  final String jwtToken; // <-- AJOUT OBLIGATOIRE : Pour authentifier tes requêtes HTTP

  const HomePage({
    super.key, 
    required this.driverEmail, 
    required this.driverId,
    required this.jwtToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

// class _State extends State<HomePage> {} // Omission technique de syntaxe, voir _HomePageState ci-dessous

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<OrderModel>> _activeOrdersFuture;
  late Future<List<OrderModel>> _historyOrdersFuture;
  // Utilise ton adresse IP locale (ex: 10.0.2.2 pour l'émulateur Android ou ton IP réseau)
  final String baseApiUrl = "http://10.0.2.2:8080"; 

  @override
  void initState() {
    super.initState();
    // Charge les données en parrallèle de manière asynchrone conforme à ton backend
    _activeOrdersFuture = _fetchActiveOrders();
    _historyOrdersFuture = _fetchHistoryOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Headers globaux incluant ton Bearer Token validé sur Swagger
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${widget.jwtToken}",
  };

  /// PAGE 1 : Récupère le sous-programme 1 (ou lié au driver) puis charge ses commandes associées
  Future<List<OrderModel>> _fetchActiveOrders() async {
    try {
      // Étape 1 : Obtenir le sous-programme (Ex: ID 1 comme testé sur Swagger)
      final subProgResponse = await http.get(
        Uri.parse("$baseApiUrl/subprograms/1"),
        headers: _headers,
      );

      if (subProgResponse.statusCode == 200) {
        final subProgData = SubProgramModel.fromJson(jsonDecode(subProgResponse.body));
        List<OrderModel> orders = [];

        // Étape 2 : Boucler sur chaque OrderID pour charger ses détails complets
        for (int orderId in subProgData.orderIds) {
          final orderResponse = await http.get(
            Uri.parse("$baseApiUrl/orders/$orderId"),
            headers: _headers,
          );
          if (orderResponse.statusCode == 200) {
            final order = OrderModel.fromJson(jsonDecode(orderResponse.body));
            // On ne garde ici que les commandes non terminées
            if (order.status != "DELIVERED") {
              orders.add(order);
            }
          }
        }
        return orders;
      }
    } catch (e) {
      print("Erreur Fetch Active Orders: $e");
    }
    return [];
  }

  /// PAGE 2 : Récupère la liste de test et filtre les commandes ayant le statut DELIVERED
  Future<List<OrderModel>> _fetchHistoryOrders() async {
    try {
      final response = await http.get(
        Uri.parse("$baseApiUrl/orders/test"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => OrderModel.fromJson(item))
            .where((order) => order.status == "DELIVERED") // Filtrage automatique
            .toList();
      }
    } catch (e) {
      print("Erreur Fetch History: $e");
    }
    return [];
  }

  /// Bouton Action : Approuver une livraison (Bouton Page 1)
  Future<void> _approveOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseApiUrl/orders/$orderId/approve"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Livraison validée avec succès !"), backgroundColor: Colors.green),
        );
        // Rafraîchir l'écran
        setState(() {
          _activeOrdersFuture = _fetchActiveOrders();
          _historyOrdersFuture = _fetchHistoryOrders();
        });
      }
    } catch (e) {
      print("Erreur approbation: $e");
    }
  }

  void _onSearch(String query) {}

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
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(),
            InventoryPage(),
            MapPage(),
            _buildProfileTab(), // Branché sur l'API Profil (Page 4)
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  Widget _buildHomeTab() {
    final displayName = widget.driverEmail.split('@')[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(displayName),
          const SizedBox(height: 24),
          SearchWidget(controller: _searchController, onSubmitted: _onSearch),
          const SizedBox(height: 32),
          const Text('Commandes actuelles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 16),
          
          // Gestion asynchrone des commandes actives (Page 1)
          FutureBuilder<List<OrderModel>>(
            future: _activeOrdersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              final activeOrders = snapshot.data ?? [];
              if (activeOrders.isEmpty) {
                return const Text("Aucune commande en cours pour ce trajet.");
              }
              return Column(
                children: activeOrders.map((order) => _buildActiveDeliveryCard(order)).toList(),
              );
            },
          ),
          
          const SizedBox(height: 32),
          const Text('Historique des livraisons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 16),
          
          // Gestion asynchrone de l'historique (Page 2)
          FutureBuilder<List<OrderModel>>(
            future: _historyOrdersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Text("Aucun historique disponible.");
              }
              return Column(
                children: history.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildHistoryCard(order),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name == "ADIL" ? "Adil" : name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Conducteur Connecté', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE2F6D1), Color(0xFFB1EAA3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commande N°', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.black, size: 28),
                onPressed: () => _approveOrder(order.id), // Bouton pour valider la livraison
              )
            ],
          ),
          const SizedBox(height: 12),
          Text('Adresse: ${order.deliveryAddress}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (order.deliveryDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${order.deliveryDescription}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ]
        ],
      ),
    );
  }

  Widget _buildHistoryCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande ${order.orderNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(order.deliveryAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(12)),
            child: Text(order.status, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// PAGE 4 : Écran de Profil simple branché sur /auth/me
  Widget _buildProfileTab() {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: http.get(Uri.parse("$baseApiUrl/auth/me"), headers: _headers).then((res) => jsonDecode(res.body)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final profile = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Mon Profil", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text("Nom : ${profile['name']}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Email : ${profile['email']}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Téléphone : ${profile['phone'] ?? 'Non renseigné'}", style: const TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. SEARCH WIDGET
// ---------------------------------------------------------
class SearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const SearchWidget({super.key, required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(28)),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: 'Rechercher une livraison...',
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. CUSTOM BOTTOM NAV BAR
// ---------------------------------------------------------
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
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_outlined, index: 0),
            _buildNavItem(icon: Icons.inventory_2_outlined, index: 1),
            _buildNavItem(icon: Icons.map_outlined, index: 2),
            _buildNavItem(icon: Icons.person_outline, index: 3), // Changement d'icône pour le Profil
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(24)),
        child: Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 26),
      ),
    );
  }
}