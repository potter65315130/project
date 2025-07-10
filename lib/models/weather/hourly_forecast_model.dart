class HourlyForecast {
  final DateTime dateTime;
  final double temp;
  final String weather;
  final int rainChance;

  HourlyForecast({
    required this.dateTime,
    required this.temp,
    required this.weather,
    required this.rainChance,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temp: json['main']['temp'].toDouble(),
      weather: json['weather'][0]['description'],
      rainChance: (json['pop'] * 100).toInt(),
    );
  }
}
