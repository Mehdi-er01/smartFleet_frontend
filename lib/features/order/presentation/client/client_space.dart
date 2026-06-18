import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/order/data/order_repository.dart';
import 'package:smartfleet_frontend/features/auth/data/auth_repository.dart';
import 'package:smartfleet_frontend/features/auth/data/user_dto.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/order/domain/order_status.dart';
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
  List<OrderDto> _allOrders = [];
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
      final repository = ref.read(orderRepositoryProvider);
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
          : RefreshIndicator(onRefresh: _loadData, child: _buildBody()),
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
        .where(
          (o) =>
              o.status != OrderStatus.delivered.value &&
              o.status != OrderStatus.rejected.value &&
              o.status != OrderStatus.cancelled.value,
        )
        .toList();

    // Today's orders = active orders whose estimatedDeliveryTime falls on today
    final todayOrders = activeOrders.where((o) {
      if (o.estimatedDeliveryTime == null) return false;
      try {
        final dt = DateTime.parse(o.estimatedDeliveryTime!);
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();

    // Tracking = prefer IN_TRANSIT/IN_PROGRESS, then any active order
    final OrderDto? trackingOrder = activeOrders.cast<OrderDto?>().firstWhere(
      (o) => o?.status == OrderStatus.inTransit.value,
      orElse: () => activeOrders.isNotEmpty ? activeOrders.first : null,
    );

    final pages = [
      HomeTabPage(
        activeOrders: activeOrders,
        todayOrders: todayOrders,
        currentUser: _currentUser,
      ),
      HistoriqueCommandesPage(history: _allOrders),
      SuiviMapPage(activeOrder: trackingOrder),
      ProfilClientPage(currentUser: _currentUser),
    ];

    return SafeArea(
      bottom: false,
      child: IndexedStack(index: _currentNavIndex, children: pages),
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
          color: const Color(0xFF0F172A),
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
            _buildNavItem(icon: Icons.home_rounded, index: 0, label: 'Home'),
            _buildNavItem(
              icon: Icons.history_rounded,
              index: 1,
              label: 'History',
            ),
            _buildNavItem(icon: Icons.map_rounded, index: 2, label: 'Map'),
            _buildNavItem(
              icon: Icons.person_rounded,
              index: 3,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
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
