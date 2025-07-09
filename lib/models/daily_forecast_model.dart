class DailyForecast {
  final DateTime dateTime;
  final double maxTemp;
  final double minTemp;
  final String weather;

  DailyForecast({
    required this.dateTime,
    required this.maxTemp,
    required this.minTemp,
    required this.weather,
  });

  factory DailyForecast.fromDailyItems(List<Map<String, dynamic>> items) {
    double maxTemp = items
        .map((item) => item['main']['temp_max'].toDouble())
        .reduce((a, b) => a > b ? a : b);
    double minTemp = items
        .map((item) => item['main']['temp_min'].toDouble())
        .reduce((a, b) => a < b ? a : b);

    return DailyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(items[0]['dt'] * 1000),
      maxTemp: maxTemp,
      minTemp: minTemp,
      weather: items[0]['weather'][0]['description'],
    );
  }
}
