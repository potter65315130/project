import 'package:flutter/material.dart';
import 'package:health_mate/models/weather/daily_forecast_model.dart';
import 'package:health_mate/models/weather/exercise_recommendation_model.dart';
import 'package:health_mate/models/weather/hourly_forecast_model.dart';
import 'package:health_mate/models/weather/weather_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData? weatherData;
  List<HourlyForecast> hourlyForecast = [];
  List<DailyForecast> dailyForecast = [];
  bool isLoading = true;
  String error = '';
  Timer? _refreshTimer;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadWeatherData();
    // Auto refresh every 30 minutes
    _refreshTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _loadWeatherData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      // Request location permission
      var permission = await Permission.location.request();
      if (permission.isDenied) {
        setState(() {
          error = 'กรุณาอนุญาตการเข้าถึงตำแหน่งเพื่อดูสภาพอากาศ';
          isLoading = false;
        });
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch weather data
      await _fetchWeatherData(position.latitude, position.longitude);

      // Check for weather alerts
      _checkWeatherAlerts();
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาด: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    const String apiKey = '914ab84766cca6dfcc374f5eadf728ff';
    const String baseUrl = 'https://api.openweathermap.org/data/2.5';

    try {
      // Current weather
      final currentResponse = await http.get(
        Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=th',
        ),
      );

      // 5-day forecast
      final forecastResponse = await http.get(
        Uri.parse(
          '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=th',
        ),
      );

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          weatherData = WeatherData.fromJson(currentData);
          hourlyForecast = _parseHourlyForecast(forecastData);
          dailyForecast = _parseDailyForecast(forecastData);
          isLoading = false;
        });
      } else {
        throw Exception('ไม่สามารถดึงข้อมูลสภาพอากาศได้');
      }
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาดในการดึงข้อมูล: $e';
        isLoading = false;
      });
    }
  }

  List<HourlyForecast> _parseHourlyForecast(Map<String, dynamic> data) {
    List<HourlyForecast> forecasts = [];
    for (var item in data['list'].take(8)) {
      forecasts.add(HourlyForecast.fromJson(item));
    }
    return forecasts;
  }

  List<DailyForecast> _parseDailyForecast(Map<String, dynamic> data) {
    Map<String, List<Map<String, dynamic>>> dailyGroups = {};

    for (var item in data['list']) {
      String date =
          DateTime.fromMillisecondsSinceEpoch(
            item['dt'] * 1000,
          ).toIso8601String().split('T')[0];

      if (!dailyGroups.containsKey(date)) {
        dailyGroups[date] = [];
      }
      dailyGroups[date]!.add(item);
    }

    List<DailyForecast> forecasts = [];
    dailyGroups.forEach((date, items) {
      forecasts.add(DailyForecast.fromDailyItems(items));
    });

    return forecasts.take(5).toList();
  }

  void _checkWeatherAlerts() {
    if (weatherData == null) return;

    // Check for rain in next 2 hours
    var nextRainTime = _getNextRainTime();
    if (nextRainTime != null) {
      _showNotification(
        'แจ้งเตือนฝนจะตก',
        'ฝนจะตกในอีก ${nextRainTime.difference(DateTime.now()).inHours} ชั่วโมง ไม่ควรออกกำลังกายกลางแจ้ง',
      );
    }

    // Check extreme weather conditions
    if (weatherData!.temp > 35) {
      _showNotification(
        'อากาศร้อนมาก',
        'อุณหภูมิ ${weatherData!.temp.toInt()}°C ควรออกกำลังกายในร่มหรือเลื่อนเป็นช่วงเย็น',
      );
    }
  }

  DateTime? _getNextRainTime() {
    for (var forecast in hourlyForecast) {
      if (forecast.weather.contains('rain') ||
          forecast.weather.contains('ฝน')) {
        return forecast.dateTime;
      }
    }
    return null;
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'weather_channel',
          'Weather Notifications',
          channelDescription: 'Notifications for weather alerts',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สภาพอากาศ'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadWeatherData),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(error, textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadWeatherData,
                      child: Text('ลองใหม่'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCurrentWeatherCard(),
                    _buildExerciseRecommendation(),
                    _buildHourlyForecast(),
                    _buildTemperatureChart(),
                    _buildDailyForecast(),
                  ],
                ),
              ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weatherData!.location,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${weatherData!.temp.toInt()}°C',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(weatherData!.weather, style: TextStyle(fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    Icon(_getWeatherIcon(weatherData!.weather), size: 64),
                    SizedBox(height: 8),
                    Text('รู้สึกเหมือน ${weatherData!.feelsLike.toInt()}°C'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  'สูงสุด',
                  '${weatherData!.maxTemp.toInt()}°C',
                ),
                _buildWeatherInfo(
                  'ต่ำสุด',
                  '${weatherData!.minTemp.toInt()}°C',
                ),
                _buildWeatherInfo('ความชื้น', '${weatherData!.humidity}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExerciseRecommendation() {
    ExerciseRecommendation recommendation = _getExerciseRecommendation();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'คำแนะนำการออกกำลังกาย',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: recommendation.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: recommendation.color),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: recommendation.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(recommendation.description),
                  if (recommendation.rainWarning.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      recommendation.rainWarning,
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พยากรณ์รายชั่วโมง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hourlyForecast.length,
                itemBuilder: (context, index) {
                  final forecast = hourlyForecast[index];
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          '${forecast.dateTime.hour}:00',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Icon(_getWeatherIcon(forecast.weather), size: 32),
                        SizedBox(height: 8),
                        Text(
                          '${forecast.temp.toInt()}°C',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${forecast.rainChance}%',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กราฟอุณหภูมิ 24 ชั่วโมง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < hourlyForecast.length) {
                            return Text(
                              '${hourlyForecast[value.toInt()].dateTime.hour}h',
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          hourlyForecast.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.temp,
                            );
                          }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildDailyForecast() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พยากรณ์ 5 วัน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...dailyForecast.map(
              (forecast) => _buildDailyForecastItem(forecast),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecastItem(DailyForecast forecast) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(forecast.dateTime),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Icon(_getWeatherIcon(forecast.weather), size: 24)),
          Expanded(
            flex: 2,
            child: Text(
              '${forecast.maxTemp.toInt()}°/${forecast.minTemp.toInt()}°',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) return 'วันนี้';
    if (difference == 1) return 'พรุ่งนี้';

    const days = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];
    return days[dateTime.weekday % 7];
  }

  IconData _getWeatherIcon(String weather) {
    if (weather.contains('ฝน') || weather.contains('rain')) {
      return Icons.umbrella;
    } else if (weather.contains('เมฆ') || weather.contains('cloud')) {
      return Icons.cloud;
    } else if (weather.contains('แสง') ||
        weather.contains('sun') ||
        weather.contains('clear')) {
      return Icons.wb_sunny;
    } else if (weather.contains('หิมะ') || weather.contains('snow')) {
      return Icons.ac_unit;
    } else if (weather.contains('ฟ้าร้อง') || weather.contains('thunder')) {
      return Icons.flash_on;
    }
    return Icons.wb_sunny;
  }

  ExerciseRecommendation _getExerciseRecommendation() {
    if (weatherData == null) {
      return ExerciseRecommendation(
        title: 'ไม่มีข้อมูล',
        description: 'ไม่สามารถให้คำแนะนำได้',
        color: Colors.grey,
      );
    }

    final temp = weatherData!.temp;
    final weather = weatherData!.weather;
    var nextRainTime = _getNextRainTime();

    // Check for rain conditions
    if (weather.contains('ฝน') || weather.contains('rain')) {
      return ExerciseRecommendation(
        title: 'ไม่แนะนำออกกำลังกายกลางแจ้ง',
        description: 'ขณะนี้มีฝนตก ควรออกกำลังกายในร่มหรือรอจนกว่าฝนจะหยุด',
        color: Colors.red,
      );
    }

    // Check for upcoming rain
    String rainWarning = '';
    if (nextRainTime != null) {
      final hoursUntilRain = nextRainTime.difference(DateTime.now()).inHours;
      if (hoursUntilRain <= 2) {
        rainWarning = 'คำเตือน: ฝนจะตกในอีก $hoursUntilRain ชั่วโมง';
      }
    }

    // Temperature-based recommendations
    if (temp > 35) {
      return ExerciseRecommendation(
        title: 'อากาศร้อนมาก - ควรออกกำลังกายในร่ม',
        description:
            'อุณหภูมิสูงมาก ควรเลือกยิมหรือสถานที่ที่มีแอร์ หรือเลื่อนเป็นช่วงเย็น',
        color: Colors.red,
        rainWarning: rainWarning,
      );
    } else if (temp > 28) {
      return ExerciseRecommendation(
        title: 'อากาศค่อนข้างร้อน - ระวังให้ดี',
        description:
            'สามารถออกกำลังกายกลางแจ้งได้ แต่ควรดื่มน้ำเยอะๆ และหลีกเลี่ยงช่วงแสงแดดจัด',
        color: Colors.orange,
        rainWarning: rainWarning,
      );
    } else if (temp > 18) {
      return ExerciseRecommendation(
        title: 'อากาศเหมาะสำหรับออกกำลังกาย',
        description: 'อุณหภูมิเหมาะสม เหมาะสำหรับการออกกำลังกายกลางแจ้ง',
        color: Colors.green,
        rainWarning: rainWarning,
      );
    } else {
      return ExerciseRecommendation(
        title: 'อากาศเย็น - ควรอุ่นเครื่องก่อน',
        description: 'อุณหภูมิค่อนข้างเย็น ควรอุ่นเครื่องให้ดีก่อนออกกำลังกาย',
        color: Colors.blue,
        rainWarning: rainWarning,
      );
    }
  }
}
