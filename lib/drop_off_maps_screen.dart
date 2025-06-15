// drop_off_maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class DropOffMapsScreen extends StatefulWidget {
  const DropOffMapsScreen({super.key});

  @override
  _DropOffMapsScreenState createState() => _DropOffMapsScreenState();
}

class _DropOffMapsScreenState extends State<DropOffMapsScreen> {
  LatLng _center = LatLng(-6.973413, 107.632296); // Default to initial location
  String _dropOffLocationName = "Gedung Damar (K), Telkom University";
  String? _googleMapsUrl;

  @override
  void initState() {
    super.initState();
    _updateGoogleMapsUrl(_center); // Initialize URL
  }

  void _updateLocation(LatLng latlng) {
    setState(() {
      _center = latlng;
      _dropOffLocationName = "Lokasi Pilihan (${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)})";
      _updateGoogleMapsUrl(latlng);
    });
  }

  void _updateGoogleMapsUrl(LatLng latlng) {
    _googleMapsUrl = 'https://maps.google.com/maps?q=${latlng.latitude},${latlng.longitude}';
  }

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
        title: const Text('Tentukan Lokasi Drop Off Anda'),
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
                      color: Colors.blue, // Different color for drop-off
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
                    'Lokasi Drop Off:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dropOffLocationName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _googleMapsUrl); // Pass URL back
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.blue, // Different color button
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'PILIH LOKASI DROP OFF',
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