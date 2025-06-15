// lib/main.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:weatherapp/rent_form_with_whatsapp.dart'; // Ensure this path is correct if used
import 'package:weatherapp/maps_screen.dart'; // Import the new MapsScreen

const String apiKey = "2d22ad9b37d0e688b9f1965cbcb0bc4d";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zgqhfzjedwwxnvvqnnre.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpncWhmemplZHd3eG52dnFubnJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzNjc2NjUsImV4cCI6MjA2NDk0MzY2NX0.-GLGyaxtxbvRYgyg9GK2qpf4QBINQZm2sBRga8zJoec',
  );
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe Weather',
      theme: ThemeData.dark(),
      home: const WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherData {
  String location;
  double temperature;
  String weatherDescription;
  String weatherIcon;
  double humidity;
  double windSpeed;
  double feelsLike;
  int pressure;
  int visibility;
  int sunrise;
  int sunset;
  List<dynamic> hourlyForecast;

  WeatherData({
    required this.location,
    this.temperature = 0,
    this.weatherDescription = "",
    this.weatherIcon = "",
    this.humidity = 0,
    this.windSpeed = 0,
    this.feelsLike = 0,
    this.pressure = 0,
    this.visibility = 0,
    this.sunrise = 0,
    this.sunset = 0,
    this.hourlyForecast = const [],
  });
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData currentLocation = WeatherData(location: "Mendeteksi lokasi...");
  WeatherData secondLocation = WeatherData(location: "Cari kota");
  TextEditingController _cityController = TextEditingController();
  List<String> citySuggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _removeOverlay();
    _pageController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      _fetchWeather(position.latitude, position.longitude, isCurrentLocation: true);
    } catch (e) {
      setState(() {
        currentLocation.location = "Izin lokasi ditolak";
      });
    }
  }

  Future<void> _fetchCitySuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        citySuggestions = [];
      });
      _removeOverlay();
      return;
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey'); // Corrected '$apiKey' usage
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        citySuggestions = data
            .map<String>((city) => '${city['name']}, ${city['country']}')
            .toList();
      });

      if (citySuggestions.isNotEmpty) {
        _showSuggestionsOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width * 0.9,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            child: Container(
              color: Colors.grey[900],
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: citySuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      citySuggestions[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      _cityController.text = citySuggestions[index].split(',').first;
                      _fetchWeatherByCity(_cityController.text);
                      _removeOverlay();
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _fetchWeatherByCity(String cityName) async {
    final cleanCityName = cityName.split(',').first.trim();

    _removeOverlay();
    setState(() {
      secondLocation.location = "Memuat...";
    });

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cleanCityName&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final forecastUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cleanCityName&appid=$apiKey&units=metric');
      final forecastResponse = await http.get(forecastUrl);

      List<dynamic> forecast = [];
      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        forecast = forecastData['list'].take(6).toList();
      }

      setState(() {
        secondLocation = WeatherData(
          location: data['name'],
          temperature: data['main']['temp'],
          feelsLike: data['main']['feels_like'],
          humidity: data['main']['humidity'].toDouble(),
          windSpeed: data['wind']['speed'].toDouble(),
          pressure: data['main']['pressure'],
          visibility: data['visibility'],
          weatherDescription: data['weather'][0]['description'],
          weatherIcon: data['weather'][0]['icon'],
          sunrise: data['sys']['sunrise'],
          sunset: data['sys']['sunset'],
          hourlyForecast: forecast,
        );
      });
    } else {
      setState(() {
        secondLocation.location = "Kota tidak ditemukan";
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
          currentLocation.location = data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              data['address']['state'] ??
              "Lokasi tidak diketahui";
        });
      } else {
        setState(() {
          currentLocation.location = "Lokasi tidak diketahui";
        });
      }
    } catch (e) {
      setState(() {
        currentLocation.location = "Lokasi tidak diketahui";
      });
    }
  }

  Future<void> _fetchWeather(double lat, double lon, {bool isCurrentLocation = true}) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";
    final forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey"; // Corrected '$apiKey' usage

    try {
      final response = await http.get(Uri.parse(url));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (response.statusCode == 200 && forecastResponse.statusCode == 200) {
        final data = jsonDecode(response.body);
        final forecastData = jsonDecode(forecastResponse.body);

        final weather = WeatherData(
          location: currentLocation.location,
          temperature: data['main']['temp'],
          feelsLike: data['main']['feels_like'],
          pressure: data['main']['pressure'],
          humidity: data['main']['humidity'].toDouble(),
          visibility: data['visibility'],
          windSpeed: data['wind']['speed'].toDouble(),
          sunrise: data['sys']['sunrise'],
          sunset: data['sys']['sunset'],
          weatherDescription: data['weather'][0]['description'],
          weatherIcon: data['weather'][0]['icon'],
          hourlyForecast: forecastData['list'].take(6).toList(),
        );

        setState(() {
          if (isCurrentLocation) {
            currentLocation = weather;
          } else {
            secondLocation = weather;
          }
        });
      } else {
        setState(() {
          if (isCurrentLocation) {
            currentLocation.location = "Gagal memuat cuaca";
          } else {
            secondLocation.location = "Gagal memuat cuaca";
          }
        });
      }
    } catch (e) {
      setState(() {
        if (isCurrentLocation) {
          currentLocation.location = "Error memuat cuaca";
        } else {
          secondLocation.location = "Error memuat cuaca";
        }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPage(WeatherData weather, String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weather.location,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "${weather.temperature.toStringAsFixed(1)}°C",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Image.network(
            "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
            height: 80,
            width: 80,
          ),
          Text(
            weather.weatherDescription,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWeatherInfo(
                    FontAwesomeIcons.droplet,
                    "Kelembapan",
                    "${weather.humidity}%",
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.wind,
                    "Kecepatan Angin",
                    "${weather.windSpeed.toStringAsFixed(1)} m/s",
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.temperatureLow,
                    "Terasa Seperti",
                    "${weather.feelsLike.toStringAsFixed(1)}°C",
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.compress,
                    "Tekanan",
                    "${weather.pressure} hPa",
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.eye,
                    "Visibilitas",
                    "${(weather.visibility / 1000).toStringAsFixed(1)} km",
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.sun,
                    "Matahari Terbit",
                    _convertToWIB(weather.sunrise),
                  ),
                  _buildWeatherInfo(
                    FontAwesomeIcons.moon,
                    "Matahari Terbenam",
                    _convertToWIB(weather.sunset),
                  ),
                ],
              ),
            ),
          ),
          if (weather.hourlyForecast.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Prakiraan Per Jam:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weather.hourlyForecast.length,
                itemBuilder: (context, index) {
                  var forecast = weather.hourlyForecast[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          forecast['dt_txt'].split(" ")[1].substring(0, 5),
                          style: const TextStyle(fontSize: 14),
                        ),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.network(
                            "https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}@2x.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          "${forecast['main']['temp'].toStringAsFixed(1)}°C",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'RENT NOW!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Cari kota...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            _fetchCitySuggestions(value);
                          },
                          onTap: () {
                            if (citySuggestions.isNotEmpty) {
                              _showSuggestionsOverlay();
                            }
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _fetchWeatherByCity(value);
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (_cityController.text.isNotEmpty) {
                            _fetchWeatherByCity(_cityController.text);
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.search, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWeatherPage(currentLocation, "Lokasi Saat Ini"),
                    _buildWeatherPage(secondLocation, "Lokasi Tambahan"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}