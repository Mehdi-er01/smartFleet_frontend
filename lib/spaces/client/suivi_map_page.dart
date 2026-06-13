import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'order_dto.dart';
import 'order_detail_sheet.dart';

class SuiviMapPage extends StatefulWidget {
  final OrderDTO? activeOrder;
  const SuiviMapPage({super.key, required this.activeOrder});

  @override
  State<SuiviMapPage> createState() => _SuiviMapPageState();
}

class _SuiviMapPageState extends State<SuiviMapPage> {
  final MapController _mapController = MapController();
  vtr.Theme? _mapTheme;
  bool _themeLoading = true;

  LatLng? _userLocation;
  String _locationError = '';
  Timer? _locationTimer;

  final String _tileServerUrl =
      'http://127.0.0.1:8081/morocco_vector/{z}/{x}/{y}.mvt';

  @override
  void initState() {
    super.initState();
    _loadVectorStyle();
    _startLocationTracking();
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
      if (mounted) setState(() { _mapTheme = theme; _themeLoading = false; });
    } catch (e) {
      final fallback = {
        'version': 8,
        'name': 'Fallback',
        'sources': {'openmaptiles': {'type': 'vector'}},
        'layers': [
          {'id': 'background', 'type': 'background', 'paint': {'background-color': '#F7F8FA'}},
          {'id': 'roads', 'type': 'line', 'source': 'openmaptiles',
           'source-layer': 'transportation', 'paint': {'line-color': '#D0D0D0', 'line-width': 2}},
        ],
      };
      final theme = vtr.ThemeReader(logger: const vtr.Logger.console()).read(fallback);
      if (mounted) setState(() { _mapTheme = theme; _themeLoading = false; });
    }
  }

  Future<void> _startLocationTracking() async {
    final ok = await _requestLocationPermission();
    if (!ok) return;
    await _fetchUserLocation();
    // refresh every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchUserLocation());
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationError = 'Location services disabled.');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationError = 'Location permission denied.');
      return false;
    }
    return true;
  }

  Future<void> _fetchUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _locationError = '';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _locationError = 'Could not get location.');
    }
  }

  LatLng get _deliveryPoint {
    final o = widget.activeOrder;
    if (o != null && (o.deliveryLatitude != 0 || o.deliveryLongitude != 0)) {
      return LatLng(o.deliveryLatitude, o.deliveryLongitude);
    }
    return const LatLng(33.58717, -7.61353);
  }

  LatLng get _mapCenter {
    if (_userLocation != null) {
      // Center between user and delivery point
      return LatLng(
        (_userLocation!.latitude + _deliveryPoint.latitude) / 2,
        (_userLocation!.longitude + _deliveryPoint.longitude) / 2,
      );
    }
    return _deliveryPoint;
  }

  double get _mapZoom {
    if (_userLocation == null) return 14.5;
    final dist = const Distance().as(LengthUnit.Kilometer, _userLocation!, _deliveryPoint);
    if (dist < 1) return 14.5;
    if (dist < 5) return 12.0;
    if (dist < 20) return 10.0;
    return 8.0;
  }

  String _formatArrival(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length >= 5 ? raw.substring(0, 5) : raw;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'IN_TRANSIT': return 'In Transit';
      case 'IN_PROGRESS': return 'In Progress';
      case 'PENDING': return 'Pending';
      default: return status;
    }
  }

  void _fitBothMarkers() {
    if (_userLocation == null) {
      _mapController.move(_deliveryPoint, 14.5);
      return;
    }
    _mapController.move(_mapCenter, _mapZoom);
  }

  @override
  Widget build(BuildContext context) {
    // ── No active order ──
    if (widget.activeOrder == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE TRACKING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    const Text('No Active Order', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 20),
                      const Text('Nothing to track right now', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(
                        'Your active orders will appear here\nonce they are in transit.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_themeLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
      );
    }

    final order = widget.activeOrder!;
    final deliveryPoint = _deliveryPoint;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
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

              // ── Dashed line between user and delivery ──
              if (_userLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userLocation!, deliveryPoint],
                      color: Colors.black.withValues(alpha: 0.18),
                      strokeWidth: 2.5,
                      pattern: StrokePattern.dashed(segments: [10, 8]),
                    ),
                  ],
                ),

              // ── Markers ──
              MarkerLayer(
                markers: [
                  // Delivery destination pin
                  Marker(
                    point: deliveryPoint,
                    width: 56,
                    height: 72,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                        ),
                        CustomPaint(size: const Size(12, 8), painter: _TrianglePainter(Colors.black)),
                      ],
                    ),
                  ),

                  // User location pulse marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showOrderDetailSheet(context, order),
                      child: _iconButton(Icons.info_outline),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _fitBothMarkers,
                      child: _iconButton(Icons.fit_screen_outlined),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _fetchUserLocation,
                      child: _iconButton(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Legend (top-right corner, below controls) ──
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _legendItem(Colors.black, Icons.local_shipping, 'Delivery'),
                const SizedBox(height: 6),
                _legendItem(Colors.black, Icons.person, 'You'),
                if (_locationError.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(_locationError, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ),
                ],
              ],
            ),
          ),

          // ── Bottom order card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_shipping_outlined, color: Colors.black87, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                            const SizedBox(height: 2),
                            Text(_statusLabel(order.status), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      if (order.estimatedDeliveryTime != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Est. Arrival', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              _formatArrival(order.estimatedDeliveryTime),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F1F5)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_userLocation != null) ...[
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Distance', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 1),
                            Text(
                              _distanceLabel(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceLabel() {
    if (_userLocation == null) return '';
    final dist = const Distance().as(LengthUnit.Kilometer, _userLocation!, _deliveryPoint);
    return dist < 1 ? '${(dist * 1000).round()} m' : '${dist.toStringAsFixed(1)} km';
  }

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
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
