import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:smartfleet_frontend/dto/user_dto.dart';
import 'package:smartfleet_frontend/login_page.dart';
import 'package:smartfleet_frontend/service/auth_service.dart';
import 'package:smartfleet_frontend/service/driver_repository.dart';
import 'package:smartfleet_frontend/service/storage_service.dart';
import 'package:smartfleet_frontend/spaces/driver/inventory_page.dart';
import 'package:smartfleet_frontend/spaces/driver/map_page.dart';

// ─────────────────────────────────────────
// ROOT SHELL
// ─────────────────────────────────────────
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentNavIndex = 0;

  bool _isLoading = true;
  String? _error;
  SubProgramDto? _activeSubProgram;
  List<SubProgramDto> _allSubPrograms = [];
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
      final repo = ref.read(driverRepositoryProvider);
      final auth = ref.read(authServiceProvider);
      final results = await Future.wait([
        repo.getActiveSubProgram(),
        repo.getMySubPrograms(),
        auth.getCurrentUser(),
      ]);
      if (mounted) {
        setState(() {
          _activeSubProgram = results[0] as SubProgramDto?;
          _allSubPrograms = results[1] as List<SubProgramDto>;
          _currentUser = results[2] as UserDto?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(
        activeSubProgram: _activeSubProgram,
        allSubPrograms: _allSubPrograms,
        currentUser: _currentUser,
        onRefresh: _loadData,
      ),
      const InventoryPage(),
      MapPage(activeSubProgram: _activeSubProgram),
      _ProfileTab(currentUser: _currentUser),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: IndexedStack(index: _currentNavIndex, children: pages),
            ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final SubProgramDto? activeSubProgram;
  final List<SubProgramDto> allSubPrograms;
  final UserDto? currentUser;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.activeSubProgram,
    required this.allSubPrograms,
    required this.currentUser,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final history = allSubPrograms
        .where((sp) => sp.id != activeSubProgram?.id)
        .toList();

    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFF0F1F5),
                    child: Icon(Icons.person, color: Colors.black54, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$salutation, ${currentUser?.name ?? "Driver"}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentUser?.email ?? 'SmartFleet Driver',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Metrics ──
            Row(
              children: [
                _metricCard(
                  Icons.assignment_outlined,
                  '${allSubPrograms.length}',
                  'Total Routes',
                  allSubPrograms.isEmpty
                      ? 'none'
                      : '${allSubPrograms.where((s) => s.status == 'COMPLETED').length} completed',
                ),
                const SizedBox(width: 12),
                _metricCard(
                  Icons.local_shipping_outlined,
                  activeSubProgram != null
                      ? '${activeSubProgram!.approvedOrdersCount}/${activeSubProgram!.totalOrdersCount}'
                      : '—',
                  'Deliveries',
                  activeSubProgram != null ? 'active route' : 'no active route',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Active subprogram ──
            Text(
              'ACTIVE ROUTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Current Assignment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            activeSubProgram != null
                ? _ActiveCard(sp: activeSubProgram!)
                : _emptyCard(
                    Icons.route_outlined,
                    'No active route',
                    'You have no subprogram assigned right now.',
                  ),

            const SizedBox(height: 24),

            // ── History ──
            Text(
              'ROUTE HISTORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${history.length} past route${history.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            if (history.isEmpty)
              _emptyCard(
                Icons.history_outlined,
                'No history yet',
                'Completed routes will appear here.',
              )
            else
              ...history.map((sp) => _HistoryCard(sp: sp)),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label, String sub) {
    return Expanded(
      child: Container(
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
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
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
      ),
    );
  }

  Widget _emptyCard(IconData icon, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ACTIVE ROUTE CARD
// ─────────────────────────────────────────
class _ActiveCard extends StatelessWidget {
  final SubProgramDto sp;
  const _ActiveCard({required this.sp});

  @override
  Widget build(BuildContext context) {
    final progress = sp.totalOrdersCount > 0
        ? sp.approvedOrdersCount / sp.totalOrdersCount
        : 0.0;

    final statusInfo = _statusStyle(sp.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
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
                  Text(
                    'SUBPROGRAM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sp.subProgramNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusInfo.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${sp.approvedOrdersCount}/${sp.totalOrdersCount} delivered',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _statChip(
                Icons.receipt_outlined,
                '${sp.totalOrdersCount} orders',
              ),
              const SizedBox(width: 10),
              if (sp.estimatedDistanceKm != null)
                _statChip(
                  Icons.straighten_outlined,
                  '${sp.estimatedDistanceKm!.toStringAsFixed(1)} km',
                ),
              if (sp.estimatedDurationMinutes != null) ...[
                const SizedBox(width: 10),
                _statChip(
                  Icons.timer_outlined,
                  '${sp.estimatedDurationMinutes} min',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return ('IN PROGRESS', Colors.orange);
      case 'COMPLETED':
        return ('COMPLETED', Colors.green);
      case 'PENDING':
        return ('PENDING', Colors.grey);
      default:
        return (status, Colors.grey);
    }
  }
}

// ─────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final SubProgramDto sp;
  const _HistoryCard({required this.sp});

  @override
  Widget build(BuildContext context) {
    final isCompleted = sp.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline : Icons.route_outlined,
              color: isCompleted ? const Color(0xFF2E7D32) : Colors.black54,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sp.subProgramNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${sp.totalOrdersCount} orders · ${sp.estimatedDistanceKm?.toStringAsFixed(1) ?? "0"} km',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCompleted ? 'Done' : sp.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCompleted ? const Color(0xFF2E7D32) : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final UserDto? currentUser;
  const _ProfileTab({this.currentUser});

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
                            currentUser?.name ?? 'Driver',
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
                        'DRIVER',
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

              // Support group
              _sectionLabel('Support'),
              const SizedBox(height: 10),
              _settingsGroup([
                (Icons.help_outline, 'Help Center'),
                (Icons.policy_outlined, 'Privacy Policy'),
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

  Widget _settingsGroup(List<(IconData, String)> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final (icon, label) = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              Padding(
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

// ─────────────────────────────────────────
// BOTTOM NAV BAR
// ─────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNavBar({required this.currentIndex, required this.onTap});

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
            _navItem(Icons.home_outlined, 0),
            _navItem(Icons.inventory_2_outlined, 1),
            _navItem(Icons.map_outlined, 2),
            _navItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
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
