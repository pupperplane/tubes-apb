import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String apiKey = "2d22ad9b37d0e688b9f1965cbcb0bc4d";

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData.dark(),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String location = "Fetching location...";
  double temperature = 0;
  String weatherDescription = "";
  String weatherIcon = "";
  double humidity = 0;
  double windSpeed = 0;
  double feelsLike = 0;
  int pressure = 0;
  int visibility = 0;
  int sunrise = 0;
  int sunset = 0;
  List<dynamic> hourlyForecast = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        location = "Location permission denied";
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {
        'User-Agent': 'Flutter Weather App'
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          location = data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              data['address']['state'] ??
              "Unknown location";
        });
      } else {
        setState(() {
          location = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        location = "Unknown location";
      });
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";
    final forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (response.statusCode == 200 && forecastResponse.statusCode == 200) {
        final data = jsonDecode(response.body);
        final forecastData = jsonDecode(forecastResponse.body);

        setState(() {
          temperature = data['main']['temp'];
          feelsLike = data['main']['feels_like'];
          pressure = data['main']['pressure'];
          humidity = data['main']['humidity'].toDouble();
          visibility = data['visibility'];
          windSpeed = data['wind']['speed'].toDouble();
          sunrise = data['sys']['sunrise'];
          sunset = data['sys']['sunset'];
          weatherDescription = data['weather'][0]['description'];
          weatherIcon = data['weather'][0]['icon'];
          hourlyForecast = forecastData['list'].take(6).toList();
        });
      } else {
        setState(() {
          location = "Failed to fetch weather";
        });
      }
    } catch (e) {
      setState(() {
        location = "Error fetching weather";
      });
    }
  }

  String _convertToWIB(int timestamp) {
    DateTime timeUTC = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    DateTime timeWIB = timeUTC.add(const Duration(hours: 7));
    return "${timeWIB.hour.toString().padLeft(2, '0')}:${timeWIB.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text("$label: $value", style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade800, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  location,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${temperature.toStringAsFixed(1)}°C",
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Image.network(
                  "https://openweathermap.org/img/wn/$weatherIcon@2x.png",
                ),
                Text(weatherDescription, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 10),
                Card(
                  color: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeatherInfo(
                          FontAwesomeIcons.droplet,
                          "Humidity",
                          "$humidity%",
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.wind,
                          "Wind Speed",
                          "${windSpeed.toStringAsFixed(1)} m/s",
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.temperatureLow,
                          "Feels Like",
                          "${feelsLike.toStringAsFixed(1)}°C",
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.compress,
                          "Pressure",
                          "$pressure hPa",
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.eye,
                          "Visibility",
                          "${(visibility / 1000).toStringAsFixed(1)} km",
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.sun,
                          "Sunrise",
                          _convertToWIB(sunrise),
                        ),
                        _buildWeatherInfo(
                          FontAwesomeIcons.moon,
                          "Sunset",
                          _convertToWIB(sunset),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: hourlyForecast.length,
                    itemBuilder: (context, index) {
                      var forecast = hourlyForecast[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Text(
                              forecast['dt_txt'].split(" ")[1],
                              style: const TextStyle(fontSize: 16),
                            ),
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: Image.network(
                                "https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}@2x.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              "${forecast['main']['temp'].toStringAsFixed(1)}°C",
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
        ),
      ),
    );
  }
}
