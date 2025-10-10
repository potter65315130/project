import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

enum TrackingState { idle, countdown, running, paused, finished }

class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;
  TrackingState _state = TrackingState.idle;
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  Timer? _countdownTimer;
  int _countdown = 3;

  final List<LatLng> _routePoints = [];
  double _distance = 0.0;
  Duration _duration = Duration.zero;
  double _caloriesBurned = 0.0;
  double _currentSpeed = 0.0; // km/h
  double _avgSpeed = 0.0; // km/h

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetPosition();
  }

  Future<void> _checkLocationPermissionAndGetPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showOpenSettingsDialog();
      return;
    }

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

  void _startCountdown() {
    if (_currentPosition == null) {
      _showErrorDialog('ยังไม่พบตำแหน่งปัจจุบัน โปรดรอสักครู่');
      return;
    }

    setState(() {
      _state = TrackingState.countdown;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _startTracking();
      }
    });
  }

  void _startTracking() {
    setState(() {
      _state = TrackingState.running;
      _routePoints.clear();
      _distance = 0.0;
      _duration = Duration.zero;
      _caloriesBurned = 0.0;
      _currentSpeed = 0.0;
      _avgSpeed = 0.0;

      _routePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    });

    // Timer สำหรับนับเวลา
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _state == TrackingState.running) {
        setState(() {
          _duration += const Duration(seconds: 1);
          // คำนวณความเร็วเฉลี่ย
          if (_duration.inSeconds > 0) {
            _avgSpeed = (_distance / 1000) / (_duration.inSeconds / 3600);
          }
        });
      }
    });

    // Stream สำหรับติดตามตำแหน่ง - ลด distanceFilter เพื่อความแม่นยำมากขึ้น
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // ลดจาก 5 เป็น 2 เมตร
      ),
    ).listen((Position position) {
      if (mounted && _state == TrackingState.running) {
        final newPoint = LatLng(position.latitude, position.longitude);
        final userWeight = context.read<HomeProvider>().user?.weight ?? 70.0;

        setState(() {
          _currentPosition = position;

          if (_routePoints.isNotEmpty) {
            final addedDistance = Geolocator.distanceBetween(
              _routePoints.last.latitude,
              _routePoints.last.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
            _distance += addedDistance;

            // คำนวณความเร็วปัจจุบัน (m/s -> km/h)
            if (position.speed > 0) {
              _currentSpeed = position.speed * 3.6;
            }
          }

          _routePoints.add(newPoint);
          _caloriesBurned = (_distance / 1000) * userWeight * 1.036;
        });

        _mapController.move(newPoint, 17.0);
      }
    });
  }

  void _pauseTracking() {
    _timer?.cancel();
    setState(() {
      _state = TrackingState.paused;
    });
  }

  void _resumeTracking() {
    setState(() {
      _state = TrackingState.running;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _state == TrackingState.running) {
        setState(() {
          _duration += const Duration(seconds: 1);
          if (_duration.inSeconds > 0) {
            _avgSpeed = (_distance / 1000) / (_duration.inSeconds / 3600);
          }
        });
      }
    });
  }

  void _finishTracking() {
    _positionStream?.cancel();
    _timer?.cancel();

    setState(() {
      _state = TrackingState.finished;
    });

    if (_distance > 0) {
      _showSummaryDialog();
    } else {
      _showErrorDialog('ไม่มีข้อมูลการวิ่ง กรุณาลองอีกครั้ง');
      _resetTracking();
    }
  }

  void _resetTracking() {
    _positionStream?.cancel();
    _timer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _state = TrackingState.idle;
      _routePoints.clear();
      _distance = 0.0;
      _duration = Duration.zero;
      _caloriesBurned = 0.0;
      _currentSpeed = 0.0;
      _avgSpeed = 0.0;
    });
  }

  Future<void> _showSummaryDialog() async {
    final pace =
        _duration.inSeconds > 0
            ? (_duration.inSeconds / 60) / (_distance / 1000)
            : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('สรุปการวิ่ง'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    Icons.straighten,
                    'ระยะทาง',
                    '${(_distance / 1000).toStringAsFixed(2)} กม.',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.timer,
                    'เวลา',
                    _formatDuration(_duration),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.speed,
                    'ความเร็วเฉลี่ย',
                    '${_avgSpeed.toStringAsFixed(1)} กม./ชม.',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.trending_up,
                    'Pace',
                    '${pace.toStringAsFixed(1)} นาที/กม.',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.local_fire_department,
                    'เผาผลาญ',
                    '${_caloriesBurned.toInt()} kcal',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetTracking();
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton.icon(
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
                icon: const Icon(Icons.save),
                label: const Text('บันทึก'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
    _countdownTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามการวิ่ง'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ส่วนแสดงผลข้อมูล
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // แถวแรก: ระยะทาง และ เวลา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'ระยะทาง',
                      '${(_distance / 1000).toStringAsFixed(2)}',
                      'กม.',
                      Icons.straighten,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'เวลา',
                      _formatDuration(_duration),
                      '',
                      Icons.timer,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // แถวสอง: ความเร็ว และ แคลอรี่
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'ความเร็ว',
                      _currentSpeed.toStringAsFixed(1),
                      'กม./ชม.',
                      Icons.speed,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'เผาผลาญ',
                      '${_caloriesBurned.toInt()}',
                      'kcal',
                      Icons.local_fire_department,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ส่วนแผนที่
          Expanded(
            child: Stack(
              children: [
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
                        if (_routePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue,
                                strokeWidth: 6,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // จุดเริ่มต้น
                            if (_routePoints.isNotEmpty)
                              Marker(
                                point: _routePoints.first,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            // ตำแหน่งปัจจุบัน
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                // Countdown overlay
                if (_state == TrackingState.countdown)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_countdown',
                            style: const TextStyle(
                              fontSize: 120,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'เตรียมพร้อม...',
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildControlButtons(),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 2),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(child: _buildButtonsForState()),
    );
  }

  Widget _buildButtonsForState() {
    switch (_state) {
      case TrackingState.idle:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startCountdown,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('เริ่มวิ่ง', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case TrackingState.countdown:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              _countdownTimer?.cancel();
              _resetTracking();
            },
            icon: const Icon(Icons.close, size: 28),
            label: const Text('ยกเลิก', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case TrackingState.running:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _pauseTracking,
                  icon: const Icon(Icons.pause, size: 28),
                  label: const Text('หยุด', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _finishTracking,
                  icon: const Icon(Icons.stop, size: 28),
                  label: const Text(
                    'เสร็จสิ้น',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case TrackingState.paused:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _resumeTracking,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'ดำเนินต่อ',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _finishTracking,
                  icon: const Icon(Icons.stop, size: 28),
                  label: const Text(
                    'เสร็จสิ้น',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case TrackingState.finished:
        return const SizedBox.shrink();
    }
  }
}
