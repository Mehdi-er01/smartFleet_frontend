import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:smartfleet_frontend/core/websocket_service.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/fleet/data/driver_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/data/delivery_program_dto.dart';
import 'package:smartfleet_frontend/features/dispatch/data/dispatch_repository.dart';
import 'package:smartfleet_frontend/features/fleet/data/vehicle_repository.dart';

class MapPage extends ConsumerStatefulWidget {
  final int? managerId;
  const MapPage({super.key, this.managerId});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  vtr.Theme? _mapTheme;

  // Data
  List<OrderDto> _orders = [];
  List<DriverDto> _drivers = [];
  List<DeliveryProgramDto> _programs = [];
  bool _loading = true;
  String? _error;

  // Filters
  bool _showOrders = true;
  bool _showDrivers = true;
  bool _showRoutes = true;

  // Selected item for bottom sheet
  _SelectedItem? _selectedItem;
  VoidCallback? _locationSubscription;

  final String _tileServerUrl =
      'http://127.0.0.1:8081/morocco_vector/{z}/{x}/{y}.mvt';

  @override
  void initState() {
    super.initState();
    _loadVectorStyle();
    _loadData();
    _connectWebSocket();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.managerId != widget.managerId) {
      _connectWebSocket();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.call();
    super.dispose();
  }

  Future<void> _loadVectorStyle() async {
    try {
      final styleString = await rootBundle.loadString('assets/map_style.json');
      final styleJson = jsonDecode(styleString);
      final theme = vtr.ThemeReader().read(styleJson);
      setState(() => _mapTheme = theme);
    } catch (e) {
      debugPrint("Error loading map style: $e");
      final fallback = {
        "version": 8,
        "name": "Fallback",
        "sources": {
          "openmaptiles": {"type": "vector"},
        },
        "layers": [
          {
            "id": "background",
            "type": "background",
            "paint": {"background-color": "#F0F4F8"},
          },
          {
            "id": "roads",
            "type": "line",
            "source": "openmaptiles",
            "source-layer": "transportation",
            "paint": {"line-color": "#D6D9DE", "line-width": 2},
          },
        ],
      };
      setState(() => _mapTheme = vtr.ThemeReader().read(fallback));
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dispatch = ref.read(dispatchRepositoryProvider);
      final fleet = ref.read(fleetRepositoryProvider);

      final results = await Future.wait([
        dispatch.getOrders(),
        fleet.getDriverLocations(),
        dispatch.getPrograms(),
      ]);

      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<OrderDto>;
        _drivers = results[1] as List<DriverDto>;
        _programs = results[2] as List<DeliveryProgramDto>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load map data: ${e.toString().length > 120 ? '${e.toString().substring(0, 120)}...' : e}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _connectWebSocket() {
    _locationSubscription?.call();
    _locationSubscription = null;

    final managerId = widget.managerId;
    if (managerId == null) return;

    ref.read(webSocketServiceProvider).connect(() {
      final unsubscribe = ref
          .read(webSocketServiceProvider)
          .subscribeToFleetLocations(managerId, _handleFleetLocationUpdate);
      if (mounted) {
        setState(() => _locationSubscription = unsubscribe);
      }
    });
  }

  void _handleFleetLocationUpdate(dynamic data) {
    final updates = _extractDriverUpdates(data);
    if (updates.isEmpty) return;

    setState(() {
      for (final update in updates) {
        final driverId =
            _numberFrom(update['id']) ??
            _numberFrom(update['driverId']) ??
            _numberFrom(update['userId']);
        if (driverId == null) continue;

        final currentIndex = _drivers.indexWhere((d) => d.id == driverId);
        if (currentIndex == -1) continue;

        final current = _drivers[currentIndex];
        _drivers[currentIndex] = DriverDto(
          id: current.id,
          email: update['email'] as String? ?? current.email,
          name: update['name'] as String? ?? current.name,
          phone: update['phone'] as String? ?? current.phone,
          role: update['role'] as String? ?? current.role,
          active: update['active'] is bool
              ? update['active'] as bool
              : current.active,
          licenseNumber:
              update['licenseNumber'] as String? ?? current.licenseNumber,
          licenseExpiry:
              update['licenseExpiry'] as String? ?? current.licenseExpiry,
          available: update['available'] is bool
              ? update['available'] as bool
              : current.available,
          managerId: _intFrom(update['managerId']) ?? current.managerId,
          currentLatitude:
              _numberFrom(update['currentLatitude']) ??
              _numberFrom(update['latitude']) ??
              current.currentLatitude,
          currentLongitude:
              _numberFrom(update['currentLongitude']) ??
              _numberFrom(update['longitude']) ??
              current.currentLongitude,
          lastLocationUpdate:
              update['lastLocationUpdate'] as String? ??
              current.lastLocationUpdate,
        );
      }
    });
  }

  List<Map<String, dynamic>> _extractDriverUpdates(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is! Map) return [];

    if (data['drivers'] is List) {
      return (data['drivers'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data['driver'] is Map) {
      return [Map<String, dynamic>.from(data['driver'] as Map)];
    }

    if (data['id'] != null ||
        data['driverId'] != null ||
        data['currentLatitude'] != null ||
        data['latitude'] != null) {
      return [Map<String, dynamic>.from(data)];
    }

    return [];
  }

  double? _numberFrom(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _intFrom(dynamic value) {
    final number = _numberFrom(value);
    return number?.toInt();
  }

  // ─── ORDER MARKERS ──────────────────────────────────
  List<Marker> _buildOrderMarkers() {
    if (!_showOrders) return [];
    return _orders
        .where((o) => o.deliveryLatitude != 0 && o.deliveryLongitude != 0)
        .map((order) {
          final color = _orderStatusColor(order.status);
          return Marker(
            point: LatLng(order.deliveryLatitude, order.deliveryLongitude),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => setState(
                () => _selectedItem = _SelectedItem(
                  type: _ItemType.order,
                  title: order.orderNumber,
                  subtitle: order.deliveryAddress,
                  status: order.status,
                  details: [
                    'Weight: ${order.weightKg} kg',
                    'Volume: ${order.volumeM2} m²',
                    if (order.priority != null) 'Priority: ${order.priority}',
                    if (order.estimatedDeliveryTime != null)
                      'ETA: ${order.estimatedDeliveryTime}',
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        })
        .toList();
  }

  // ─── DRIVER MARKERS ─────────────────────────────────
  List<Marker> _buildDriverMarkers() {
    if (!_showDrivers) return [];
    return _drivers.where((d) => d.hasLocation).map((driver) {
      final color = (driver.available ?? false)
          ? const Color(0xFF2ECC71)
          : const Color(0xFF95A5A6);
      return Marker(
        point: LatLng(driver.currentLatitude!, driver.currentLongitude!),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => setState(
            () => _selectedItem = _SelectedItem(
              type: _ItemType.driver,
              title: driver.name,
              subtitle: driver.email,
              status: (driver.available ?? false) ? 'AVAILABLE' : 'BUSY',
              details: [
                'Phone: ${driver.phone}',
                if (driver.licenseNumber != null)
                  'License: ${driver.licenseNumber}',
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─── ROUTE POLYLINES ────────────────────────────────
  List<Polyline> _buildRoutePolylines() {
    if (!_showRoutes) return [];
    final polylines = <Polyline>[];
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      const Color(0xFF2ECC71),
      const Color(0xFF9B59B6),
      const Color(0xFFE67E22),
      const Color(0xFF1ABC9C),
    ];
    int colorIdx = 0;

    for (final program in _programs) {
      for (final sub in program.subPrograms) {
        if (sub.polyline != null && sub.polyline!.isNotEmpty) {
          final points = _decodePolyline(sub.polyline!);
          if (points.isNotEmpty) {
            final color = colors[colorIdx % colors.length];
            polylines.add(
              Polyline(
                points: points,
                strokeWidth: 3.5,
                color: color,
                pattern: StrokePattern.dashed(segments: [8, 4]),
              ),
            );
            colorIdx++;
          }
        }
      }
    }
    return polylines;
  }

  /// Decodes a Google-encoded polyline string into LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Color _orderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFF39C12);
      case 'ASSIGNED':
        return const Color(0xFF3498DB);
      case 'IN_TRANSIT':
        return const Color(0xFF9B59B6);
      case 'ARRIVING_SOON':
        return const Color(0xFF1ABC9C);
      case 'DELIVERED':
        return const Color(0xFF2ECC71);
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  // ─── BUILD ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_mapTheme == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(33.58717, -7.61353),
              initialZoom: 13.0,
              maxZoom: 19.0,
            ),
            children: [
              VectorTileLayer(
                theme: _mapTheme!,
                tileOffset: TileOffset.mapbox,
                tileProviders: TileProviders({
                  'openmaptiles': NetworkVectorTileProvider(
                    urlTemplate: _tileServerUrl,
                    maximumZoom: 14,
                  ),
                }),
              ),
              // Route polylines
              PolylineLayer(polylines: _buildRoutePolylines()),
              // Order markers
              MarkerLayer(markers: _buildOrderMarkers()),
              // Driver markers
              MarkerLayer(markers: _buildDriverMarkers()),
            ],
          ),

          // ── TOP BAR ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Title pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: Color(0xFF2C3E50),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Fleet Map',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Refresh
                _buildCircleButton(icon: Icons.refresh, onTap: _loadData),
              ],
            ),
          ),

          // ── FILTER CHIPS ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChip(
                  label: 'Orders',
                  icon: Icons.inventory_2,
                  active: _showOrders,
                  color: const Color(0xFFF39C12),
                  onTap: () => setState(() => _showOrders = !_showOrders),
                ),
                const SizedBox(height: 8),
                _buildFilterChip(
                  label: 'Drivers',
                  icon: Icons.directions_car,
                  active: _showDrivers,
                  color: const Color(0xFF2ECC71),
                  onTap: () => setState(() => _showDrivers = !_showDrivers),
                ),
                const SizedBox(height: 8),
                _buildFilterChip(
                  label: 'Routes',
                  icon: Icons.route,
                  active: _showRoutes,
                  color: const Color(0xFF3498DB),
                  onTap: () => setState(() => _showRoutes = !_showRoutes),
                ),
              ],
            ),
          ),

          // ── LEGEND ──
          Positioned(bottom: 24, left: 16, child: _buildLegend()),

          // ── STATS BADGE ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: _buildStatsBadge(),
          ),

          // ── FAB ──
          Positioned(
            right: 16,
            bottom: 24,
            child: _buildCircleButton(
              icon: Icons.my_location,
              onTap: () =>
                  _mapController.move(const LatLng(33.58717, -7.61353), 13.0),
            ),
          ),

          // ── LOADING ──
          if (_loading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
              ),
            ),

          // ── ERROR ──
          if (_error != null && !_loading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── BOTTOM SHEET ──
          if (_selectedItem != null) _buildBottomSheet(),
        ],
      ),
    );
  }

  // ─── WIDGETS ────────────────────────────────────────
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF2C3E50)),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : const Color(0xFF6B7B8D),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF6B7B8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          _legendItem(const Color(0xFFF39C12), 'Pending'),
          _legendItem(const Color(0xFF3498DB), 'Assigned'),
          _legendItem(const Color(0xFF9B59B6), 'In Transit'),
          _legendItem(const Color(0xFF2ECC71), 'Delivered / Available'),
          _legendItem(const Color(0xFFE74C3C), 'Cancelled'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF4A6070)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge() {
    final activeOrders = _orders
        .where(
          (o) =>
              o.status != 'DELIVERED' &&
              o.status != 'CANCELLED' &&
              o.status != 'REJECTED',
        )
        .length;
    final activeDrivers = _drivers.where((d) => d.hasLocation).length;
    final activeRoutes = _programs
        .expand((p) => p.subPrograms)
        .where((s) => s.polyline != null && s.polyline!.isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow(
            Icons.inventory_2,
            activeOrders.toString(),
            const Color(0xFFF39C12),
          ),
          const SizedBox(height: 4),
          _statRow(
            Icons.directions_car,
            activeDrivers.toString(),
            const Color(0xFF2ECC71),
          ),
          const SizedBox(height: 4),
          _statRow(
            Icons.route,
            activeRoutes.toString(),
            const Color(0xFF3498DB),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    final item = _selectedItem!;
    final statusColor = item.type == _ItemType.order
        ? _orderStatusColor(item.status)
        : (item.status == 'AVAILABLE'
              ? const Color(0xFF2ECC71)
              : const Color(0xFF95A5A6));

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.type == _ItemType.order
                          ? Icons.inventory_2
                          : Icons.directions_car,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7B8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...item.details.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: Color(0xFFB0BEC5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A6070),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedItem = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7B8D),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MODELS ───────────────────────────────────────────
enum _ItemType { order, driver }

class _SelectedItem {
  final _ItemType type;
  final String title;
  final String subtitle;
  final String status;
  final List<String> details;

  _SelectedItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.details,
  });
}
