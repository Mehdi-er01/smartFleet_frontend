import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/order/domain/order_status.dart';
import 'package:smartfleet_frontend/features/order/data/order_repository.dart';

/// Shows a premium, scrollable bottom-sheet with full order details.
void showOrderDetailSheet(
  BuildContext context,
  OrderDto order, {
  VoidCallback? onRefresh,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderDetailSheet(order: order, onRefresh: onRefresh),
  );
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  final OrderDto order;
  final VoidCallback? onRefresh;
  const _OrderDetailSheet({required this.order, this.onRefresh});

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  late OrderDto _order;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _approveOrder() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final updated = await repo.approveOrder(_order.id);
      if (mounted) {
        setState(() {
          _order = updated;
          _isProcessing = false;
        });
        widget.onRefresh?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order approved successfully!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final updated = await repo.rejectOrder(_order.id);
      if (mounted) {
        setState(() {
          _order = updated;
          _isProcessing = false;
        });
        widget.onRefresh?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _order.status == OrderStatus.delivered.value;
    final isFailed =
        _order.status == OrderStatus.rejected.value ||
        _order.status == OrderStatus.cancelled.value;
    final isInProgress = _order.status == OrderStatus.inTransit.value;

    Color statusColor;
    IconData statusIcon;
    Color statusBg;
    if (isDelivered) {
      statusColor = Colors.green.shade700;
      statusBg = Colors.green.shade50;
      statusIcon = Icons.check_circle_rounded;
    } else if (isFailed) {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
      statusIcon = Icons.cancel_rounded;
    } else if (isInProgress) {
      statusColor = Colors.blue.shade700;
      statusBg = Colors.blue.shade50;
      statusIcon = Icons.local_shipping_rounded;
    } else {
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
      statusIcon = Icons.schedule_rounded;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  children: [
                    // Header: Order number + status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _order.orderNumber,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _order.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _sectionTitle('Delivery Information'),
                    const SizedBox(height: 14),

                    _infoRow(
                      Icons.location_on_rounded,
                      'Delivery Address',
                      _order.deliveryAddress,
                    ),
                    if (_order.deliveryDescription != null &&
                        _order.deliveryDescription!.isNotEmpty)
                      _infoRow(
                        Icons.notes_rounded,
                        'Description',
                        _order.deliveryDescription!,
                      ),

                    const SizedBox(height: 24),
                    _sectionTitle('Package Details'),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            Icons.scale_rounded,
                            '${_order.weightKg} kg',
                            'Weight',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            Icons.view_in_ar_rounded,
                            '${_order.volumeM2} m³',
                            'Volume',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Timeline'),
                    const SizedBox(height: 14),

                    if (_order.estimatedDeliveryTime != null)
                      _timelineRow(
                        Icons.access_time_rounded,
                        'Estimated Delivery',
                        _formatDate(_order.estimatedDeliveryTime!),
                        isFirst: true,
                      ),
                    if (_order.actualDeliveryTime != null)
                      _timelineRow(
                        Icons.done_all_rounded,
                        'Actual Delivery',
                        _formatDate(_order.actualDeliveryTime!),
                        isLast: true,
                        color: Colors.green.shade600,
                      ),

                    const SizedBox(height: 24),
                    _sectionTitle('Location Coordinates'),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_order.deliveryLatitude.toStringAsFixed(4)}, ${_order.deliveryLongitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Client Approval Actions
                    if (!_order.clientApproved && _order.status != OrderStatus.rejected.value && _order.status != OrderStatus.cancelled.value) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Awaiting your approval',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isProcessing ? null : _rejectOrder,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _approveOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_order.clientApproved) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Approved by you',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.black45,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.black54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(
    IconData icon,
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    Color color = Colors.black54,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: isFirst ? 0 : 12,
              color: Colors.grey.shade300,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            Container(
              width: 2,
              height: isLast ? 0 : 12,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
