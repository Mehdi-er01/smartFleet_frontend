import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/delivery_program_dto.dart';
import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:smartfleet_frontend/service/dispatch_repository.dart';
import 'package:smartfleet_frontend/service/snackbar_service.dart';

// ═══════════════════════════════════════════════════════════
// DISPATCH PAGE — List / Detail / Create
// ═══════════════════════════════════════════════════════════
enum _View { list, detail, create }

class DispatchCreationPage extends ConsumerStatefulWidget {
  const DispatchCreationPage({super.key});

  @override
  ConsumerState<DispatchCreationPage> createState() =>
      _DispatchCreationPageState();
}

class _DispatchCreationPageState extends ConsumerState<DispatchCreationPage> {
  _View _view = _View.list;
  DeliveryProgramDto? _selectedProgram;
  List<DeliveryProgramDto> _programs = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ref.read(dispatchRepositoryProvider).getPrograms();
    if (mounted) {
      setState(() {
        _programs = list;
        _loading = false;
      });
    }
  }

  List<DeliveryProgramDto> get _filtered {
    var list = _programs;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.programNumber.toLowerCase().contains(q) ||
                p.status.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_statusFilter != null) {
      list = list.where((p) => p.status == _statusFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _View.list:
        return _buildList();
      case _View.detail:
        return _ProgramDetail(
          program: _selectedProgram!,
          onBack: () => setState(() {
            _view = _View.list;
            _selectedProgram = null;
          }),
          onOptimize: () => _optimize(_selectedProgram!),
        );
      case _View.create:
        return _ProgramCreate(
          onBack: () => setState(() => _view = _View.list),
          onCreated: () {
            setState(() => _view = _View.list);
            _load();
          },
        );
    }
  }

  // ─── LIST VIEW ──────────────────────────────────────────
  Widget _buildList() {
    final items = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Dispatch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => setState(() => _view = _View.create),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSearchBar(_searchCtrl, () => setState(() {})),
          ),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    'All',
                    _statusFilter == null,
                    () => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final s in [
                    'PENDING',
                    'OPTIMIZED',
                    'IN_PROGRESS',
                    'COMPLETED',
                  ]) ...[
                    _chip(
                      _formatStatus(s),
                      _statusFilter == s,
                      () => setState(
                        () => _statusFilter = _statusFilter == s ? null : s,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _emptyState('No programmes found')
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildProgramCard(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(DeliveryProgramDto p) {
    final statusColor = _statusColor(p.status);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedProgram = p;
        _view = _View.detail;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    p.programNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(p.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoPill(
                  Icons.assignment_outlined,
                  '${p.orders.length} orders',
                ),
                const SizedBox(width: 12),
                _infoPill(Icons.route, '${p.subPrograms.length} routes'),
                if (p.plannedDate != null) ...[
                  const SizedBox(width: 12),
                  _infoPill(Icons.calendar_today, _formatDate(p.plannedDate!)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _optimize(DeliveryProgramDto p) async {
    await ref.read(dispatchRepositoryProvider).optimizeProgram(p.id);
    SnackbarService.showSuccess('Optimization launched for ${p.programNumber}');
    _load();
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMME DETAIL VIEW
// ═══════════════════════════════════════════════════════════
class _ProgramDetail extends StatelessWidget {
  final DeliveryProgramDto program;
  final VoidCallback onBack;
  final VoidCallback onOptimize;

  const _ProgramDetail({
    required this.program,
    required this.onBack,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(
          program.programNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          if (program.status == 'PENDING')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: onOptimize,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text(
                  'Optimize',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Sub-Programmes (${program.subPrograms.length})',
            ),
            const SizedBox(height: 12),
            if (program.subPrograms.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sub-programmes yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (program.status == 'PENDING')
                      const Text(
                        'Tap Optimize to generate routes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              )
            else
              ...program.subPrograms.map(
                (sp) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSubProgramCard(sp),
                ),
              ),
            const SizedBox(height: 24),
            _buildSectionTitle('Orders (${program.orders.length})'),
            const SizedBox(height: 12),
            ...program.orders.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildOrderRow(o),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final statusColor = _statusColor(program.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatus(program.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem('${program.orders.length}', 'Orders'),
              _statItem('${program.subPrograms.length}', 'Routes'),
              _statItem(
                '${program.subPrograms.fold<double>(0, (sum, sp) => sum + (sp.estimatedDistanceKm ?? 0)).toStringAsFixed(1)} km',
                'Total Dist.',
              ),
            ],
          ),
          if (program.plannedDate != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Planned: ${_formatDate(program.plannedDate!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (program.executionDate != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Executed: ${_formatDate(program.executionDate!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubProgramCard(SubProgramDto sp) {
    final statusColor = _statusColor(sp.status);
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                sp.subProgramNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatus(sp.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                sp.driverName ?? 'Driver #${sp.driverId}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                sp.vehicleRegistration ?? 'Vehicle #${sp.vehicleId}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoPill(
                Icons.shopping_bag_outlined,
                '${sp.totalOrdersCount} orders',
              ),
              const SizedBox(width: 8),
              if (sp.estimatedDistanceKm != null)
                _infoPill(
                  Icons.route,
                  '${sp.estimatedDistanceKm!.toStringAsFixed(1)} km',
                ),
              const SizedBox(width: 8),
              if (sp.estimatedDurationMinutes != null)
                _infoPill(
                  Icons.access_time,
                  '${sp.estimatedDurationMinutes} min',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderDto o) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  o.deliveryAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${o.weightKg.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${o.volumeM2.toStringAsFixed(0)} m²',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            val,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMME CREATE VIEW
// ═══════════════════════════════════════════════════════════
class _ProgramCreate extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCreated;
  const _ProgramCreate({required this.onBack, required this.onCreated});

  @override
  ConsumerState<_ProgramCreate> createState() => _ProgramCreateState();
}

class _ProgramCreateState extends ConsumerState<_ProgramCreate> {
  final _orders = <_OrderDraft>[];
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addOrder() {
    setState(() => _orders.add(_OrderDraft()));
  }

  void _removeOrder(int i) {
    setState(() => _orders.removeAt(i));
  }

  bool get _isValid => _orders.isNotEmpty && _orders.every((o) => o.isValid);

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _submitting = true);
    final repo = ref.read(dispatchRepositoryProvider);
    try {
      final orders = _orders.asMap().entries.map((e) {
        final i = e.key;
        final o = e.value;
        return OrderDto(
          id: 0,
          orderNumber: 'ORD-NEW-${i + 1}',
          weightKg: double.tryParse(o.weightCtrl.text) ?? 0,
          volumeM2: double.tryParse(o.volumeCtrl.text) ?? 0,
          deliveryLatitude: double.tryParse(o.latCtrl.text) ?? 0,
          deliveryLongitude: double.tryParse(o.lonCtrl.text) ?? 0,
          deliveryAddress: o.addressCtrl.text.trim(),
          deliveryDescription: o.descCtrl.text.trim().isEmpty
              ? null
              : o.descCtrl.text.trim(),
          status: 'PENDING',
        );
      }).toList();

      await repo.createProgram(
        orders,
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      SnackbarService.showSuccess(
        'Programme created — optimize it to generate routes',
      );
      widget.onCreated();
    } catch (e) {
      SnackbarService.showError('Failed to create programme: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'New Programme',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Orders section
            Row(
              children: [
                const Text(
                  'Orders',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _addOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Add Order',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No orders added yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Order" to start',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._orders.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildOrderForm(e.key, e.value),
                ),
              ),
            const SizedBox(height: 20),
            // Notes
            const Text(
              'Notes (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDeco('Add notes about this programme...'),
            ),
            const SizedBox(height: 32),
            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!_isValid || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create & Send for Routing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderForm(int index, _OrderDraft draft) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Order #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeOrder(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.addressCtrl,
            decoration: _inputDeco('Delivery address'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Weight (kg)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: draft.volumeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Volume (m²)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.latCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Latitude'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: draft.lonCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Longitude'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.descCtrl,
            decoration: _inputDeco('Description (optional)'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ORDER DRAFT (for the create form)
// ═══════════════════════════════════════════════════════════
class _OrderDraft {
  final addressCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final volumeCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  bool get isValid =>
      addressCtrl.text.trim().isNotEmpty &&
      weightCtrl.text.trim().isNotEmpty &&
      volumeCtrl.text.trim().isNotEmpty &&
      latCtrl.text.trim().isNotEmpty &&
      lonCtrl.text.trim().isNotEmpty;
}

// ═══════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════

Widget _buildSearchBar(TextEditingController ctrl, VoidCallback onChanged) {
  return Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: TextField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Search programmes...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

Widget _chip(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.black : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
    ),
  );
}

Widget _infoPill(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade600),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ],
  );
}

Widget _emptyState(String msg) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      ],
    ),
  );
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black),
    ),
  );
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Colors.orange;
    case 'OPTIMIZED':
      return Colors.blue;
    case 'IN_PROGRESS':
      return const Color(0xFF4CAF50);
    case 'COMPLETED':
      return Colors.green;
    case 'FAILED':
      return Colors.red;
    case 'CANCELLED':
      return Colors.grey;
    case 'ASSIGNED':
      return Colors.blue;
    case 'IN_TRANSIT':
      return Colors.teal;
    case 'DELIVERED':
      return Colors.green;
    case 'REJECTED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _formatStatus(String s) {
  return s.split('_').map((w) => w[0] + w.substring(1).toLowerCase()).join(' ');
}

String _formatDate(String dateStr) {
  try {
    final d = DateTime.parse(dateStr);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return dateStr;
  }
}
