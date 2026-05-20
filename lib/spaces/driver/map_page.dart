import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  
  // Corrected to use Theme instead of Style
  vtr.Theme? _mapTheme;
  
  final List<LatLng> _deliveries = [];

  // Change 127.0.0.1 to 10.0.2.2 if testing on an Android Emulator
  final String _tileServerUrl = 'http://127.0.0.1:8081/morocco_vector/{z}/{x}/{y}.mvt';

  @override
  void initState() {
    super.initState();
    _loadVectorStyle();
  }

  Future<void> _loadVectorStyle() async {
    try {
      // 1. Read the JSON file from your assets
      final styleString = await rootBundle.loadString('assets/map_style.json');
      
      // 2. Decode it into a Dart Map
      final styleJson = jsonDecode(styleString);
      
      // 3. Pass the parsed JSON to ThemeReader
      final theme = vtr.ThemeReader().read(styleJson);
      
      setState(() {
        _mapTheme = theme;
      });
    } catch (e) {
      debugPrint("Could not find or parse map_style.json. Falling back to inline JSON. Error: $e");
      
      // Emergency Fallback if the asset isn't found
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

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _deliveries.add(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mapTheme == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(33.58717, -7.61353), 
          initialZoom: 14.0,
          maxZoom: 19.0,
          onTap: _handleMapTap,
        ),
        children: [
          VectorTileLayer(
            theme: _mapTheme!, // Using the properly loaded Theme
            tileOffset: TileOffset.mapbox, 
            tileProviders: TileProviders({
              'openmaptiles': NetworkVectorTileProvider(
                urlTemplate: _tileServerUrl,
                maximumZoom: 14, 
              ),
            }),
          ),
          MarkerLayer(
            markers: _deliveries.map((delivery) => Marker(
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
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0), 
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: Colors.black),
          onPressed: () {
             _mapController.move(const LatLng(33.58717, -7.61353), 14.0);
          },
        ),
      ),
    );
  }
}