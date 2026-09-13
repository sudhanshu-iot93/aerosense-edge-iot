// screens/heatmap_screen.dart
// Interactive City & Campus AQI Heatmap powered by flutter_map and latlong2.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapNode {
  final String id;
  final String name;
  final LatLng position;
  final int aqi;
  final double pm25;
  final String dominantSource;
  final String windDirection;
  final double windSpeed;

  const _HeatmapNode({
    required this.id,
    required this.name,
    required this.position,
    required this.aqi,
    required this.pm25,
    required this.dominantSource,
    required this.windDirection,
    required this.windSpeed,
  });
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final MapController _mapController = MapController();

  // Default campus nodes (Rourkela / Industrial Zone)
  final List<_HeatmapNode> _nodes = const [
    _HeatmapNode(
      id: 'node-01',
      name: 'Rourkela Lab & Workshop (Primary Uno Q)',
      position: LatLng(22.2572, 84.9032),
      aqi: 42,
      pm25: 12.4,
      dominantSource: 'Clean Indoor Air',
      windDirection: 'NE',
      windSpeed: 3.2,
    ),
    _HeatmapNode(
      id: 'node-02',
      name: 'Steel Plant Perimeter Gate (Node 02)',
      position: LatLng(22.2680, 84.8910),
      aqi: 172,
      pm25: 88.5,
      dominantSource: 'Industrial Foundry & Smelting',
      windDirection: 'SW',
      windSpeed: 4.8,
    ),
    _HeatmapNode(
      id: 'node-03',
      name: 'Campus Residential Block (Node 03)',
      position: LatLng(22.2490, 84.9120),
      aqi: 35,
      pm25: 9.8,
      dominantSource: 'Vegetation Canopy',
      windDirection: 'E',
      windSpeed: 2.1,
    ),
    _HeatmapNode(
      id: 'node-04',
      name: 'Commercial Kitchen & Canteen (Node 04)',
      position: LatLng(22.2530, 84.9010),
      aqi: 95,
      pm25: 32.1,
      dominantSource: 'Cooking Gas & Biomass',
      windDirection: 'NW',
      windSpeed: 1.5,
    ),
  ];

  _HeatmapNode? _selectedNode;
  LatLng? _userLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selectedNode = _nodes.first;
    _determineUserPosition();
  }

  Future<void> _determineUserPosition() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 4));
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
            _locating = false;
          });
        }
      } else {
        if (mounted) setState(() => _locating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E676);
    if (aqi <= 100) return const Color(0xFFFFD600);
    if (aqi <= 150) return const Color(0xFFFF9100);
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      appBar: AppBar(
        title: const Text('City & Campus AQI Heatmap'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My Location',
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: () async {
              await _determineUserPosition();
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15.0);
              }
            },
          ),
          IconButton(
            tooltip: 'Center Campus',
            icon: const Icon(Icons.center_focus_strong_rounded),
            onPressed: () {
              _mapController.move(const LatLng(22.2572, 84.9032), 14.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(22.2572, 84.9032),
              initialZoom: 13.8,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aerosense.edge',
              ),
              // Heatmap Halos / Radius Circles
              CircleLayer(
                circles: _nodes.map((n) {
                  final color = _getAqiColor(n.aqi);
                  return CircleMarker(
                    point: n.position,
                    color: color.withValues(alpha: 0.18),
                    borderColor: color.withValues(alpha: 0.6),
                    borderStrokeWidth: 1.5,
                    useRadiusInMeter: true,
                    radius: n.aqi > 100 ? 550 : 350,
                  );
                }).toList(),
              ),
              // Marker Layer
              MarkerLayer(
                markers: [
                  ..._nodes.map((node) {
                    final color = _getAqiColor(node.aqi);
                    final isSelected = _selectedNode?.id == node.id;
                    return Marker(
                      point: node.position,
                      width: isSelected ? 64 : 52,
                      height: isSelected ? 64 : 52,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedNode = node);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: isSelected ? 16 : 8,
                                spreadRadius: isSelected ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${node.aqi}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'AQI',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Legend Floating Bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legendItem(const Color(0xFF00E676), 'Good (0-50)'),
                      _legendItem(const Color(0xFFFFD600), 'Moderate (51-100)'),
                      _legendItem(const Color(0xFFFF9100), 'Unhealthy (101-150)'),
                      _legendItem(const Color(0xFFFF1744), 'Hazard (>150)'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Node Inspection Card
          if (_selectedNode != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildNodeDetailsCard(theme, _selectedNode!),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildNodeDetailsCard(AeroTheme theme, _HeatmapNode node) {
    final color = _getAqiColor(node.aqi);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Node ID: ${node.id} • Lat: ${node.position.latitude.toStringAsFixed(4)}, Lon: ${node.position.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 10, color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      'AQI ${node.aqi}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('PM2.5', '${node.pm25.toStringAsFixed(1)} ug/m3', theme),
                  _statItem('Dominant Source', node.dominantSource, theme),
                  _statItem('Wind Vector', '${node.windDirection} @ ${node.windSpeed} m/s', theme),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _statItem(String title, String value, AeroTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: theme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }
}
