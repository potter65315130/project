import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;

  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  final List<LatLng> _routePoints = [];
  double _distance = 0.0;
  Duration _duration = Duration.zero;
  double _caloriesBurned = 0.0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetPosition();
  }

  Future<void> _checkLocationPermissionAndGetPosition() async {
    // 1. ตรวจสอบว่าเปิด GPS (Location Services) หรือยัง
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    // 2. ตรวจสอบสิทธิ์ที่ผู้ใช้ให้
    LocationPermission permission = await Geolocator.checkPermission();

    // ถ้ายังไม่ได้ขอ หรือถูกปฏิเสธ
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    // ถ้าผู้ใช้ปฏิเสธถาวร
    if (permission == LocationPermission.deniedForever) {
      _showOpenSettingsDialog();
      return;
    }

    // 3. ดึงตำแหน่งเมื่อได้สิทธิ์
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      if (kDebugMode) {
        print("ตำแหน่งปัจจุบัน: $_currentPosition");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting position: $e");
      }
      if (mounted) {
        _showErrorDialog("ไม่สามารถหาตำแหน่งได้: $e");
      }
    }
  }

  void _startTracking() {
    if (_currentPosition == null) {
      _showErrorDialog('ยังไม่พบตำแหน่งปัจจุบัน โปรดรอสักครู่');
      return;
    }

    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _distance = 0.0;
      _duration = Duration.zero;
      _caloriesBurned = 0.0;

      // เพิ่มตำแหน่งปัจจุบันเป็นจุดเริ่มต้น
      _routePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    });

    // Timer สำหรับนับเวลา
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      }
    });

    // Stream สำหรับติดตามตำแหน่ง
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        final newPoint = LatLng(position.latitude, position.longitude);
        final userWeight = context.read<HomeProvider>().user?.weight ?? 70.0;

        setState(() {
          _currentPosition = position;

          if (_routePoints.isNotEmpty) {
            _distance += Geolocator.distanceBetween(
              _routePoints.last.latitude,
              _routePoints.last.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
          }

          _routePoints.add(newPoint);
          _caloriesBurned = (_distance / 1000) * userWeight * 1.036;
        });

        // เลื่อนแผนที่ตามตำแหน่งใหม่
        _mapController.move(newPoint, 17.0);
      }
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _timer?.cancel();

    setState(() {
      _isTracking = false;
    });

    if (_distance > 0) {
      _showSaveDialog();
    }
  }

  Future<void> _showSaveDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('บันทึกการออกกำลังกาย'),
            content: Text(
              'ระยะทาง: ${(_distance / 1000).toStringAsFixed(2)} กม.\n'
              'เวลา: ${_formatDuration(_duration)}\n'
              'เผาผลาญ: ${_caloriesBurned.toInt()} kcal\n\n'
              'คุณต้องการบันทึกหรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final session = RunningSessionModel(
                    distance: _distance,
                    durationSeconds: _duration.inSeconds,
                    caloriesBurned: _caloriesBurned,
                    timestamp: DateTime.now(),
                  );
                  await context.read<HomeProvider>().logActivity(session);
                  if (mounted) {
                    Navigator.of(context).pop(); // ปิด Dialog
                    Navigator.of(context).pop(); // กลับหน้า Home
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("กรุณาเปิด GPS"),
            content: const Text("แอปนี้ต้องใช้ GPS ในการติดตามกิจกรรมของคุณ"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง"),
              ),
            ],
          ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("การอนุญาตถูกปฏิเสธ"),
            content: const Text("แอปต้องการสิทธิ์การเข้าถึงตำแหน่งเพื่อทำงาน"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง"),
              ),
            ],
          ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("สิทธิ์ถูกปฏิเสธถาวร"),
            content: const Text("กรุณาเปิดสิทธิ์จากหน้าตั้งค่าของระบบ"),
            actions: [
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text("ไปยังการตั้งค่า"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ยกเลิก"),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามการออกกำลังกาย')),
      body: Column(
        children: [
          // ส่วนแสดงผลข้อมูล
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(
                  'ระยะทาง',
                  '${(_distance / 1000).toStringAsFixed(2)} กม.',
                ),
                _buildInfoCard('เวลา', _formatDuration(_duration)),
                _buildInfoCard('เผาผลาญ', '${_caloriesBurned.toInt()} kcal'),
              ],
            ),
          ),
          // ส่วนแผนที่
          Expanded(
            child:
                _currentPosition == null
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังค้นหาตำแหน่ง...'),
                        ],
                      ),
                    )
                    : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        initialZoom: 17.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.health_mate',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue,
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.run_circle,
                                color: Colors.blueAccent,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        label: Text(_isTracking ? 'หยุด' : 'เริ่มวิ่ง'),
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
        backgroundColor: _isTracking ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
