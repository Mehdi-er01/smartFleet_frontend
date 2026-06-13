import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/dto/user_dto.dart';
import 'order_dto.dart';
import 'order_detail_sheet.dart';

class HomeTabPage extends StatelessWidget {
  final List<OrderDTO> activeOrders;
  final List<OrderDTO> todayOrders;
  final UserDto? currentUser;

  const HomeTabPage({
    super.key,
    required this.activeOrders,
    required this.todayOrders,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = activeOrders.where((o) => o.status == 'PENDING').length;
    final inTransitCount = activeOrders.where((o) => o.status == 'IN_TRANSIT' || o.status == 'IN_PROGRESS').length;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 24),

            // ── Metric grid (manager-style) ──
            Row(
              children: [
                _metricCard(Icons.pending_actions_outlined, '$pendingCount', 'Pending'),
                const SizedBox(width: 12),
                _metricCard(Icons.local_shipping_outlined, '$inTransitCount', 'In Transit'),
              ],
            ),
            const SizedBox(height: 24),

            // ── Today section ──
            Text(
              'TODAY\'S DELIVERIES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTodayDate(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            const SizedBox(height: 16),

            if (todayOrders.isEmpty)
              _buildEmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'No deliveries today',
                sub: 'You have no orders scheduled for today.',
              )
            else
              ...todayOrders.map(
                (order) => GestureDetector(
                  onTap: () => showOrderDetailSheet(context, order),
                  child: _buildOrderCard(order),
                ),
              ),

            const SizedBox(height: 24),

            // ── All active section ──
            Text(
              'ALL ACTIVE ORDERS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              '${activeOrders.length} order${activeOrders.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            const SizedBox(height: 16),

            if (activeOrders.isEmpty)
              _buildEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No active orders',
                sub: 'All your orders have been completed.',
              )
            else
              ...activeOrders.map(
                (order) => GestureDetector(
                  onTap: () => showOrderDetailSheet(context, order),
                  child: _buildOrderCard(order),
                ),
              ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final salutation = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Row(
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
                '$salutation, ${currentUser?.name ?? "Guest"}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                currentUser?.email ?? 'SmartFleet Client',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.black87, size: 20),
        ),
      ],
    );
  }

  Widget _metricCard(IconData icon, String value, String label) {
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderDTO order) {
    final statusInfo = _statusStyle(order.status);
    final isToday = _isToday(order.estimatedDeliveryTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_shipping_outlined, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.deliveryAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusInfo.$2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusInfo.$1,
              style: TextStyle(color: statusInfo.$3, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String sub}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  bool _isToday(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) {
      return false;
    }
  }

  /// Returns (label, bgColor, textColor)
  (String, Color, Color) _statusStyle(String status) {
    switch (status) {
      case 'PENDING':
        return ('PENDING', const Color(0xFFF0F1F5), Colors.black54);
      case 'IN_TRANSIT':
      case 'IN_PROGRESS':
        return ('IN TRANSIT', Colors.black, Colors.white);
      case 'DELIVERED':
        return ('DELIVERED', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'FAILED':
      case 'CANCELLED':
        return ('CANCELLED', const Color(0xFFFFEBEE), const Color(0xFFC62828));
      default:
        return (status, const Color(0xFFF0F1F5), Colors.black54);
    }
  }
}