import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/spaces/manager/dispatch_creation_page.dart';
import 'package:smartfleet_frontend/spaces/manager/map_page.dart';
import 'package:smartfleet_frontend/spaces/manager/ressources_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // The Manager's Page Views
  final List<Widget> _pages = const [
    ManagerDashboardView(), // The redesigned dashboard
    DispatchCreationPage(),
    MapPage(),
    ResourcesPage(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true, // Allows content to scroll behind the floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ---------------------------------------------------------
// MANAGER DASHBOARD VIEW
// ---------------------------------------------------------
class ManagerDashboardView extends StatelessWidget {
  const ManagerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Hero Status Card (Matches Driver Style)
            _buildFleetSummaryCard(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Live Fleet', 'View Map'),
            const SizedBox(height: 12),
            _buildHorizontalFleetList(),

            const SizedBox(height: 32),
            const Text(
              'Issues requiring attention',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 16),
            _buildActionAlert(
              title: 'Delayed: TRK-042',
              subtitle: 'Ahmed R. stuck in Settat traffic',
              isUrgent: true,
            ),
            _buildActionAlert(
              title: 'Failed Delivery',
              subtitle: 'Order #7620937 - Recipient not home',
              isUrgent: false,
            ),
            
            const SizedBox(height: 120), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMARTFLEET MANAGER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.black54),
            ),
            Text(
              'Operations',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.tune, color: Colors.black),
        )
      ],
    );
  }

  Widget _buildFleetSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2F6D1), Color(0xFFB1EAA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Efficiency', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          const Text('94.2%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('12', 'Active Trucks'),
              _buildStatItem('145', 'Pending'),
              _buildStatItem('89', 'Completed'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        Text(action, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHorizontalFleetList() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFleetCard('Ahmed R.', 'TRK-042', 0.85),
          _buildFleetCard('Fatima Z.', 'TRK-019', 0.35),
          _buildFleetCard('Youssef B.', 'TRK-088', 0.15),
        ],
      ),
    );
  }

  Widget _buildFleetCard(String name, String id, double progress) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFF0F1F5),
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const Icon(Icons.person, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionAlert({required String title, required String subtitle, required bool isUrgent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFF0F1F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.info_outline,
              color: isUrgent ? Colors.red : Colors.black45,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM FLOATING BOTTOM NAV BAR (Shared with Driver App)
// ---------------------------------------------------------
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

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
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.grid_view_rounded, 0),
            _navItem(Icons.assignment, 1),
            _navItem(Icons.map_outlined, 2),
            _navItem(Icons.cases_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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