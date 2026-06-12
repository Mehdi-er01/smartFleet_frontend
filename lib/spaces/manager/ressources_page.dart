import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/dto/driver_dto.dart';
import 'package:smartfleet_frontend/dto/vehicle_dto.dart';
import 'package:smartfleet_frontend/service/fleet_repository.dart';
import 'package:smartfleet_frontend/service/snackbar_service.dart';

// ═══════════════════════════════════════════════════════════
// MAIN PAGE — Tabbed container
// ═══════════════════════════════════════════════════════════
class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

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
            'Fleet Resources',
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
              Tab(text: 'Drivers', icon: Icon(Icons.person_outline, size: 20)),
              Tab(
                text: 'Vehicles',
                icon: Icon(Icons.local_shipping_outlined, size: 20),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_DriversTab(), _VehiclesTab()]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DRIVERS TAB
// ═══════════════════════════════════════════════════════════
enum _DriverSection { myDrivers, available }

class _DriversTab extends ConsumerStatefulWidget {
  const _DriversTab();
  @override
  ConsumerState<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<_DriversTab> {
  final _searchCtrl = TextEditingController();
  _DriverSection _section = _DriverSection.myDrivers;
  bool _showActiveOnly = false;
  List<DriverDto> _myDrivers = [];
  List<DriverDto> _unassigned = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(() {});
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(fleetRepositoryProvider);
      final myDriversFuture = repo.getMyDrivers();
      final unassignedFuture = repo.getUnassignedDrivers();
      final myDrivers = await myDriversFuture;
      final unassigned = await unassignedFuture;
      if (mounted) {
        setState(() {
          _myDrivers = myDrivers;
          _unassigned = unassigned;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DriverDto> get _filtered {
    var list = _section == _DriverSection.myDrivers ? _myDrivers : _unassigned;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.email.toLowerCase().contains(q) ||
                d.phone.contains(q) ||
                (d.licenseNumber?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (_showActiveOnly) {
      list = list.where((d) => d.active).toList();
    }
    return list;
  }

  Future<void> _assign(DriverDto d) async {
    await ref.read(fleetRepositoryProvider).assignDriver(d.id);
    SnackbarService.showSuccess('${d.name} assigned to your fleet');
    _load();
  }

  Future<void> _unassign(DriverDto d) async {
    await ref.read(fleetRepositoryProvider).unassignDriver(d.id);
    SnackbarService.showSuccess('${d.name} removed from your fleet');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Column(
      children: [
        // ── Search ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildSearchBar(_searchCtrl),
        ),
        // ── Section chips ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  'My Drivers (${_myDrivers.length})',
                  _section == _DriverSection.myDrivers,
                  () => setState(() => _section = _DriverSection.myDrivers),
                ),
                const SizedBox(width: 8),
                _chip(
                  'Available (${_unassigned.length})',
                  _section == _DriverSection.available,
                  () => setState(() => _section = _DriverSection.available),
                ),
                const SizedBox(width: 16),
                // Active-only toggle
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      setState(() => _showActiveOnly = !_showActiveOnly),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _showActiveOnly ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showActiveOnly
                            ? Colors.black
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: _showActiveOnly
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _showActiveOnly
                                ? Colors.white
                                : Colors.black87,
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
        // ── List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? _emptyState(
                  _section == _DriverSection.myDrivers
                      ? 'No drivers in your fleet'
                      : 'No available drivers',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildDriverCard(items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(DriverDto d) {
    final isMyDriver = _section == _DriverSection.myDrivers;
    final availColor = d.available ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: availColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.available ? 'AVAILABLE' : 'BUSY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: availColor,
                        ),
                      ),
                    ),
                    if (!d.active) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  d.email,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  d.phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (d.licenseNumber != null)
                  Text(
                    'License: ${d.licenseNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          // Action
          if (isMyDriver)
            _actionBtn(
              Icons.person_remove,
              'Remove',
              Colors.red.shade700,
              () => _unassign(d),
            )
          else
            _actionBtn(
              Icons.person_add,
              'Assign',
              Colors.black,
              () => _assign(d),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// VEHICLES TAB
// ═══════════════════════════════════════════════════════════
class _VehiclesTab extends ConsumerStatefulWidget {
  const _VehiclesTab();
  @override
  ConsumerState<_VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends ConsumerState<_VehiclesTab> {
  final _searchCtrl = TextEditingController();
  bool? _activeFilter; // null=all, true=active, false=inactive
  List<VehicleDto> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
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
      final list = await ref.read(fleetRepositoryProvider).getVehicles();
      if (mounted) {
        setState(() {
          _vehicles = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<VehicleDto> get _filtered {
    var list = _vehicles;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (v) =>
                v.registrationNumber.toLowerCase().contains(q) ||
                v.model.toLowerCase().contains(q) ||
                v.brand.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_activeFilter != null) {
      list = list.where((v) => v.active == _activeFilter).toList();
    }
    return list;
  }

  Future<void> _toggleActive(VehicleDto v) async {
    final newActive = !v.active;
    await ref
        .read(fleetRepositoryProvider)
        .toggleVehicleActive(v.id, newActive);
    SnackbarService.showSuccess(
      '${v.brand} ${v.model} ${newActive ? 'activated' : 'deactivated'}',
    );
    _load();
  }

  Future<void> _openForm({VehicleDto? vehicle}) async {
    final result = await showDialog<VehicleDto>(
      context: context,
      builder: (ctx) => _VehicleFormDialog(existing: vehicle),
    );
    if (result != null) {
      final repo = ref.read(fleetRepositoryProvider);
      if (vehicle == null) {
        await repo.createVehicle(result);
        SnackbarService.showSuccess('Vehicle created');
      } else {
        await repo.updateVehicle(vehicle.id, result);
        SnackbarService.showSuccess('Vehicle updated');
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Stack(
      children: [
        Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSearchBar(_searchCtrl),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(
                      'All',
                      _activeFilter == null,
                      () => setState(() => _activeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Active',
                      _activeFilter == true,
                      () => setState(() => _activeFilter = true),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Inactive',
                      _activeFilter == false,
                      () => setState(() => _activeFilter = false),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${items.length} vehicles',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? _emptyState('No vehicles found')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildVehicleCard(items[i]),
                      ),
                    ),
            ),
          ],
        ),
        // FAB — Add vehicle
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () => _openForm(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(VehicleDto v) {
    final statusColor = v.active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${v.brand} ${v.model}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.active ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Reg: ${v.registrationNumber}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Text(
                      '${v.maxPayloadKg.toStringAsFixed(0)} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Text('  •  ', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${v.maxVolumeM2.toStringAsFixed(0)} m²',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Text('  •  ', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${v.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              _iconOnlyBtn(Icons.edit_outlined, () => _openForm(vehicle: v)),
              const SizedBox(height: 4),
              _iconOnlyBtn(
                v.active ? Icons.toggle_on : Icons.toggle_off,
                () => _toggleActive(v),
                color: v.active ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// VEHICLE FORM DIALOG
// ═══════════════════════════════════════════════════════════
class _VehicleFormDialog extends StatefulWidget {
  final VehicleDto? existing;
  const _VehicleFormDialog({this.existing});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _volumeCtrl;
  late final TextEditingController _payloadCtrl;
  late bool _active;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _regCtrl = TextEditingController(text: v?.registrationNumber ?? '');
    _brandCtrl = TextEditingController(text: v?.brand ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v != null ? v.year.toString() : '');
    _volumeCtrl = TextEditingController(
      text: v != null ? v.maxVolumeM2.toString() : '',
    );
    _payloadCtrl = TextEditingController(
      text: v != null ? v.maxPayloadKg.toString() : '',
    );
    _active = v?.active ?? true;
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _volumeCtrl.dispose();
    _payloadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      VehicleDto(
        id: widget.existing?.id ?? 0,
        registrationNumber: _regCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: int.tryParse(_yearCtrl.text) ?? 0,
        maxVolumeM2: double.tryParse(_volumeCtrl.text) ?? 0,
        maxPayloadKg: double.tryParse(_payloadCtrl.text) ?? 0,
        active: _active,
        managerId: widget.existing?.managerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Edit Vehicle' : 'Add Vehicle',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(_regCtrl, 'Registration Number', hint: '1234-A-15'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _formField(_brandCtrl, 'Brand', hint: 'Volvo'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _formField(_modelCtrl, 'Model', hint: 'FH16'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _formField(
                        _yearCtrl,
                        'Year',
                        hint: '2022',
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _formField(
                        _volumeCtrl,
                        'Max Volume (m²)',
                        hint: '82',
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _formField(
                  _payloadCtrl,
                  'Max Payload (kg)',
                  hint: '25000',
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active', style: TextStyle(fontSize: 14)),
                  value: _active,
                  activeColor: Colors.black,
                  onChanged: (v) => setState(() => _active = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label, {
    String hint = '',
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDeco(label).copyWith(hintText: hint),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
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
}

// ═══════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════

Widget _buildSearchBar(TextEditingController ctrl) {
  return Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: 'Search...',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
    ),
  );
}

Widget _actionBtn(
  IconData icon,
  String label,
  Color color,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _iconOnlyBtn(IconData icon, VoidCallback onTap, {Color? color}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: (color ?? Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color ?? Colors.black87),
    ),
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
