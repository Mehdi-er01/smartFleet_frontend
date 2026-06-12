import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:geolocator/geolocator.dart';
import 'package:smartfleet_frontend/service/api_client.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  
  vtr.Theme? _mapTheme;
  final List<LatLng> _deliveries = [];

  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSub;
  int? _driverId;
  bool _isLoadingLoc = true;

  // Change 127.0.0.1 to 10.0.2.2 if testing on an Android Emulator
  final String _tileServerUrl = 'http://127.0.0.1:8081/morocco_vector/{z}/{x}/{y}.mvt';

  @override
  void initState() {
    super.initState();
    _loadVectorStyle();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadVectorStyle() async {
    try {
      final styleString = await rootBundle.loadString('assets/map_style.json');
      final styleJson = jsonDecode(styleString);
      final theme = vtr.ThemeReader().read(styleJson);
      
      setState(() {
        _mapTheme = theme;
      });
    } catch (e) {
      debugPrint("Could not find or parse map_style.json. Falling back to inline JSON. Error: $e");
      
      final fallbackThemeData = {
        "version": 8,
        "name": "Emergency Fallback",
        "sources": {"openmaptiles": {"type": "vector"}},
        "layers": [
          {
            "id": "background",
            "type": "background",
            "paint": {"background-color": "#F7F8FA"}
          },
          {
            "id": "roads",
            "type": "line",
            "source": "openmaptiles",
            "source-layer": "transportation",
            "paint": {"line-color": "#B0BEC5", "line-width": 2}
          }
        ]
      };
      
      final emergencyTheme = vtr.ThemeReader(logger: const vtr.Logger.console())
          .read(fallbackThemeData);

      setState(() {
        _mapTheme = emergencyTheme;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      // 1. Fetch current profile to get driver ID
      final response = await ApiClient().get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _driverId = response.data['id'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching driver profile: $e");
    }

    // 2. Request GPS permissions and locate driver
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      setState(() { _isLoadingLoc = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        setState(() { _isLoadingLoc = false; });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      setState(() { _isLoadingLoc = false; });
      return;
    }

    // Fetch initial location
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng initialLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = initialLatLng;
        _isLoadingLoc = false;
      });
      _mapController.move(initialLatLng, 15.0);
      _sendLocationToBackend(position);
    } catch (e) {
      debugPrint("Error getting initial GPS position: $e");
      setState(() { _isLoadingLoc = false; });
    }

    // Subscribe to continuous GPS changes
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Trigger update when moving at least 10 meters
      ),
    ).listen((Position position) {
      LatLng newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newLatLng;
      });
      _sendLocationToBackend(position);
    });
  }

  Future<void> _sendLocationToBackend(Position position) async {
    if (_driverId == null) return;
    try {
      await ApiClient().put(
        '/drivers/$_driverId/location',
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );
      debugPrint("Driver GPS position synced to backend: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("Failed to sync driver GPS location to backend: $e");
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _deliveries.add(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mapTheme == null || (_isLoadingLoc && _currentPosition == null)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 16),
              Text(
                "Loading map and GPS position...",
                style: TextStyle(fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition ?? const LatLng(33.58717, -7.61353), 
          initialZoom: 15.0,
          maxZoom: 19.0,
          onTap: _handleMapTap,
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
          MarkerLayer(
            markers: [
              if (_currentPosition != null)
                Marker(
                  point: _currentPosition!,
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ..._deliveries.map((delivery) => Marker(
                point: delivery,
                width: 60,
                height: 60,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_shipping, 
                  color: Colors.black87, 
                  size: 30,
                ),
              )).toList(),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0), 
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: Colors.black),
          onPressed: () {
            if (_currentPosition != null) {
              _mapController.move(_currentPosition!, 15.0);
            } else {
              _mapController.move(const LatLng(33.58717, -7.61353), 14.0);
            }
          },
        ),
      ),
    );
  }
}