import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/delivery_program_dto.dart';
import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';
import 'package:smartfleet_frontend/service/dispatch_repository.dart';
import 'package:smartfleet_frontend/service/geocoding_service.dart';
import 'package:smartfleet_frontend/service/snackbar_service.dart';
import 'package:smartfleet_frontend/service/fleet_repository.dart';

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
    try {
      final dispatch = ref.read(dispatchRepositoryProvider);
      final fleet = ref.read(fleetRepositoryProvider);

      // Fetch programs, drivers and vehicles in parallel and enrich sub-programs
      final results = await Future.wait([
        dispatch.getPrograms(),
        fleet.getMyDrivers(),
        fleet.getVehicles(),
      ]);

      final programs = results[0] as List<DeliveryProgramDto>;
      final drivers = results[1] as List;
      final vehicles = results[2] as List;

      final driversById = <int, dynamic>{};
      for (final d in drivers) {
        try {
          driversById[(d.id as int)] = d;
        } catch (_) {}
      }
      final vehiclesById = <int, dynamic>{};
      for (final v in vehicles) {
        try {
          vehiclesById[(v.id as int)] = v;
        } catch (_) {}
      }

      final enriched = programs.map((p) {
        final enrichedSubs = p.subPrograms.map((sp) {
          final driverName = sp.driverId != null && driversById.containsKey(sp.driverId)
              ? driversById[sp.driverId].name
              : null;
          final vehicleReg = sp.vehicleId != null && vehiclesById.containsKey(sp.vehicleId)
              ? vehiclesById[sp.vehicleId].registrationNumber
              : null;
          return SubProgramDto(
            id: sp.id,
            subProgramNumber: sp.subProgramNumber,
            deliveryProgramId: sp.deliveryProgramId,
            driverId: sp.driverId,
            vehicleId: sp.vehicleId,
            orderIds: sp.orderIds,
            status: sp.status,
            polyline: sp.polyline,
            estimatedDistanceKm: sp.estimatedDistanceKm,
            estimatedDurationMinutes: sp.estimatedDurationMinutes,
            actualDistanceKm: sp.actualDistanceKm,
            actualDurationMinutes: sp.actualDurationMinutes,
            startTime: sp.startTime,
            endTime: sp.endTime,
            totalOrdersCount: sp.totalOrdersCount,
            approvedOrdersCount: sp.approvedOrdersCount,
            driverName: driverName,
            vehicleRegistration: vehicleReg,
          );
        }).toList();

        return DeliveryProgramDto(
          id: p.id,
          programNumber: p.programNumber,
          managerId: p.managerId,
          status: p.status,
          orders: p.orders,
          subPrograms: enrichedSubs,
          plannedDate: p.plannedDate,
          executionDate: p.executionDate,
          completionDate: p.completionDate,
          notes: p.notes,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _programs = enriched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        SnackbarService.showError('Failed to load programs: $e');
      }
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
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSearchBar(_searchCtrl, () => setState(() {})),
          ),
          // Create button + Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Create Programme button
                  GestureDetector(
                    onTap: () => setState(() => _view = _View.create),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'New Programme',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
    try {
      await ref.read(dispatchRepositoryProvider).optimizeProgram(p.id);
      SnackbarService.showSuccess(
        'Optimization launched for ${p.programNumber}',
      );
      _load();
    } catch (e) {
      SnackbarService.showError('Optimization failed: $e');
    }
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
// PROGRAMME CREATE VIEW — 3-STEP WIZARD
// ═══════════════════════════════════════════════════════════
class _ProgramCreate extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCreated;
  const _ProgramCreate({required this.onBack, required this.onCreated});

  @override
  ConsumerState<_ProgramCreate> createState() => _ProgramCreateState();
}

class _ProgramCreateState extends ConsumerState<_ProgramCreate> {
  int _step = 0; // 0=Orders, 1=Review, 2=Confirm
  final _orders = <_OrderDraft>[];
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addOrder() => setState(() => _orders.add(_OrderDraft()));
  void _removeOrder(int i) => setState(() => _orders.removeAt(i));
  bool get _isValid => _orders.isNotEmpty && _orders.every((o) => o.isValid);

  // ── Geocode a single order's address → lat/lon ──
  Future<void> _geocodeOrder(_OrderDraft draft) async {
    final addr = draft.addressCtrl.text.trim();
    if (addr.isEmpty) {
      SnackbarService.showError('Enter an address first');
      return;
    }
    setState(() => draft.geocoding = true);
    final result = await GeocodingService.geocode(addr);
    if (!mounted) return;
    setState(() {
      draft.geocoding = false;
      if (result != null) {
        draft.latCtrl.text = result.lat.toStringAsFixed(6);
        draft.lonCtrl.text = result.lon.toStringAsFixed(6);
        draft.geocoded = true;
      } else {
        SnackbarService.showError('Could not geocode: $addr');
      }
    });
  }

  // ── Geocode all orders that don't have coords yet ──
  Future<void> _geocodeAll() async {
    final needsGeocode = _orders
        .where(
          (o) =>
              o.addressCtrl.text.trim().isNotEmpty &&
              o.latCtrl.text.trim().isEmpty,
        )
        .toList();
    if (needsGeocode.isEmpty) {
      SnackbarService.showError('All orders already have coordinates');
      return;
    }
    for (final draft in needsGeocode) {
      await _geocodeOrder(draft);
    }
  }

  // ── Bulk add N empty orders ──
  void _bulkAdd() {
    showDialog<int>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: '5');
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Multiple Orders',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How many empty order forms do you want to add?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: _inputDeco('Number of orders'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text) ?? 0;
                Navigator.pop(ctx, n);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((n) {
      if (n != null && n > 0) {
        setState(() {
          for (var i = 0; i < n; i++) {
            _orders.add(_OrderDraft());
          }
        });
        SnackbarService.showSuccess('Added $n empty orders');
      }
    });
  }

  // ── Import orders from CSV or XLSX file ──
  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) {
      SnackbarService.showError('Could not access file');
      return;
    }

    try {
      final ext = path.split('.').last.toLowerCase();
      final List<_OrderDraft> imported = [];

      if (ext == 'csv') {
        final content = await File(path).readAsString();
        final rows = const CsvToListConverter(eol: '\n').convert(content);
        if (rows.isEmpty) {
          SnackbarService.showError('CSV file is empty');
          return;
        }
        // Try to detect header row
        final firstRow = rows.first;
        final hasHeader = firstRow.any(
          (c) =>
              c.toString().toLowerCase().contains('address') ||
              c.toString().toLowerCase().contains('weight'),
        );
        final dataRows = hasHeader ? rows.skip(1).toList() : rows;

        for (final row in dataRows) {
          if (row.isEmpty) continue;
          final draft = _OrderDraft();
          // Expected columns: address, weight, volume, [lat, lon], [description]
          if (row.length >= 1)
            draft.addressCtrl.text = row[0].toString().trim();
          if (row.length >= 2) draft.weightCtrl.text = row[1].toString().trim();
          if (row.length >= 3) draft.volumeCtrl.text = row[2].toString().trim();
          if (row.length >= 4 && row[3].toString().trim().isNotEmpty) {
            draft.latCtrl.text = row[3].toString().trim();
            draft.lonCtrl.text = row.length >= 5
                ? row[4].toString().trim()
                : '';
            draft.geocoded = true;
          }
          if (row.length >= 6) draft.descCtrl.text = row[5].toString().trim();
          if (draft.addressCtrl.text.isNotEmpty) imported.add(draft);
        }
      } else if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await File(path).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]!;
        final maxRow = sheet.maxRows;
        if (maxRow < 1) {
          SnackbarService.showError('Excel file is empty');
          return;
        }
        // Skip header if it looks like one
        int startRow = 0;
        final firstRow = sheet.rows.isNotEmpty ? sheet.rows.first : [];
        if (firstRow.any((c) {
          final v = c?.value?.toString().toLowerCase() ?? '';
          return v.contains('address') || v.contains('weight');
        })) {
          startRow = 1;
        }
        for (var r = startRow; r < maxRow; r++) {
          final row = sheet.rows[r];
          if (row.isEmpty) continue;
          String cell(int col) {
            if (col >= row.length) return '';
            return row[col]?.value?.toString().trim() ?? '';
          }

          final draft = _OrderDraft();
          draft.addressCtrl.text = cell(0);
          draft.weightCtrl.text = cell(1);
          draft.volumeCtrl.text = cell(2);
          final lat = cell(3);
          final lon = cell(4);
          if (lat.isNotEmpty) {
            draft.latCtrl.text = lat;
            draft.lonCtrl.text = lon;
            draft.geocoded = true;
          }
          draft.descCtrl.text = cell(5);
          if (draft.addressCtrl.text.isNotEmpty) imported.add(draft);
        }
      }

      if (imported.isEmpty) {
        SnackbarService.showError('No valid orders found in file');
        return;
      }

      // Geocode orders that don't have coordinates
      int needGeocode = imported
          .where((o) => o.latCtrl.text.trim().isEmpty)
          .length;
      setState(() => _orders.addAll(imported));
      SnackbarService.showSuccess(
        'Imported ${imported.length} orders'
        '${needGeocode > 0 ? ' ($needGeocode need geocoding)' : ''}',
      );
    } catch (e) {
      SnackbarService.showError('Failed to parse file: $e');
    }
  }

  void _next() {
    if (_step == 0 && !_isValid) {
      SnackbarService.showError('Add at least one valid order');
      return;
    }
    setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

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

      await repo.createProgramWithOrders(
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
          onPressed: _step > 0 ? _prev : widget.onBack,
        ),
        title: const Text(
          'New Programme',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _step == 0
                  ? _buildStepOrders()
                  : _step == 1
                  ? _buildStepReview()
                  : _buildStepConfirm(),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEPPER BAR ──
  Widget _buildStepper() {
    final labels = ['Orders', 'Review', 'Confirm'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.black
                              : done
                              ? Colors.green
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < labels.length - 1)
                  Container(
                    height: 2,
                    width: 32,
                    color: done ? Colors.green : Colors.grey.shade200,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── STEP 1: ORDERS ──
  Widget _buildStepOrders() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Action buttons row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _toolBtn(Icons.add, 'Add Order', _addOrder),
                const SizedBox(width: 8),
                _toolBtn(Icons.format_list_numbered, 'Bulk Add', _bulkAdd),
                const SizedBox(width: 8),
                _toolBtn(Icons.upload_file, 'Import CSV/XLSX', _importFromFile),
                if (_orders.any(
                  (o) =>
                      o.latCtrl.text.trim().isEmpty &&
                      o.addressCtrl.text.trim().isNotEmpty,
                )) ...[
                  const SizedBox(width: 8),
                  _toolBtn(
                    Icons.my_location,
                    'Geocode All',
                    _geocodeAll,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_orders.isNotEmpty)
            Text(
              '${_orders.length} order${_orders.length > 1 ? 's' : ''}  •  '
              '${_orders.where((o) => o.geocoded || o.latCtrl.text.trim().isNotEmpty).length} with coordinates',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 12),
          if (_orders.isEmpty)
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
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No orders added yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add orders manually, bulk add multiple,\nor import from a CSV/XLSX file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expected CSV columns:\naddress, weight, volume, [lat, lon], [description]',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'monospace',
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Review',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── STEP 2: REVIEW ──
  Widget _buildStepReview() {
    final totalWeight = _orders.fold<double>(
      0,
      (s, o) => s + (double.tryParse(o.weightCtrl.text) ?? 0),
    );
    final totalVolume = _orders.fold<double>(
      0,
      (s, o) => s + (double.tryParse(o.volumeCtrl.text) ?? 0),
    );

    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Orders',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _reviewStat('${_orders.length}', 'Orders'),
                _reviewStat('${totalWeight.toStringAsFixed(0)} kg', 'Weight'),
                _reviewStat('${totalVolume.toStringAsFixed(0)} m²', 'Volume'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Order list
          ..._orders.asMap().entries.map((e) {
            final i = e.key;
            final o = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.addressCtrl.text.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${o.weightCtrl.text} kg  •  ${o.volumeCtrl.text} m²',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _prev,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Confirm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _reviewStat(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 3: CONFIRM ──
  Widget _buildStepConfirm() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm & Submit',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, size: 28, color: Colors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ready to create programme?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_orders.length} order${_orders.length > 1 ? 's' : ''} will be created and linked to a new delivery programme.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (_notesCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _notesCtrl.text.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _prev,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Create Programme',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOrderForm(int index, _OrderDraft draft) {
    final hasCoords = draft.latCtrl.text.trim().isNotEmpty;
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
          // Header
          Row(
            children: [
              Text(
                'Order #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              if (hasCoords)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GEOCODED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeOrder(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address + Geocode button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.addressCtrl,
                  decoration: _inputDeco('Delivery address'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: draft.geocoding ? null : () => _geocodeOrder(draft),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: hasCoords ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: draft.geocoding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          hasCoords ? Icons.check : Icons.my_location,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
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
          TextField(
            controller: draft.descCtrl,
            decoration: _inputDeco('Description (optional)'),
          ),
          // Show coords read-only if geocoded
          if (hasCoords) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${draft.latCtrl.text}, ${draft.lonCtrl.text}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? Colors.black).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.black87),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
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
  bool geocoding = false; // true while geocoding in progress
  bool geocoded = false; // true once lat/lon have been fetched

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
