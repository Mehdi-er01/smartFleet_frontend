import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/dispatch/data/delivery_program_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/domain/delivery_program_status.dart';
import 'package:smartfleet_frontend/features/fleet/data/driver_dto.dart';
import 'package:smartfleet_frontend/features/auth/data/user_dto.dart';
import 'package:smartfleet_frontend/features/fleet/data/vehicle_dto.dart';
import 'package:smartfleet_frontend/features/auth/presentation/login_page.dart';
import 'package:smartfleet_frontend/features/auth/data/auth_repository.dart';
import 'package:smartfleet_frontend/features/dispatch/data/dispatch_repository.dart';
import 'package:smartfleet_frontend/features/fleet/data/vehicle_repository.dart';
import 'package:smartfleet_frontend/core/storage_service.dart';
import 'package:smartfleet_frontend/core/snackbar_service.dart';
import 'package:smartfleet_frontend/features/dispatch/presentation/dispatch_creation_page.dart';
import 'package:smartfleet_frontend/features/dispatch/presentation/map_page.dart';
import 'package:smartfleet_frontend/features/fleet/presentation/ressources_page.dart';
import 'package:smartfleet_frontend/features/auth/presentation/profile_edit_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  UserDto? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ManagerDashboardView(
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
      const DispatchCreationPage(),
      MapPage(managerId: _currentUser?.id),
      const ResourcesPage(),
      ManagerProfilePage(
        currentUser: _currentUser,
        onUserUpdated: (user) {
          setState(() {
            _currentUser = user;
          });
        },
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ---------------------------------------------------------
// MANAGER DASHBOARD — Real metrics, black/white design
// ---------------------------------------------------------
class ManagerDashboardView extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigate;
  const ManagerDashboardView({super.key, this.onNavigate});

  @override
  ConsumerState<ManagerDashboardView> createState() =>
      _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends ConsumerState<ManagerDashboardView> {
  bool _loading = true;
  List<DriverDto> _myDrivers = [];
  List<VehicleDto> _vehicles = [];
  List<DeliveryProgramDto> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fleet = ref.read(fleetRepositoryProvider);
      final dispatch = ref.read(dispatchRepositoryProvider);
      final drivers = await fleet.getMyDrivers();
      final vehicles = await fleet.getVehicles();
      final programs = await dispatch.getPrograms();
      if (mounted) {
        setState(() {
          _myDrivers = drivers;
          _vehicles = vehicles;
          _programs = programs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        SnackbarService.showError('Failed to load dashboard: $e');
      }
    }
  }

  // ── Computed metrics ──
  int get _activeVehicles => _vehicles.where((v) => v.active).length;
  int get _inactiveVehicles => _vehicles.length - _activeVehicles;
  int get _totalDrivers => _myDrivers.length;
  int get _pendingPrograms => _programs
      .where((p) => p.status == DeliveryProgramStatus.pending.value)
      .length;
  int get _inProgressPrograms => _programs
      .where(
        (p) =>
            p.status == DeliveryProgramStatus.inProgress.value ||
            p.status == DeliveryProgramStatus.optimized.value,
      )
      .length;
  int get _completedPrograms => _programs
      .where((p) => p.status == DeliveryProgramStatus.completed.value)
      .length;
  int get _totalOrders =>
      _programs.fold<int>(0, (sum, p) => sum + p.orders.length);
  int get _activeOrders => _programs
      .where((p) => p.status != 'COMPLETED' && p.status != 'CANCELLED')
      .fold<int>(0, (sum, p) => sum + p.orders.length);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildMetricGrid(),
                    const SizedBox(height: 24),
                    _buildFleetOverview(),
                    const SizedBox(height: 24),
                    _buildProgramOverview(),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DASHBOARD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fleet Overview',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _load,
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.refresh, color: Colors.black87, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.person_outline,
                label: 'Drivers',
                value: '$_totalDrivers',
                sub: '$_activeVehicles active vehicles',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.local_shipping_outlined,
                label: 'Vehicles',
                value: '${_vehicles.length}',
                sub: '$_inactiveVehicles inactive',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.assignment_outlined,
                label: 'Programs',
                value: '${_programs.length}',
                sub: '$_pendingPrograms pending',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Orders',
                value: '$_totalOrders',
                sub: '$_activeOrders active',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                sub,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _statusRow(
            'Active Vehicles',
            _activeVehicles,
            _vehicles.length,
            Colors.green,
          ),
          const SizedBox(height: 10),
          _statusRow(
            'Inactive Vehicles',
            _inactiveVehicles,
            _vehicles.length,
            Colors.grey,
          ),
          const SizedBox(height: 10),
          _statusRow(
            'My Drivers',
            _totalDrivers,
            _totalDrivers > 0 ? _totalDrivers : 1,
            Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, int count, int total, Color color) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Programs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _programStat('Pending', _pendingPrograms, Colors.orange),
              _programStat('In Progress', _inProgressPrograms, Colors.blue),
              _programStat('Completed', _completedPrograms, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _programStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.add_circle_outline,
                'New Dispatch',
                'Create a delivery program',
                () => widget.onNavigate?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                Icons.local_shipping_outlined,
                'Fleet',
                'Manage drivers & vehicles',
                () => widget.onNavigate?.call(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// MANAGER PROFILE PAGE
// ---------------------------------------------------------
class ManagerProfilePage extends StatelessWidget {
  final UserDto? currentUser;
  final ValueChanged<UserDto>? onUserUpdated;
  const ManagerProfilePage({super.key, this.currentUser, this.onUserUpdated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'My Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Identity card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFF0F1F5),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.name ?? 'Manager',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            currentUser?.email ?? '—',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (currentUser?.phone != null &&
                              currentUser!.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              currentUser!.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'MANAGER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionLabel('Account Settings'),
              const SizedBox(height: 10),
              _settingsGroup([
                (
                  Icons.person_outline,
                  'Personal Information',
                  () async {
                    if (currentUser == null) return;
                    final updated = await showDialog<UserDto>(
                      context: context,
                      builder: (_) =>
                          ProfileEditDialog(currentUser: currentUser!),
                    );
                    if (updated != null) {
                      onUserUpdated?.call(updated);
                    }
                  },
                ),
                (Icons.business_outlined, 'Company Details', null),
                (Icons.notifications_outlined, 'Notifications', null),
              ]),

              const SizedBox(height: 20),

              _sectionLabel('Support'),
              const SizedBox(height: 10),
              _settingsGroup([
                (Icons.help_outline, 'Help Center', null),
                (Icons.policy_outlined, 'Privacy Policy', null),
              ]),

              const SizedBox(height: 24),

              // Logout
              GestureDetector(
                onTap: () async {
                  await StorageService.deleteToken();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.black87, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    ),
  );

  Widget _settingsGroup(List<(IconData, String, VoidCallback?)> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final (icon, label, onTap) = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.black87, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: Color(0xFFF0F1F5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM FLOATING BOTTOM NAV BAR
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
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.grid_view_rounded, 0),
            _navItem(Icons.assignment, 1),
            _navItem(Icons.map_outlined, 2),
            _navItem(Icons.cases_rounded, 3),
            _navItem(Icons.person_outline, 4),
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
