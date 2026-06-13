import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/service/client_repository.dart';
import 'package:smartfleet_frontend/service/auth_service.dart';
import 'package:smartfleet_frontend/dto/user_dto.dart';
import 'order_dto.dart';
import 'home_tab_page.dart';
import 'historique_commandes.dart';
import 'suivi_map_page.dart';
import 'profil_client_page.dart';

class ClientSpace extends ConsumerStatefulWidget {
  const ClientSpace({super.key});

  @override
  ConsumerState<ClientSpace> createState() => _ClientSpaceState();
}

class _ClientSpaceState extends ConsumerState<ClientSpace> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<OrderDTO> _allOrders = [];
  UserDto? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(clientRepositoryProvider);
      final authService = ref.read(authServiceProvider);
      
      final user = await authService.getCurrentUser();
      final orders = await repository.getOrders();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          // Only show orders that belong to the logged-in client
          if (user != null) {
            _allOrders = orders.where((o) => o.clientId == user.id).toList();
          } else {
            _allOrders = []; // Fallback if user is null
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Erreur de chargement: $_error"))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildBody(),
                ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  Widget _buildBody() {
    final now = DateTime.now();

    // Active = anything not yet delivered/failed
    final activeOrders = _allOrders
        .where((o) => o.status != 'DELIVERED' && o.status != 'FAILED' && o.status != 'CANCELLED')
        .toList();

    // Today's orders = active orders whose estimatedDeliveryTime falls on today
    final todayOrders = activeOrders.where((o) {
      if (o.estimatedDeliveryTime == null) return false;
      try {
        final dt = DateTime.parse(o.estimatedDeliveryTime!);
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();


    // Tracking = prefer IN_TRANSIT/IN_PROGRESS, then any active order
    final OrderDTO? trackingOrder = activeOrders.cast<OrderDTO?>().firstWhere(
          (o) => o?.status == 'IN_TRANSIT' || o?.status == 'IN_PROGRESS',
          orElse: () => activeOrders.isNotEmpty ? activeOrders.first : null,
        );

    final pages = [
      HomeTabPage(activeOrders: activeOrders, todayOrders: todayOrders, currentUser: _currentUser),
      HistoriqueCommandesPage(history: _allOrders),
      SuiviMapPage(activeOrder: trackingOrder),
      ProfilClientPage(currentUser: _currentUser),
    ];

    return SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _currentNavIndex,
        children: pages,
      ),
    );
  }
}

// ---- NAVIGATION BAR PREMIUM RE-UTILISABLE ----
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
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
        duration: const Duration(milliseconds: 255),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white60,
          size: 26,
        ),
      ),
    );
  }
}