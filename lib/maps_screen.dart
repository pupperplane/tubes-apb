// maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:weatherapp/rent_form_with_whatsapp.dart'; // Import the RentFormPage

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  LatLng _center = LatLng(-6.973413, 107.632296);
  String _pickupLocationName = "Gedung Damar (K), Telkom University";

  String? _googleMapsUrl;

  @override
  void initState() {
    super.initState();
    _updateGoogleMapsUrl(_center);
  }

  void _updateLocation(LatLng latlng) {
    setState(() {
      _center = latlng;
      _pickupLocationName = "Lokasi Pilihan (${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)})";
      _updateGoogleMapsUrl(latlng);
    });
  }

  void _updateGoogleMapsUrl(LatLng latlng) {
    _googleMapsUrl = 'https://maps.google.com/maps?q=${latlng.latitude},${latlng.longitude}';
  }

  // No longer needed to launch URL directly from this screen
  // Future<void> _launchUrl(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (!await launchUrl(uri)) {
  //     throw Exception('Could not launch $uri');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentukan Lokasi Penjemputan Anda (Presentasi)'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: _center,
              zoom: 16.0,
              onTap: (tapPosition, latlng) {
                _updateLocation(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.yourcompany.yourapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 80.0,
                    height: 80.0,
                    builder: (context) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lokasi Penjemputan:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text( // No longer a GestureDetector
                    _pickupLocationName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black, // No longer blue or underlined
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_googleMapsUrl != null) {
                          // Navigate to RentFormPage and pass the pick-up URL
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RentFormPage(pickupLocationUrl: _googleMapsUrl!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL Google Maps tidak tersedia.')),
                          );
                        }
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
            ),
          ),
        ],
      ),
    );
  }
}