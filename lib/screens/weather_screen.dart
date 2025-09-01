import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // 👉 ใส่ API Key ของคุณที่นี่
  final String apiKey = '45d46ce30f18652988cfaf26b76687ce';

  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  // ฟังก์ชันแนะนำการออกกำลังกาย
  Map<String, dynamic> getExerciseRecommendation() {
    if (weatherData == null) return {'icon': '🤷‍♂️', 'title': 'ไม่มีข้อมูล', 'description': '', 'color': Colors.grey};

    double temp = (weatherData!['main']['temp'] as num).toDouble();
    double humidity = (weatherData!['main']['humidity'] as num).toDouble();
    String weatherMain = weatherData!['weather'][0]['main'].toLowerCase();

    // เช็คสภาพอากาศแล้วแนะนำ
    if (weatherMain.contains('rain') || weatherMain.contains('storm')) {
      return {
        'icon': '🏠',
        'title': 'ออกกำลังกายในร้ม',
        'description': 'วันนี้ฝนตก แนะนำ: โยคะ ยืดเส้นยืดสาย หรือออกกำลังกายในร่ม',
        'color': const Color(0xFF64B5F6),
        'level': 'medium'
      };
    }

    if (temp > 35) {
      return {
        'icon': '🥵',
        'title': 'อากาศร้อนจัด - หลีกเลี่ยง',
        'description': 'อุณหภูมิสูงมาก แนะนำ: พักผ่อน ดื่มน้ำเยอะๆ หรือออกกำลังกายในแอร์',
        'color': const Color(0xFFEF5350),
        'level': 'low'
      };
    }

    if (temp < 15) {
      return {
        'icon': '🥶',
        'title': 'อากาศเย็น - ระวังตัว',
        'description': 'อุณหภูมิต่ำ แนะนำ: วอร์มอัพนานๆ ใส่เสื้อกันหนาว วิ่งเบาๆ',
        'color': const Color(0xFF42A5F5),
        'level': 'medium'
      };
    }

    if (humidity > 80) {
      return {
        'icon': '💦',
        'title': 'อากาศชื้น - ออกกำลังกายเบาๆ',
        'description': 'ความชื้นสูง แนะนำ: เดิน จ๊อกกิ้งเบาๆ ดื่มน้ำบ่อยๆ หลีกเลี่ยงออกแรงหนัก',
        'color': const Color(0xFF4DB6AC),
        'level': 'medium'
      };
    }

    if (temp >= 20 && temp <= 28 && humidity < 70) {
      return {
        'icon': '🏃‍♂️',
        'title': 'สภาพอากาศเหมาะมาก!',
        'description': 'วันนี้เหมาะออกกำลังกาย: วิ่ง ปั่นจักรยาน ฟุตบอล หรือกีฬากลางแจ้ง',
        'color': const Color(0xFF66BB6A),
        'level': 'high'
      };
    }

    if (temp >= 15 && temp < 32) {
      return {
        'icon': '🚶‍♂️',
        'title': 'เหมาะออกกำลังกายปานกลาง',
        'description': 'สภาพอากาศดี แนะนำ: เดิน จ๊อกกิ้ง โยคะกลางแจ้ง หรือขี่จักรยาน',
        'color': const Color(0xFFFFB74D),
        'level': 'medium'
      };
    }

    return {
      'icon': '🤔',
      'title': 'พิจารณาด้วยตัวเอง',
      'description': 'สภาพอากาศปกติ ดูอาการร่างกายแล้วตัดสินใจเอง',
      'color': const Color(0xFFBDBDBD),
      'level': 'medium'
    };
  }

  Color getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    if (temp < 35) return Colors.red;
    return Colors.red;
  }

  String getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'drizzle': return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow': return '❄️';
      case 'mist':
      case 'fog': return '🌫️';
      default: return '🌤️';
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // ✅ ขอสิทธิ์ Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = "❌ ไม่ได้รับสิทธิ์ใช้ Location";
            isLoading = false;
          });
          return;
        }
      }

      // ✅ เอาพิกัด latitude, longitude
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // ✅ เรียก API OpenWeatherMap
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=th",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          weatherData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "โหลดข้อมูลล้มเหลว: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = getExerciseRecommendation();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "สภาพอากาศ & การออกกำลังกาย",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("กำลังโหลดข้อมูล...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Color(0xFFEF5350)),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadWeatherData,
                        icon: const Icon(Icons.refresh),
                        label: const Text("ลองอีกครั้ง"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : weatherData != null
                  ? RefreshIndicator(
                      onRefresh: _loadWeatherData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // การ์ดสภาพอากาศ
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          weatherData!['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getWeatherIcon(weatherData!['weather'][0]['main']),
                                        style: const TextStyle(fontSize: 48),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${(weatherData!['main']['temp'] as num).round()}°C",
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            weatherData!['weather'][0]['description'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // รายละเอียดสภาพอากาศ
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "รายละเอียด",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildWeatherDetail(
                                          "🌡️", "รู้สึกเหมือน", 
                                          "${(weatherData!['main']['feels_like'] as num).round()}°C"
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildWeatherDetail(
                                          "💧", "ความชื้น", 
                                          "${(weatherData!['main']['humidity'] as num).round()}%"
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildWeatherDetail(
                                          "💨", "ลม", 
                                          "${(weatherData!['wind']?['speed'] ?? 0).toStringAsFixed(1)} m/s"
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildWeatherDetail(
                                          "👁️", "ทัศนวิสัย", 
                                          "${((weatherData!['visibility'] ?? 0) / 1000).toStringAsFixed(1)} กม."
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // การ์ดแนะนำการออกกำลังกาย
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: recommendation['color'],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    recommendation['icon'],
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    recommendation['title'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recommendation['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      recommendation['level'] == 'high' ? "แนะนำสูง" :
                                      recommendation['level'] == 'medium' ? "แนะนำปานกลาง" : "ไม่แนะนำ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ปุ่มรีเฟรช
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _loadWeatherData,
                                icon: const Icon(Icons.refresh),
                                label: const Text(
                                  "รีเฟรชข้อมูล",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            
                            Text(
                              "ดึงข้อมูลเมื่อ: ${DateTime.now().toString().substring(0, 16)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(child: Text("ไม่มีข้อมูล")),
    );
  }

  Widget _buildWeatherDetail(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}