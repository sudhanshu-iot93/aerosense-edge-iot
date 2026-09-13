// screens/mesh_sync_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/air_quality_state.dart';
import '../services/edge_api_service.dart';
import '../theme/app_theme.dart';

class MeshSyncScreen extends StatefulWidget {
  final AeroSenseState state;

  const MeshSyncScreen({
    super.key,
    required this.state,
  });

  @override
  State<MeshSyncScreen> createState() => _MeshSyncScreenState();
}

class _MeshSyncScreenState extends State<MeshSyncScreen> {
  bool _isCompressing = false;
  bool _isScanningBLE = false;
  CompressionStats? _customCompressionStats;

  Future<void> _runCompressionTest() async {
    setState(() => _isCompressing = true);
    final stats = await EdgeApiService().runCompressionTest();
    setState(() {
      _customCompressionStats = stats;
      _isCompressing = false;
    });
  }

  void _simulateBLEScan() {
    setState(() => _isScanningBLE = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isScanningBLE = false);
        _showConnectionDialog();
      }
    });
  }

  void _showConnectionDialog() {
    final controller = TextEditingController(text: EdgeApiService().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
        ),
        title: Text(
          'BLE Node Configuration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).extension<AeroTheme>()!.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter fallback node IP/Port if BLE fails (e.g. http://localhost:8000, http://10.0.2.2:8000):',
              style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                hintText: 'http://192.168.4.1:8000',
                hintStyle: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              EdgeApiService().baseUrl = controller.text.trim();
              Navigator.pop(ctx);
              EdgeApiService().fetchAndUpdateState();
            },
            child: Text('Sync & Connect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comp = _customCompressionStats ?? widget.state.compressionStats;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BLE Radar Banner
          Container(
            padding: EdgeInsets.all(16),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'OFFLINE BLE RADAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                  ),
                ),
                SizedBox(height: 12),
                if (_isScanningBLE)
                  SpinKitPulse(
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                    size: 60.0,
                  )
                else
                  Icon(Icons.bluetooth_connected, size: 40, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                SizedBox(height: 12),
                Text(
                  _isScanningBLE ? 'Scanning for Arduino UNO Q...' : 'Connected to Node: ${EdgeApiService().baseUrl}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isScanningBLE ? Theme.of(context).extension<AeroTheme>()!.accentCyan : Theme.of(context).extension<AeroTheme>()!.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).extension<AeroTheme>()!.cardHover,
                    foregroundColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isScanningBLE ? null : _simulateBLEScan,
                  icon: Icon(Icons.radar, size: 16),
                  label: Text('Scan & Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Campus / Ward Street Mesh Map Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hub_outlined, size: 20, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                        SizedBox(width: 8),
                        Text(
                          'CAMPUS STREET MESH',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${widget.state.meshTopology.length} Nodes Active',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Decentralized peer-to-peer spatial interpolation across campus zones:',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                ),
                SizedBox(height: 16),

                // Mesh Nodes List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.state.meshTopology.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final node = widget.state.meshTopology[index];
                    final nodeAqiColor = AeroTheme.getAqiColor(node.aqi);

                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: nodeAqiColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.nodeName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${node.nodeId} • ${node.source}',
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${node.aqi} AQI',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: nodeAqiColor,
                                ),
                              ),
                              Text(
                                'Bat ${node.battery}%',
                                style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Offline Resilience & Gorilla Compression Monitor
          Container(
            padding: EdgeInsets.all(20),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compress, size: 20, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                        SizedBox(width: 8),
                        Text(
                          'DELTA-DELTA GORILLA SYNC',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'SQLite WAL Active',
                        style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.accentCyan, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),

                // 4 Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                  children: [
                    _buildSyncStat('Offline Retention', '30 Days', 'Circular on eMMC', Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                    _buildSyncStat('Compression Savings', '${comp.bandwidthSavingsPct}%', 'Payload Reduction', Theme.of(context).extension<AeroTheme>()!.accentCyan),
                    _buildSyncStat('24h Data Packet', '< 42 KB', 'LoRa / BLE Ready', Theme.of(context).extension<AeroTheme>()!.accentIndigo),
                    _buildSyncStat('Cloud API Cost', '\$0.00', 'Zero Monthly Fees', Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                  ],
                ),
                SizedBox(height: 16),

                // Hex Sample Dump Preview
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delta-Compressed Payload (Hex):',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                          ),
                          InkWell(
                            onTap: _isCompressing ? null : _runCompressionTest,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).extension<AeroTheme>()!.cardHover,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isCompressing
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                                    )
                                  : Text(
                                      'Test Compress',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        comp.hexSample.isNotEmpty
                            ? comp.hexSample
                            : 'AE 55 00 1E 66 D5 1C 92 00 00 8E 01 09 01 A2 00 12 00 2D 01 18 0A 34 00 2A 00 FE 43',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSyncStat(String label, String val, String sub, Color valColor) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textSecondary)),
          SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valColor)),
          Text(sub, style: TextStyle(fontSize: 9, color: Theme.of(context).extension<AeroTheme>()!.textMuted)),
        ],
      ),
    );
  }
}
