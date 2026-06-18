import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/order/domain/order_status.dart';
import 'order_detail_sheet.dart';

class HistoriqueCommandesPage extends StatefulWidget {
  final List<OrderDto> history;
  final VoidCallback? onRefresh;
  const HistoriqueCommandesPage({super.key, required this.history, this.onRefresh});

  @override
  State<HistoriqueCommandesPage> createState() =>
      _HistoriqueCommandesPageState();
}

class _HistoriqueCommandesPageState extends State<HistoriqueCommandesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  static final _statuses = [
    'ALL',
    OrderStatus.pending.value,
    OrderStatus.inTransit.value,
    OrderStatus.delivered.value,
    OrderStatus.rejected.value,
    OrderStatus.cancelled.value,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderDto> get _filtered {
    return widget.history.where((o) {
      final matchStatus =
          _selectedStatus == 'ALL' || o.status == _selectedStatus;
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          o.orderNumber.toLowerCase().contains(q) ||
          o.deliveryAddress.toLowerCase().contains(q) ||
          (o.deliveryDescription?.toLowerCase().contains(q) ?? false);
      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER HISTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.history.length} order${widget.history.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Search bar ──
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by order number or address...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Status filter chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStatus = status),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── List ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty || _selectedStatus != 'ALL'
                                ? 'No orders match your filter'
                                : 'No order history yet',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty || _selectedStatus != 'ALL'
                                ? 'Try a different search or filter.'
                                : 'Completed or failed orders will appear here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              showOrderDetailSheet(context, filtered[index], onRefresh: widget.onRefresh),
                          child: _buildHistoryCard(filtered[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(OrderDto order) {
    final isDelivered = order.status == OrderStatus.delivered.value;
    final isFailed =
        order.status == OrderStatus.rejected.value ||
        order.status == OrderStatus.cancelled.value;

    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isDelivered) {
      iconBg = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline;
    } else if (isFailed) {
      iconBg = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFC62828);
      icon = Icons.cancel_outlined;
    } else {
      iconBg = const Color(0xFFF0F1F5);
      iconColor = Colors.black54;
      icon = Icons.local_shipping_outlined;
    }

    final dateStr = _formatDate(
      order.actualDeliveryTime ?? order.estimatedDeliveryTime,
    );

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
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.deliveryAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDelivered
                  ? const Color(0xFFE8F5E9)
                  : isFailed
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(order.status),
              style: TextStyle(
                color: isDelivered
                    ? const Color(0xFF2E7D32)
                    : isFailed
                    ? const Color(0xFFC62828)
                    : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ALL':
        return 'All';
      case 'PENDING':
        return 'Pending';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'DELIVERED':
        return 'Delivered';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}
