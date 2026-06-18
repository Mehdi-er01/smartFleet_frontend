import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/client/data/client_dto.dart';
import 'package:smartfleet_frontend/features/client/data/client_repo.dart';
import 'package:smartfleet_frontend/features/dispatch/data/delivery_program_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/domain/delivery_program_status.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/order/domain/order_status.dart';
import 'package:smartfleet_frontend/features/order/data/order_repository.dart';
import 'package:smartfleet_frontend/features/driver/data/sub_program_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/data/dispatch_repository.dart';
import 'package:smartfleet_frontend/features/dispatch/data/optimization_repo.dart';
import 'package:smartfleet_frontend/features/dispatch/data/optimizedProgramStatsDto.dart';
import 'package:smartfleet_frontend/core/geocoding_service.dart';
import 'package:smartfleet_frontend/core/snackbar_service.dart';

// ═══════════════════════════════════════════════════════════
// DISPATCH PAGE — Tabbed: Programs + Orders
// ═══════════════════════════════════════════════════════════
class DispatchCreationPage extends StatelessWidget {
  const DispatchCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                text: 'Programs',
                icon: Icon(Icons.assignment_outlined, size: 18),
              ),
              Tab(
                text: 'Orders',
                icon: Icon(Icons.shopping_bag_outlined, size: 18),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_ProgramsTab(), _OrdersTab()]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMS TAB — List / Detail / Create wizard
// ═══════════════════════════════════════════════════════════
enum _ProgView { list, detail, create }

class _ProgramsTab extends ConsumerStatefulWidget {
  const _ProgramsTab();

  @override
  ConsumerState<_ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends ConsumerState<_ProgramsTab> {
  _ProgView _view = _ProgView.list;
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
      final list = await ref.read(dispatchRepositoryProvider).getPrograms();
      if (mounted)
        setState(() {
          _programs = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      SnackbarService.showError('Failed to load programs: $e');
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
      case _ProgView.list:
        return _buildList();
      case _ProgView.detail:
        return _ProgramDetail(
          program: _selectedProgram!,
          onBack: () => setState(() {
            _view = _ProgView.list;
            _selectedProgram = null;
          }),
          onOptimize: () => _optimize(_selectedProgram!),
          onDelete: () => _deleteProgram(_selectedProgram!),
          onRemoveOrder: (orderId) => _removeOrder(_selectedProgram!, orderId),
          onAddOrders: () => _addOrdersToProgram(_selectedProgram!),
          onEdit: () => _editProgram(_selectedProgram!),
        );
      case _ProgView.create:
        return _ProgramCreate(
          onBack: () => setState(() => _view = _ProgView.list),
          onCreated: () {
            setState(() => _view = _ProgView.list);
            _load();
          },
        );
    }
  }

  Widget _buildList() {
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildSearchBar(_searchCtrl, () => setState(() {})),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _view = _ProgView.create),
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
                  DeliveryProgramStatus.pending.value,
                  DeliveryProgramStatus.optimized.value,
                  DeliveryProgramStatus.inProgress.value,
                  DeliveryProgramStatus.completed.value,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildProgramCard(items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProgramCard(DeliveryProgramDto p) {
    final statusColor = _statusColor(p.status);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedProgram = p;
        _view = _ProgView.detail;
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
                    color: statusColor.withValues(alpha: 0.12),
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
      // Reload program detail to get sub-programs
      final updated = await ref
          .read(dispatchRepositoryProvider)
          .getProgram(p.id);
      if (mounted) {
        setState(() {
          _selectedProgram = updated;
          // Update in list too
          final idx = _programs.indexWhere((pr) => pr.id == updated.id);
          if (idx >= 0) _programs[idx] = updated;
        });
      }
    } catch (e) {
      final msg = e.toString();
      SnackbarService.showError(
        'Optimization failed: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}',
      );
    }
  }

  Future<void> _deleteProgram(DeliveryProgramDto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Programme'),
        content: Text('Delete ${p.programNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(dispatchRepositoryProvider).deleteProgram(p.id);
      SnackbarService.showSuccess('${p.programNumber} deleted');
      setState(() {
        _view = _ProgView.list;
        _selectedProgram = null;
      });
      _load();
    } catch (e) {
      SnackbarService.showError('Failed to delete: $e');
    }
  }

  Future<void> _removeOrder(DeliveryProgramDto p, int orderId) async {
    try {
      await ref.read(dispatchRepositoryProvider).deleteOrder(p.id, orderId);
      SnackbarService.showSuccess('Order removed');
      final updated = await ref
          .read(dispatchRepositoryProvider)
          .getProgram(p.id);
      if (mounted) {
        setState(() {
          _selectedProgram = updated;
          final idx = _programs.indexWhere((pr) => pr.id == updated.id);
          if (idx >= 0) _programs[idx] = updated;
        });
      }
    } catch (e) {
      SnackbarService.showError('Failed to remove order: $e');
    }
  }

  Future<void> _addOrdersToProgram(DeliveryProgramDto p) async {
    try {
      // Load all orders not already in the program
      final allOrders = await ref.read(orderRepositoryProvider).getOrders();
      final existingIds = p.orders.map((o) => o.id).toSet();
      final available = allOrders
          .where((o) => !existingIds.contains(o.id))
          .toList();
      if (!mounted) return;
      if (available.isEmpty) {
        SnackbarService.showError('No available orders to add');
        return;
      }
      final selected = await showDialog<List<int>>(
        context: context,
        builder: (ctx) => _OrderPickerDialog(orders: available),
      );
      if (selected == null || selected.isEmpty) return;
      final updated = await ref
          .read(dispatchRepositoryProvider)
          .addOrders(p.id, selected);
      if (mounted) {
        setState(() {
          _selectedProgram = updated;
          final idx = _programs.indexWhere((pr) => pr.id == updated.id);
          if (idx >= 0) _programs[idx] = updated;
        });
        SnackbarService.showSuccess('${selected.length} order(s) added');
      }
    } catch (e) {
      SnackbarService.showError('Failed to add orders: $e');
    }
  }

  Future<void> _editProgram(DeliveryProgramDto p) async {
    final notesCtrl = TextEditingController(text: p.notes ?? '');
    DateTime? planned = p.plannedDate != null
        ? DateTime.tryParse(p.plannedDate!)
        : null;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Programme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: planned ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => planned = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Planned Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    planned != null
                        ? '${planned!.day}/${planned!.month}/${planned!.year}'
                        : 'Not set',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    try {
      final updated = await ref
          .read(dispatchRepositoryProvider)
          .updateProgram(
            p.id,
            DeliveryProgramDto(
              id: p.id,
              programNumber: p.programNumber,
              managerId: p.managerId,
              status: p.status,
              orders: p.orders,
              subPrograms: p.subPrograms,
              notes: notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              plannedDate: planned?.toIso8601String(),
            ),
          );
      if (mounted) {
        setState(() {
          _selectedProgram = updated;
          final idx = _programs.indexWhere((pr) => pr.id == updated.id);
          if (idx >= 0) _programs[idx] = updated;
        });
        SnackbarService.showSuccess('Programme updated');
      }
    } catch (e) {
      SnackbarService.showError('Failed to update: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════
// ORDERS TAB — Standalone order management
// ═══════════════════════════════════════════════════════════
class _OrdersTab extends ConsumerStatefulWidget {
  const _OrdersTab();

  @override
  ConsumerState<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<_OrdersTab> {
  List<OrderDto> _orders = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  bool _showForm = false;
  OrderDto? _selectedOrder;

  // Filter & sort
  String? _statusFilter;
  bool _sortAsc = true;

  // Order form fields
  final _addressCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();
  bool _geocoding = false;
  bool _submitting = false;
  ClientDto? _selectedClient;
  List<ClientDto> _clientResults = [];
  List<ClientDto> _allClientsCache = [];
  bool _searchingClients = false;
  bool _clientsLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _clientSearchCtrl.addListener(_onClientSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _addressCtrl.dispose();
    _weightCtrl.dispose();
    _volumeCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(orderRepositoryProvider).getOrders();
      if (mounted)
        setState(() {
          _orders = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      SnackbarService.showError('Failed to load orders: $e');
    }
  }

  List<OrderDto> get _filtered {
    var list = _orders.toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.orderNumber.toLowerCase().contains(q) ||
                o.deliveryAddress.toLowerCase().contains(q) ||
                o.status.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_statusFilter != null) {
      list = list.where((o) => o.status == _statusFilter).toList();
    }
    list.sort(
      (a, b) => _sortAsc
          ? a.orderNumber.compareTo(b.orderNumber)
          : b.orderNumber.compareTo(a.orderNumber),
    );
    return list;
  }

  Future<void> _onClientSearch() async {
    final q = _clientSearchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _clientResults = []);
      return;
    }
    // Load all clients once and cache
    if (!_clientsLoaded) {
      setState(() => _searchingClients = true);
      try {
        _allClientsCache = await ref.read(clientRepoProvider).getClients();
        _clientsLoaded = true;
      } catch (e) {
        if (mounted) {
          setState(() => _searchingClients = false);
          SnackbarService.showError('Failed to load clients');
        }
        return;
      }
    }
    // Filter locally
    final query = q.toLowerCase();
    final results = _allClientsCache
        .where(
          (c) =>
              (c.name?.toLowerCase().contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query) ?? false) ||
              (c.companyName?.toLowerCase().contains(query) ?? false),
        )
        .take(5)
        .toList();
    if (mounted)
      setState(() {
        _clientResults = results;
        _searchingClients = false;
      });
  }

  Future<void> _geocode() async {
    final addr = _addressCtrl.text.trim();
    if (addr.isEmpty) {
      SnackbarService.showError('Enter an address first');
      return;
    }
    setState(() => _geocoding = true);
    try {
      final result = await GeocodingService.geocode(addr);
      if (!mounted) return;
      setState(() {
        _geocoding = false;
        if (result != null) {
          _latCtrl.text = result.lat.toStringAsFixed(6);
          _lonCtrl.text = result.lon.toStringAsFixed(6);
        } else {
          SnackbarService.showError('Could not geocode: $addr');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _geocoding = false);
        SnackbarService.showError('Geocoding failed: $e');
      }
    }
  }

  void _resetForm() {
    _addressCtrl.clear();
    _weightCtrl.clear();
    _volumeCtrl.clear();
    _descCtrl.clear();
    _latCtrl.clear();
    _lonCtrl.clear();
    _clientSearchCtrl.clear();
    setState(() {
      _selectedClient = null;
      _clientResults = [];
      _showForm = false;
    });
  }

  void _selectClient(ClientDto c) {
    setState(() {
      _selectedClient = c;
      _clientSearchCtrl.clear();
      _clientResults = [];
    });
  }

  Future<void> _createOrder() async {
    if (_addressCtrl.text.trim().isEmpty ||
        _weightCtrl.text.trim().isEmpty ||
        _volumeCtrl.text.trim().isEmpty) {
      SnackbarService.showError('Address, weight and volume are required');
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = OrderDto(
        id: 0,
        orderNumber: '',
        clientId: _selectedClient?.id,
        weightKg: double.tryParse(_weightCtrl.text) ?? 0,
        volumeM2: double.tryParse(_volumeCtrl.text) ?? 0,
        deliveryLatitude: double.tryParse(_latCtrl.text) ?? 0,
        deliveryLongitude: double.tryParse(_lonCtrl.text) ?? 0,
        deliveryAddress: _addressCtrl.text.trim(),
        deliveryDescription: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        status: OrderStatus.pending.value,
      );
      await ref.read(orderRepositoryProvider).createOrder(order);
      if (!mounted) return;
      SnackbarService.showSuccess('Order created successfully');
      _resetForm();
      _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().length > 120
          ? '${e.toString().substring(0, 120)}...'
          : e.toString();
      SnackbarService.showError('Failed to create order: $msg');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
      final List<OrderDto> toCreate = [];

      if (ext == 'csv') {
        final content = await File(path).readAsString();
        final rows = const CsvToListConverter(eol: '\n').convert(content);
        if (rows.isEmpty) {
          SnackbarService.showError('CSV file is empty');
          return;
        }
        final hasHeader = rows.first.any(
          (c) =>
              c.toString().toLowerCase().contains('address') ||
              c.toString().toLowerCase().contains('weight'),
        );
        final dataRows = hasHeader ? rows.skip(1).toList() : rows;
        for (final row in dataRows) {
          if (row.isEmpty) continue;
          toCreate.add(
            OrderDto(
              id: 0,
              orderNumber: '',
              weightKg:
                  double.tryParse(
                    row.length >= 2 ? row[1].toString().trim() : '0',
                  ) ??
                  0,
              volumeM2:
                  double.tryParse(
                    row.length >= 3 ? row[2].toString().trim() : '0',
                  ) ??
                  0,
              deliveryLatitude:
                  double.tryParse(
                    row.length >= 4 ? row[3].toString().trim() : '0',
                  ) ??
                  0,
              deliveryLongitude:
                  double.tryParse(
                    row.length >= 5 ? row[4].toString().trim() : '0',
                  ) ??
                  0,
              deliveryAddress: row[0].toString().trim(),
              deliveryDescription: row.length >= 6
                  ? row[5].toString().trim()
                  : null,
              status: OrderStatus.pending.value,
            ),
          );
        }
      } else {
        final bytes = await File(path).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]!;
        int startRow = 0;
        if (sheet.rows.isNotEmpty &&
            sheet.rows.first.any((c) {
              final v = c?.value?.toString().toLowerCase() ?? '';
              return v.contains('address') || v.contains('weight');
            }))
          startRow = 1;
        for (var r = startRow; r < sheet.maxRows; r++) {
          final row = sheet.rows[r];
          if (row.isEmpty) continue;
          String cell(int col) =>
              col >= row.length ? '' : row[col]?.value?.toString().trim() ?? '';
          toCreate.add(
            OrderDto(
              id: 0,
              orderNumber: '',
              weightKg: double.tryParse(cell(1)) ?? 0,
              volumeM2: double.tryParse(cell(2)) ?? 0,
              deliveryLatitude: double.tryParse(cell(3)) ?? 0,
              deliveryLongitude: double.tryParse(cell(4)) ?? 0,
              deliveryAddress: cell(0),
              deliveryDescription: cell(5).isEmpty ? null : cell(5),
              status: OrderStatus.pending.value,
            ),
          );
        }
      }

      if (toCreate.isEmpty) {
        SnackbarService.showError('No valid orders found in file');
        return;
      }
      int created = 0;
      for (final o in toCreate) {
        try {
          await ref.read(orderRepositoryProvider).createOrder(o);
          created++;
        } catch (_) {}
      }
      SnackbarService.showSuccess(
        'Imported $created / ${toCreate.length} orders',
      );
      _load();
    } catch (e) {
      SnackbarService.showError('Failed to parse file: $e');
    }
  }

  Future<void> _approveOrder(OrderDto o) async {
    try {
      final updated = await ref
          .read(orderRepositoryProvider)
          .approveOrder(o.id);
      if (mounted) {
        setState(() {
          _selectedOrder = updated;
          final idx = _orders.indexWhere((or) => or.id == updated.id);
          if (idx >= 0) _orders[idx] = updated;
        });
        SnackbarService.showSuccess('${updated.orderNumber} approved');
      }
    } catch (e) {
      SnackbarService.showError('Failed to approve: $e');
    }
  }

  Future<void> _rejectOrder(OrderDto o) async {
    try {
      final updated = await ref.read(orderRepositoryProvider).rejectOrder(o.id);
      if (mounted) {
        setState(() {
          _selectedOrder = updated;
          final idx = _orders.indexWhere((or) => or.id == updated.id);
          if (idx >= 0) _orders[idx] = updated;
        });
        SnackbarService.showSuccess('${updated.orderNumber} rejected');
      }
    } catch (e) {
      SnackbarService.showError('Failed to reject: $e');
    }
  }

  Future<void> _refreshOrder(OrderDto o) async {
    try {
      final fresh = await ref.read(orderRepositoryProvider).getOrder(o.id);
      if (mounted) {
        setState(() {
          _selectedOrder = fresh;
          final idx = _orders.indexWhere((or) => or.id == fresh.id);
          if (idx >= 0) _orders[idx] = fresh;
        });
      }
    } catch (e) {
      SnackbarService.showError('Failed to refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Order detail view
    if (_selectedOrder != null) {
      return _OrderDetail(
        order: _selectedOrder!,
        onBack: () => setState(() => _selectedOrder = null),
        onApprove: () => _approveOrder(_selectedOrder!),
        onReject: () => _rejectOrder(_selectedOrder!),
        onRefresh: () => _refreshOrder(_selectedOrder!),
      );
    }

    final items = _filtered;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _buildSearchBar(
        _searchCtrl,
        () => setState(() {}),
        hint: 'Search orders...',
      ),
    );

    final filterRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              'All',
              _statusFilter == null,
              () => setState(() => _statusFilter = null),
            ),
            const SizedBox(width: 6),
            for (final s in [
              OrderStatus.pending.value,
              OrderStatus.assigned.value,
              OrderStatus.inTransit.value,
              OrderStatus.delivered.value,
              OrderStatus.rejected.value,
            ]) ...[
              _filterChip(
                _formatStatus(s),
                _statusFilter == s,
                () => setState(
                  () => _statusFilter = _statusFilter == s ? null : s,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _sortAsc = !_sortAsc),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolBtn(
              Icons.add,
              'Add Order',
              () => setState(() => _showForm = !_showForm),
            ),
            const SizedBox(width: 8),
            _toolBtn(Icons.upload_file, 'Import CSV/XLSX', _importFromFile),
            const SizedBox(width: 8),
            Text(
              '${items.length} order${items.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );

    Widget orderBody() {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (items.isEmpty) return _emptyState('No orders found');
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _selectedOrder = items[i]),
            child: _buildOrderCard(items[i]),
          ),
        ),
      );
    }

    if (_showForm) {
      return Column(
        children: [
          header,
          filterRow,
          toolbar,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOrderForm(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: orderBody(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        filterRow,
        toolbar,
        Expanded(child: orderBody()),
      ],
    );
  }

  Widget _buildOrderForm() {
    final hasCoords = _latCtrl.text.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              const Text(
                'New Order',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _resetForm,
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
          // Client search
          const Text(
            'Client (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (_selectedClient != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedClient!.name ?? _selectedClient!.email}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedClient = null;
                      _clientSearchCtrl.clear();
                      _clientResults = [];
                    }),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _clientSearchCtrl,
              decoration: _inputDeco('Search client...').copyWith(
                suffixIcon: _searchingClients
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            if (_clientResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _clientResults.length,
                  itemBuilder: (_, i) {
                    final c = _clientResults[i];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        c.name ?? 'No name',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        c.email ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        c.companyName ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onTap: () => _selectClient(c),
                    );
                  },
                ),
              ),
          ],
          const SizedBox(height: 12),
          // Address + Geocode
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _addressCtrl,
                    decoration: _inputDeco('Delivery address'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _geocoding ? null : _geocode,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: hasCoords ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _geocoding
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
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Weight (kg)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _volumeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Volume (m²)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            decoration: _inputDeco('Description (optional)'),
          ),
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
                    '${_latCtrl.text}, ${_lonCtrl.text}',
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                      'Create Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderDto o) {
    final statusColor = _statusColor(o.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
                  o.orderNumber.isNotEmpty ? o.orderNumber : 'Order #${o.id}',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatStatus(o.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${o.weightKg.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMME CREATE — 3-STEP WIZARD (Select Orders → Review → Confirm)
// ═══════════════════════════════════════════════════════════
class _ProgramCreate extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCreated;
  const _ProgramCreate({required this.onBack, required this.onCreated});

  @override
  ConsumerState<_ProgramCreate> createState() => _ProgramCreateState();
}

class _ProgramCreateState extends ConsumerState<_ProgramCreate> {
  int _step = 0; // 0=Select Orders, 1=Review, 2=Confirm
  List<OrderDto> _allOrders = [];
  final Set<int> _selectedIds = {};
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  DateTime? _plannedDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await ref.read(orderRepositoryProvider).getOrders();
      if (mounted)
        setState(() {
          // Exclude completed/delivered/cancelled orders
          _allOrders = orders.where((o) {
            final s = o.status.toUpperCase();
            return s != OrderStatus.delivered.value &&
                s != OrderStatus.cancelled.value &&
                s != OrderStatus.rejected.value;
          }).toList();
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      SnackbarService.showError('Failed to load orders: $e');
    }
  }

  List<OrderDto> get _filteredOrders {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allOrders;
    return _allOrders
        .where(
          (o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.deliveryAddress.toLowerCase().contains(q) ||
              o.status.toLowerCase().contains(q),
        )
        .toList();
  }

  List<OrderDto> get _selectedOrders =>
      _allOrders.where((o) => _selectedIds.contains(o.id)).toList();

  void _toggleOrder(OrderDto o) {
    setState(() {
      if (_selectedIds.contains(o.id))
        _selectedIds.remove(o.id);
      else
        _selectedIds.add(o.id);
    });
  }

  void _selectAll() {
    setState(() {
      for (final o in _filteredOrders) _selectedIds.add(o.id);
    });
  }

  void _deselectAll() => setState(() => _selectedIds.clear());

  void _next() {
    if (_step == 0 && _selectedIds.isEmpty) {
      SnackbarService.showError('Select at least one order');
      return;
    }
    setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final selected = _selectedOrders;
      final plannedStr = _plannedDate != null
          ? _plannedDate!.toIso8601String()
          : null;
      await ref
          .read(dispatchRepositoryProvider)
          .createProgram(
            selected,
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            plannedDate: plannedStr,
          );
      SnackbarService.showSuccess(
        'Programme created with ${selected.length} orders',
      );
      widget.onCreated();
    } catch (e) {
      final msg = e.toString();
      SnackbarService.showError(
        'Failed to create programme: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStepper(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _step == 0
                ? _buildStepSelect()
                : _step == 1
                ? _buildStepReview()
                : _buildStepConfirm(),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    final labels = ['Select Orders', 'Review', 'Confirm'];
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

  // ── STEP 0: SELECT ORDERS ──
  Widget _buildStepSelect() {
    final filtered = _filteredOrders;
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(
            _searchCtrl,
            () => setState(() {}),
            hint: 'Search orders...',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_selectedIds.length} selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text('Select All', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filtered.isEmpty)
            _emptyState('No orders found')
          else
            ...filtered.map((o) => _buildSelectableOrder(o)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIds.isNotEmpty ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue (${_selectedIds.length} orders)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSelectableOrder(OrderDto o) {
    final selected = _selectedIds.contains(o.id);
    final statusColor = _statusColor(o.status);
    return GestureDetector(
      onTap: () => _toggleOrder(o),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.black.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.black : Colors.white,
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.orderNumber.isNotEmpty ? o.orderNumber : 'Order #${o.id}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatStatus(o.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  '${o.weightKg.toStringAsFixed(0)} kg • ${o.volumeM2.toStringAsFixed(0)} m²',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 1: REVIEW ──
  Widget _buildStepReview() {
    final selected = _selectedOrders;
    final totalWeight = selected.fold<double>(0, (s, o) => s + o.weightKg);
    final totalVolume = selected.fold<double>(0, (s, o) => s + o.volumeM2);

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _reviewStat('${selected.length}', 'Orders'),
                _reviewStat('${totalWeight.toStringAsFixed(0)} kg', 'Weight'),
                _reviewStat('${totalVolume.toStringAsFixed(0)} m²', 'Volume'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...selected.asMap().entries.map((e) {
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
                          o.deliveryAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${o.weightKg.toStringAsFixed(0)} kg  •  ${o.volumeM2.toStringAsFixed(0)} m²',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Planned Date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    _plannedDate ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _plannedDate = picked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _plannedDate != null
                        ? '${_plannedDate!.day}/${_plannedDate!.month}/${_plannedDate!.year}'
                        : 'Select planned date',
                    style: TextStyle(
                      fontSize: 14,
                      color: _plannedDate != null
                          ? Colors.black
                          : Colors.grey.shade500,
                      fontWeight: _plannedDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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

  // ── STEP 2: CONFIRM ──
  Widget _buildStepConfirm() {
    final selected = _selectedOrders;
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
                    color: Colors.green.withValues(alpha: 0.1),
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
                  '${selected.length} order${selected.length > 1 ? 's' : ''} will be linked to a new delivery programme.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (_plannedDate != null) ...[
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
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Planned: ${_plannedDate!.day}/${_plannedDate!.month}/${_plannedDate!.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMME DETAIL VIEW
// ═══════════════════════════════════════════════════════════
class _ProgramDetail extends ConsumerStatefulWidget {
  final DeliveryProgramDto program;
  final VoidCallback onBack;
  final VoidCallback onOptimize;
  final VoidCallback onDelete;
  final void Function(int orderId) onRemoveOrder;
  final VoidCallback onAddOrders;
  final VoidCallback onEdit;

  const _ProgramDetail({
    required this.program,
    required this.onBack,
    required this.onOptimize,
    required this.onDelete,
    required this.onRemoveOrder,
    required this.onAddOrders,
    required this.onEdit,
  });

  @override
  ConsumerState<_ProgramDetail> createState() => _ProgramDetailState();
}

class _ProgramDetailState extends ConsumerState<_ProgramDetail> {
  OptimizedProgramStatsDto? _stats;
  bool _loadingStats = false;

  DeliveryProgramDto get program => widget.program;
  VoidCallback get onBack => widget.onBack;
  VoidCallback get onOptimize => widget.onOptimize;
  VoidCallback get onDelete => widget.onDelete;
  void Function(int orderId) get onRemoveOrder => widget.onRemoveOrder;
  VoidCallback get onAddOrders => widget.onAddOrders;
  VoidCallback get onEdit => widget.onEdit;

  @override
  void initState() {
    super.initState();
    if (program.status != DeliveryProgramStatus.pending.value) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await ref
          .read(optimizationRepoProvider)
          .getProgramOptimizationStat(program.id);
      if (mounted)
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
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
          onPressed: onBack,
        ),
        title: Text(
          program.programNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          if (program.status == DeliveryProgramStatus.pending.value) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
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
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            if (_stats != null) ...[
              const SizedBox(height: 16),
              _buildOptimizationStats(),
            ],
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
                    if (program.status == DeliveryProgramStatus.pending.value)
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
            Row(
              children: [
                Expanded(
                  child: _buildSectionTitle(
                    'Orders (${program.orders.length})',
                  ),
                ),
                if (program.status == DeliveryProgramStatus.pending.value)
                  GestureDetector(
                    onTap: onAddOrders,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add Orders',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...program.orders.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildOrderRow(o, onRemoveOrder),
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
                  color: statusColor.withValues(alpha: 0.12),
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

  Widget _buildOptimizationStats() {
    final s = _stats!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Optimization Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem('${s.totalVehicles}', 'Vehicles'),
              _statItem(
                '${s.totalDistanceKm.toStringAsFixed(1)} km',
                'Distance',
              ),
              _statItem('${s.totalDurationMinutes} min', 'Duration'),
            ],
          ),
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
                  color: statusColor.withValues(alpha: 0.12),
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
              const Icon(Icons.person, size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                sp.driverName ?? 'Driver #${sp.driverId}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: Colors.black54,
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

  Widget _buildOrderRow(OrderDto o, void Function(int orderId) onRemoveOrder) {
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
          if (program.status == DeliveryProgramStatus.pending.value)
            GestureDetector(
              onTap: () => onRemoveOrder(o.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
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
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════

Widget _buildSearchBar(
  TextEditingController ctrl,
  VoidCallback onChanged, {
  String hint = 'Search programmes...',
}) {
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
        hintText: hint,
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

// ═══════════════════════════════════════════════════════════
// ORDER DETAIL
// ═══════════════════════════════════════════════════════════
class _OrderDetail extends StatelessWidget {
  final OrderDto order;
  final VoidCallback onBack;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRefresh;
  const _OrderDetail({
    required this.order,
    required this.onBack,
    this.onApprove,
    this.onReject,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(
          order.orderNumber.isNotEmpty
              ? order.orderNumber
              : 'Order #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: onRefresh,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatStatus(order.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Approve / Reject actions for pending orders
            if (order.status == OrderStatus.pending.value ||
                order.status == OrderStatus.unassigned.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (onApprove != null && onReject != null)
                      const SizedBox(width: 12),
                    if (onReject != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Delivery info
            _detailSection('Delivery Info', [
              _detailRow('Address', order.deliveryAddress),
              if (order.deliveryDescription != null)
                _detailRow('Description', order.deliveryDescription!),
              _detailRow('Latitude', order.deliveryLatitude.toStringAsFixed(6)),
              _detailRow(
                'Longitude',
                order.deliveryLongitude.toStringAsFixed(6),
              ),
            ]),
            const SizedBox(height: 16),

            // Order details
            _detailSection('Order Details', [
              _detailRow('Weight', '${order.weightKg.toStringAsFixed(1)} kg'),
              _detailRow('Volume', '${order.volumeM2.toStringAsFixed(2)} m²'),
              if (order.priority != null)
                _detailRow('Priority', _formatStatus(order.priority!)),
              if (order.clientId != null)
                _detailRow('Client ID', order.clientId.toString()),
              if (order.estimatedDeliveryTime != null)
                _detailRow('Estimated', order.estimatedDeliveryTime!),
              if (order.actualDeliveryTime != null)
                _detailRow('Actual', order.actualDeliveryTime!),
              if (order.createdAt != null)
                _detailRow('Created', _formatDate(order.createdAt!)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ORDER PICKER DIALOG — Select orders to add to a program
// ═══════════════════════════════════════════════════════════
class _OrderPickerDialog extends StatefulWidget {
  final List<OrderDto> orders;
  const _OrderPickerDialog({required this.orders});

  @override
  State<_OrderPickerDialog> createState() => _OrderPickerDialogState();
}

class _OrderPickerDialogState extends State<_OrderPickerDialog> {
  final Set<int> _selected = {};
  final _searchCtrl = TextEditingController();

  List<OrderDto> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.orders;
    return widget.orders
        .where(
          (o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.deliveryAddress.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Text(
            'Add Orders',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (_selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selected.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final o = items[i];
                  final isSelected = _selected.contains(o.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      isSelected ? _selected.remove(o.id) : _selected.add(o.id);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${o.weightKg.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _selected.isEmpty
                ? 'Select Orders'
                : 'Add ${_selected.length} Order(s)',
          ),
        ),
      ],
    );
  }
}
