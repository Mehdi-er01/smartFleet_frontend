import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/spaces/driver/inventory_page.dart';
import 'package:smartfleet_frontend/spaces/driver/map_page.dart';

// ---------------------------------------------------------
// 1. DATA MODELS (Ready for your backend JSON serialization)
// ---------------------------------------------------------
class DeliveryModel {
  final String trackingNumber;
  final String fromLocation;
  final String toLocation;
  final String arrivalDate;
  final String status;
  final double progress; // 0.0 to 1.0

  DeliveryModel({
    required this.trackingNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.arrivalDate,
    required this.status,
    required this.progress,
  });
}

// ---------------------------------------------------------
// 2. MAIN PAGE (Stateful for navigation & input handling)
// ---------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Mock data simulating a backend fetch
  final DeliveryModel _activeDelivery = DeliveryModel(
    trackingNumber: '#36123217',
    fromLocation: 'Paris',
    toLocation: 'Berlin',
    arrivalDate: '21 Dec, 2025',
    status: 'In transit',
    progress: 0.65,
  );

  final List<DeliveryModel> _deliveryHistory = [
    DeliveryModel(
      trackingNumber: '#7620937',
      fromLocation: 'Paris',
      toLocation: 'Berlin',
      arrivalDate: '15 Dec, 2025',
      status: 'Delivered',
      progress: 1.0,
    ),
    DeliveryModel(
      trackingNumber: '#7620938',
      fromLocation: 'Settat',
      toLocation: 'Casablanca',
      arrivalDate: '10 Dec, 2025',
      status: 'Delivered',
      progress: 1.0,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    // TODO: Trigger backend search/filter here
    print("Searching for: $query");
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    // TODO: Handle actual page transitions or state changes here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        // Using IndexedStack allows you to keep the state of different pages 
        // alive while switching between bottom nav tabs.
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(),
            InventoryPage(),
            MapPage(),
            const Center(child: Text("Settings Page")),

          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  // Extracted the home tab content so the build method stays clean
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 24),
          
          // Functional Search Widget
          SearchWidget(
            controller: _searchController,
            onSubmitted: _onSearch,
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Nearest deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildActiveDeliveryCard(_activeDelivery),
          
          const SizedBox(height: 32),
          const Text(
            'Delivery history',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Dynamically building the history list from the model
          ..._deliveryHistory.map((delivery) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildHistoryCard(delivery),
              )),
          
          const SizedBox(height: 120),
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
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diane Lara',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Berlin',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {
              // TODO: Fetch notifications
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryCard(DeliveryModel delivery) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2F6D1), Color(0xFFB1EAA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking number', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    delivery.trackingNumber,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  delivery.status,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 6,
                    width: constraints.maxWidth * delivery.progress,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(delivery.fromLocation, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('To', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(delivery.toLocation, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Arrival date', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(delivery.arrivalDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DeliveryModel delivery) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ${delivery.trackingNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'From ${delivery.fromLocation} to ${delivery.toLocation}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              delivery.status,
              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. FUNCTIONAL SEARCH WIDGET
// ---------------------------------------------------------
class SearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const SearchWidget({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Track your shipment',
          hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                // TODO: Trigger QR Scanner logic here
                print("QR Scanner tapped");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. FUNCTIONAL BOTTOM NAV BAR
// ---------------------------------------------------------
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
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_outlined, index: 0),
            _buildNavItem(icon: Icons.inventory_2_outlined, index: 1),
            _buildNavItem(icon: Icons.map_outlined, index: 2),
            _buildNavItem(icon: Icons.settings_outlined, index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white70,
          size: 26,
        ),
      ),
    );
  }
}