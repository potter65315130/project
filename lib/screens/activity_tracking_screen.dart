import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/screens/history/running_history_screen.dart';
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
  double _currentSpeed = 0.0;
  double _avgSpeed = 0.0;

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
      _showErrorDialog('ยังไม่พบตำแหน่งปัจจุบัน โปรดรออักครั้ง');
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

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
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
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDFF00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1A1A1A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สรุปการวิ่ง',
                  style: TextStyle(
                    color: Color(0xFFCDFF00),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
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
                  const Divider(color: Color(0xFF333333)),
                  _buildSummaryRow(
                    Icons.timer,
                    'เวลา',
                    _formatDuration(_duration),
                  ),
                  const Divider(color: Color(0xFF333333)),
                  _buildSummaryRow(
                    Icons.speed,
                    'ความเร็วเฉลี่ย',
                    '${_avgSpeed.toStringAsFixed(1)} กม./ชม.',
                  ),
                  const Divider(color: Color(0xFF333333)),
                  _buildSummaryRow(
                    Icons.trending_up,
                    'Pace',
                    '${pace.toStringAsFixed(1)} นาที/กม.',
                  ),
                  const Divider(color: Color(0xFF333333)),
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
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.save, size: 20),
                label: const Text('บันทึก', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCDFF00),
                  foregroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFCDFF00),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCDFF00),
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
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "เปิด GPS",
              style: TextStyle(
                color: Color(0xFFCDFF00),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "แอปนี้ต้องใช้ GPS ในการติดตามการวิ่งของคุณ",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(color: Color(0xFFCDFF00)),
                ),
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
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "การอนุญาตถูกปฏิเสธ",
              style: TextStyle(
                color: Color(0xFFCDFF00),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "แอปต้องการสิทธิ์การเข้าถึงตำแหน่งเพื่อทำงาน",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(color: Color(0xFFCDFF00)),
                ),
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
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "สิทธิ์ถูกปฏิเสธอย่างถาวร",
              style: TextStyle(
                color: Color(0xFFCDFF00),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "กรุณาเปิดสิทธิ์จากหน้าต้นของระบบ",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text(
                  "ไปยังการตั้งค่า",
                  style: TextStyle(color: Color(0xFFCDFF00)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ยกเลิก",
                  style: TextStyle(color: Colors.grey),
                ),
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
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: Color(0xFFCDFF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(color: Color(0xFFCDFF00)),
                  ),
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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'ติดตามการวิ่ง',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFCDFF00),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติการวิ่ง',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RunningHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'ระยะทาง',
                      (_distance / 1000).toStringAsFixed(2),
                      'กม.',
                      Icons.straighten,
                      const Color(0xFFCDFF00),
                    ),
                    _buildStatCard(
                      'เวลา',
                      _formatDuration(_duration),
                      '',
                      Icons.timer,
                      const Color(0xFFCDFF00),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'ความเร็ว',
                      _currentSpeed.toStringAsFixed(1),
                      'กม./ชม.',
                      Icons.speed,
                      const Color(0xFFCDFF00),
                    ),
                    _buildStatCard(
                      'เผาผลาญ',
                      '${_caloriesBurned.toInt()}',
                      'kcal',
                      Icons.local_fire_department,
                      const Color(0xFFCDFF00),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _currentPosition == null
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFCDFF00),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'กำลังค้นหาตำแหน่ง...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
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
                                color: const Color(0xFFCDFF00),
                                strokeWidth: 6,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_routePoints.isNotEmpty)
                              Marker(
                                point: _routePoints.first,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCDFF00),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFCDFF00,
                                        ).withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Color(0xFF1A1A1A),
                                    size: 24,
                                  ),
                                ),
                              ),
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCDFF00),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFCDFF00,
                                      ).withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Color(0xFF1A1A1A),
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                if (_state == TrackingState.countdown)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_countdown',
                            style: const TextStyle(
                              fontSize: 120,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCDFF00),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'เตรียมพร้อม...',
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(0xFFCDFF00),
                              fontWeight: FontWeight.w600,
                            ),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 3, bottom: 2),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
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
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
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
            label: const Text(
              'เริ่มวิ่ง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCDFF00),
              foregroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
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
            label: const Text(
              'ยกเลิก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
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
                  label: const Text(
                    'หยุด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCDFF00),
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
