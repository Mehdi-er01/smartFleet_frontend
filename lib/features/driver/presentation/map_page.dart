import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartfleet_frontend/core/websocket_service.dart';
import 'package:smartfleet_frontend/features/order/data/order_dto.dart';
import 'package:smartfleet_frontend/features/order/domain/order_status.dart';
import 'package:smartfleet_frontend/features/driver/data/sub_program_dto.dart';
import 'package:smartfleet_frontend/features/driver/data/driver_repository.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

class MapPage extends ConsumerStatefulWidget {
  final SubProgramDto? activeSubProgram;
  final int? driverId;
  const MapPage({super.key, this.activeSubProgram, this.driverId});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  vtr.Theme? _mapTheme;
  bool _themeLoading = true;

  LatLng? _userLocation;
  String _locationError = '';
  Timer? _locationTimer;
  bool _isFetchingLocation = false;

  List<OrderDto> _stopOrders = [];

  final String _tileServerUrl =
      'http://127.0.0.1:8081/morocco_vector/{z}/{x}/{y}.mvt';

  @override
  void initState() {
    super.initState();
    _loadVectorStyle();
    _connectWebSocket();
    _startLocationTracking();
    _loadStops();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVectorStyle() async {
    try {
      final styleString = await rootBundle.loadString('assets/map_style.json');
      final styleJson = jsonDecode(styleString);
      final theme = vtr.ThemeReader().read(styleJson);
      if (mounted)
        setState(() {
          _mapTheme = theme;
          _themeLoading = false;
        });
    } catch (e) {
      final fallback = {
        'version': 8,
        'name': 'Fallback',
        'sources': {
          'openmaptiles': {'type': 'vector'},
        },
        'layers': [
          {
            'id': 'background',
            'type': 'background',
            'paint': {'background-color': '#F7F8FA'},
          },
          {
            'id': 'roads',
            'type': 'line',
            'source': 'openmaptiles',
            'source-layer': 'transportation',
            'paint': {'line-color': '#D0D0D0', 'line-width': 2},
          },
        ],
      };
      final theme = vtr.ThemeReader(
        logger: const vtr.Logger.console(),
      ).read(fallback);
      if (mounted)
        setState(() {
          _mapTheme = theme;
          _themeLoading = false;
        });
    }
  }

  Future<void> _loadStops() async {
    final sp = widget.activeSubProgram;
    if (sp == null || sp.orderIds.isEmpty) return;
    try {
      final repo = ref.read(driverRepositoryProvider);
      final orders = await repo.getOrdersByIds(sp.orderIds);
      if (mounted) setState(() => _stopOrders = orders);
    } catch (_) {}
  }

  Future<void> _startLocationTracking() async {
    final ok = await _requestLocationPermission();
    if (!ok) return;
    await _fetchUserLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchUserLocation(),
    );
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        setState(() => _locationError = 'Location services disabled.');
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted)
        setState(() => _locationError = 'Location permission denied.');
      return false;
    }
    return true;
  }

  Future<void> _fetchUserLocation() async {
    if (_isFetchingLocation) return;

    _isFetchingLocation = true;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _locationError = '';
        });
      }
      _publishLocation(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) setState(() => _locationError = 'Could not get location.');
    } finally {
      _isFetchingLocation = false;
    }
  }

  void _publishLocation(double latitude, double longitude) {
    ref.read(webSocketServiceProvider).sendDriverLocation({
      'driverId': widget.driverId,
      'subProgramId': widget.activeSubProgram?.id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _connectWebSocket() {
    ref
        .read(webSocketServiceProvider)
        .connect(() => debugPrint('Driver location WebSocket ready.'));
  }

  List<LatLng> get _stopPoints => _stopOrders
      .where((o) => o.deliveryLatitude != 0 || o.deliveryLongitude != 0)
      .map((o) => LatLng(o.deliveryLatitude, o.deliveryLongitude))
      .toList();

  LatLng get _mapCenter {
    if (_userLocation != null) return _userLocation!;
    if (_stopPoints.isNotEmpty) return _stopPoints.first;
    return const LatLng(33.58717, -7.61353);
  }

  @override
  Widget build(BuildContext context) {
    if (_themeLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
        ),
      );
    }

    final stops = _stopPoints;
    final pendingStops = _stopOrders
        .where(
          (o) =>
              o.status != OrderStatus.delivered.value &&
              o.status != OrderStatus.rejected.value,
        )
        .length;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 13.0,
              maxZoom: 19.0,
            ),
            children: [
              if (_mapTheme != null)
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

              // Route line between all stops
              if (stops.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [?_userLocation, ...stops],
                      color: Colors.black.withValues(alpha: 0.2),
                      strokeWidth: 2,
                      pattern: StrokePattern.dashed(segments: [8, 6]),
                    ),
                  ],
                ),

              // Delivery stop markers
              MarkerLayer(
                markers: [
                  ...stops.asMap().entries.map((entry) {
                    final i = entry.key;
                    final point = entry.value;
                    final order = _stopOrders.firstWhere(
                      (o) =>
                          (o.deliveryLatitude == point.latitude &&
                          o.deliveryLongitude == point.longitude),
                      orElse: () => _stopOrders[i],
                    );
                    final isDelivered =
                        order.status == OrderStatus.delivered.value;
                    final isFailed = order.status == OrderStatus.rejected.value;
                    return Marker(
                      point: point,
                      width: 56,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showStopSheet(context, order, i + 1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDelivered
                                    ? const Color(0xFF2E7D32)
                                    : isFailed
                                    ? const Color(0xFFC62828)
                                    : Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _TrianglePainter(
                                isDelivered
                                    ? const Color(0xFF2E7D32)
                                    : isFailed
                                    ? const Color(0xFFC62828)
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Driver location
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.07),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.activeSubProgram != null
                                ? widget.activeSubProgram!.subProgramNumber
                                : 'Route Map',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (_userLocation != null) {
                          _mapController.move(_userLocation!, 14.0);
                        }
                      },
                      child: _iconButton(Icons.my_location),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (stops.isNotEmpty) {
                          _mapController.move(stops.first, 12.0);
                        }
                      },
                      child: _iconButton(Icons.route_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom stats card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: widget.activeSubProgram == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No active route assigned',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _bottomStat(
                          Icons.location_on_outlined,
                          '${stops.length}',
                          'Stops',
                        ),
                        _divider(),
                        _bottomStat(
                          Icons.pending_outlined,
                          '$pendingStops',
                          'Remaining',
                        ),
                        _divider(),
                        _bottomStat(
                          Icons.check_circle_outline,
                          '${_stopOrders.where((o) => o.status == OrderStatus.delivered.value).length}',
                          'Delivered',
                        ),
                        if (widget.activeSubProgram?.estimatedDistanceKm !=
                            null) ...[
                          _divider(),
                          _bottomStat(
                            Icons.straighten_outlined,
                            widget.activeSubProgram!.estimatedDistanceKm!
                                .toStringAsFixed(1),
                            'km',
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          // ── Location error ──
          if (_locationError.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStopSheet(BuildContext context, OrderDto order, int stopNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stop $stopNumber · ${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            const SizedBox(height: 16),
            Text(
              order.deliveryAddress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (order.deliveryDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                order.deliveryDescription!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${order.weightKg} kg · ${order.volumeM2} m²',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }

  Widget _bottomStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 32,
    width: 1,
    color: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
