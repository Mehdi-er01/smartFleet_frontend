import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/driver/data/sub_program_dto.dart';
import 'package:smartfleet_frontend/features/driver/domain/sub_program_status.dart';
import 'package:smartfleet_frontend/features/driver/data/driver_repository.dart';

// ─────────────────────────────────────────
// INVENTORY PAGE — List of sub-programs
// ─────────────────────────────────────────
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  bool _isLoading = true;
  String? _error;
  List<SubProgramDto> _subPrograms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(driverRepositoryProvider);
      final list = await repo.getMySubPrograms();
      if (mounted) {
        setState(() {
          _subPrograms = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: Colors.black,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        if (_subPrograms.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmpty(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _SubProgramCard(
                                  sp: _subPrograms[i],
                                  onRefresh: _load,
                                ),
                                childCount: _subPrograms.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    final active = _subPrograms
        .where((s) => s.status == SubProgramStatus.inTransit.value ||
            s.status == 'IN_PROGRESS')
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUTES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'My Sub-Programs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_subPrograms.length} assigned · $active active',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
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
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Failed to load routes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route_outlined,
                  size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'No routes assigned',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Your sub-programs will appear here once a manager assigns them.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SUB-PROGRAM CARD (list item)
// ─────────────────────────────────────────
class _SubProgramCard extends StatelessWidget {
  final SubProgramDto sp;
  final VoidCallback onRefresh;

  const _SubProgramCard({required this.sp, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusStyle(sp.status);
    final progress = sp.totalOrdersCount > 0
        ? sp.approvedOrdersCount / sp.totalOrdersCount
        : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SubProgramDetailPage(sp: sp, onRefresh: onRefresh),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route_outlined,
                      size: 20, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sp.subProgramNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sp.totalOrdersCount} orders',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.$2.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo.$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusInfo.$2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Progress bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 5,
                backgroundColor: Colors.grey.shade100,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
            const SizedBox(height: 8),

            // ── Stats row ──
            Row(
              children: [
                if (sp.estimatedDistanceKm != null)
                  _chip(Icons.straighten_outlined,
                      '${sp.estimatedDistanceKm!.toStringAsFixed(1)} km'),
                if (sp.estimatedDurationMinutes != null) ...[
                  const SizedBox(width: 8),
                  _chip(Icons.timer_outlined,
                      '${sp.estimatedDurationMinutes} min'),
                ],
                const Spacer(),
                Text(
                  '${sp.approvedOrdersCount}/${sp.totalOrdersCount} done',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'IN_PROGRESS':
      case 'IN_TRANSIT':
        return ('IN PROGRESS', Colors.orange);
      case 'COMPLETED':
        return ('COMPLETED', const Color(0xFF2E7D32));
      case 'PENDING':
        return ('PENDING', Colors.grey);
      case 'ASSIGNED':
        return ('ASSIGNED', Colors.blue);
      case 'FAILED':
        return ('FAILED', Colors.red);
      case 'CANCELLED':
        return ('CANCELLED', Colors.red);
      default:
        return (status, Colors.grey);
    }
  }
}

// ─────────────────────────────────────────
// SUB-PROGRAM DETAIL PAGE
// ─────────────────────────────────────────
class SubProgramDetailPage extends ConsumerStatefulWidget {
  final SubProgramDto sp;
  final VoidCallback onRefresh;

  const SubProgramDetailPage(
      {super.key, required this.sp, required this.onRefresh});

  @override
  ConsumerState<SubProgramDetailPage> createState() =>
      _SubProgramDetailPageState();
}

class _SubProgramDetailPageState extends ConsumerState<SubProgramDetailPage> {
  bool _isStarting = false;
  bool _isCalculating = false;
  late SubProgramDto _sp;

  @override
  void initState() {
    super.initState();
    _sp = widget.sp;
  }

  bool get _canCalculate =>
      _sp.status == SubProgramStatus.assigned.value ||
      _sp.status == SubProgramStatus.pending.value;

  Future<void> _calculateRoute() async {
    setState(() => _isCalculating = true);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final updated = await repo.calculateRoute(_sp.id);
      if (mounted) {
        setState(() {
          _sp = updated;
          _isCalculating = false;
        });
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route calculated successfully!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
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

  Future<void> _startRoute() async {
    setState(() => _isStarting = true);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final updated = await repo.startSubProgram(_sp.id);
      if (mounted) {
        setState(() {
          _sp = updated;
          _isStarting = false;
        });
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route started successfully!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
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
    final statusInfo = _statusStyle(_sp.status);
    final progress = _sp.totalOrdersCount > 0
        ? _sp.approvedOrdersCount / _sp.totalOrdersCount
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: Colors.black),
          ),
        ),
        title: const Text(
          'Sub-Program Details',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Black hero card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUB-PROGRAM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sp.subProgramNumber,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                  const SizedBox(height: 22),
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery progress',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      Text(
                        '${_sp.approvedOrdersCount}/${_sp.totalOrdersCount}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stat chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _heroChip(
                          Icons.receipt_outlined, '${_sp.totalOrdersCount}', 'Orders'),
                      if (_sp.estimatedDistanceKm != null)
                        _heroChip(
                            Icons.straighten_outlined,
                            '${_sp.estimatedDistanceKm!.toStringAsFixed(1)} km',
                            'Distance'),
                      if (_sp.estimatedDurationMinutes != null)
                        _heroChip(
                            Icons.timer_outlined,
                            '${_sp.estimatedDurationMinutes} min',
                            'Duration'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Info section ──
            _sectionTitle('Route Information'),
            const SizedBox(height: 12),
            _infoCard([
              _infoRow(Icons.tag_outlined, 'Program ID',
                  '#${_sp.deliveryProgramId}'),
              _infoRow(Icons.inventory_2_outlined, 'Total Orders',
                  '${_sp.totalOrdersCount}'),
              _infoRow(Icons.check_circle_outline, 'Delivered',
                  '${_sp.approvedOrdersCount}'),
              _infoRow(Icons.pending_outlined, 'Remaining',
                  '${_sp.totalOrdersCount - _sp.approvedOrdersCount}'),
            ]),

            if (_sp.startTime != null || _sp.endTime != null) ...[
              const SizedBox(height: 20),
              _sectionTitle('Timeline'),
              const SizedBox(height: 12),
              _infoCard([
                if (_sp.startTime != null)
                  _infoRow(Icons.play_circle_outline, 'Started',
                      _sp.startTime!),
                if (_sp.endTime != null)
                  _infoRow(Icons.stop_circle_outlined, 'Ended', _sp.endTime!),
              ]),
            ],

            const SizedBox(height: 32),

            // ── Action buttons ──
            if (_canCalculate) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isCalculating ? null : _calculateRoute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isCalculating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        )
                      : const Icon(Icons.route_outlined, size: 20),
                  label: Text(
                    _isCalculating ? 'Calculating...' : 'Calculate Route',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isStarting ? 'Starting...' : 'Start Route',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Back to list button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.list_alt_outlined, size: 20),
                label: const Text(
                  'Back to List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.black87),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'IN_PROGRESS':
      case 'IN_TRANSIT':
        return ('IN PROGRESS', Colors.orange);
      case 'COMPLETED':
        return ('COMPLETED', const Color(0xFF2E7D32));
      case 'PENDING':
        return ('PENDING', Colors.grey);
      case 'ASSIGNED':
        return ('ASSIGNED', Colors.blue);
      case 'FAILED':
        return ('FAILED', Colors.red);
      case 'CANCELLED':
        return ('CANCELLED', Colors.red);
      default:
        return (status, Colors.grey);
    }
  }
}
