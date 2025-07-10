class WeatherData {
  final String location;
  final double temp;
  final double feelsLike;
  final double maxTemp;
  final double minTemp;
  final String weather;
  final int humidity;

  WeatherData({
    required this.location,
    required this.temp,
    required this.feelsLike,
    required this.maxTemp,
    required this.minTemp,
    required this.weather,
    required this.humidity,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['name'],
      temp: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      maxTemp: json['main']['temp_max'].toDouble(),
      minTemp: json['main']['temp_min'].toDouble(),
      weather: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
    );
  }
}
