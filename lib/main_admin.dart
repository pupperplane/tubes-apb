
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weatherapp/drop_off_maps_screen.dart'; 
import 'package:weatherapp/maps_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zgqhfzjedwwxnvvqnnre.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpncWhmemplZHd3eG52dnFubnJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzNjc2NjUsImV4cCI6MjA2NDk0MzY2NX0.-GLGyaxtxbvRYgyg9GK2qpf4QBINQZm2sBRga8zJoec',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Rental Payung',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RentFormPage(),
      debugShowCheckedModeBanner: false, 
    );
  }
}

class RentFormPage extends StatefulWidget {
  final String? pickupLocationUrl; // New: to receive the pick-up URL

  const RentFormPage({Key? key, this.pickupLocationUrl}) : super(key: key);

  @override
  _RentFormPageState createState() => _RentFormPageState();
}

class _RentFormPageState extends State<RentFormPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nowaController = TextEditingController();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropoffController = TextEditingController();
  final TextEditingController durasiController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> rentalList = [];
  List<Map<String, dynamic>> filteredrentalList = [];
  int? selectedId;

  @override
  void initState() {
    super.initState();
    fetchData();
    searchController.addListener(_filterData);

    // Set the initial pick-up location if provided
    if (widget.pickupLocationUrl != null) {
      pickupController.text = widget.pickupLocationUrl!;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    namaController.dispose();
    nowaController.dispose();
    pickupController.dispose();
    dropoffController.dispose();
    durasiController.dispose();
    emailController.dispose();
    statusController.dispose();
    super.dispose();
  }

  void _filterData() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredrentalList = rentalList.where((rental) {
        return rental['Nama'].toString().toLowerCase().contains(query) ||
            rental['Email'].toString().toLowerCase().contains(query) ||
            rental['NoWa'].toString().contains(query) ||
            rental['PickUp'].toString().toLowerCase().contains(query) ||
            rental['DropOff'].toString().toLowerCase().contains(query) ||
            rental['Status'].toString().toLowerCase().contains(query) ||
            rental['Durasi'].toString().contains(query);
      }).toList();
    });
  }

  Future<void> fetchData() async {
    final response = await supabase.from('rental').select();
    setState(() {
      rentalList = List<Map<String, dynamic>>.from(response);
      filteredrentalList = List.from(rentalList);
    });
  }

  Future<void> tambahData() async {
    await supabase.from('rental').insert({
      'Nama': namaController.text,
      'Email': emailController.text,
      'NoWa': int.tryParse(nowaController.text) ?? 0,
      'PickUp': pickupController.text,
      'DropOff': dropoffController.text,
      'Durasi': double.tryParse(durasiController.text) ?? 0.0,
      'Status': "sedang menunggu payung",
    });

    clearFields();
    fetchData();
  }

  Future<void> updateData() async {
    if (selectedId != null) {
      await supabase.from('rental').update({
        'Nama': namaController.text,
        'Email': emailController.text,
        'NoWa': int.tryParse(nowaController.text) ?? 0,
        'PickUp': pickupController.text,
        'DropOff': dropoffController.text,
        'Durasi': double.tryParse(durasiController.text) ?? 0.0,
        'Status': statusController.text,
      }).eq('id', selectedId!);

      clearFields();
      selectedId = null;
      fetchData();
    }
  }

  Future<void> deleteData(int id) async {
    await supabase.from('rental').delete().eq('id', id);
    fetchData();
  }

  void clearFields() {
    namaController.clear();
    emailController.clear();
    nowaController.clear();
    pickupController.clear();
    dropoffController.clear();
    durasiController.clear();
    statusController.clear();
    selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Formulir Rental Payung")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Cari Data Rental",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextField(
                            controller: namaController,
                            decoration: const InputDecoration(labelText: "Nama")),
                        TextField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: "Email")),
                        TextField(
                            controller: nowaController,
                            decoration: const InputDecoration(labelText: "No Wa"),
                            keyboardType: TextInputType.number),
                        // Row for Pick Up with a button to select location
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pickupController,
                                decoration: const InputDecoration(labelText: "Lokasi Pick Up"),
                                readOnly: true, // Make it read-only, but allow selection via button
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () async {
                                final selectedPickupUrl = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MapsScreen(), // Navigate to MapsScreen
                                  ),
                                );
                                if (selectedPickupUrl != null) {
                                  setState(() {
                                    pickupController.text = selectedPickupUrl as String;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        // Row for Drop Off with a button to select location
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dropoffController,
                                decoration: const InputDecoration(labelText: "Lokasi Drop Off"),
                                readOnly: true, // Make it read-only
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () async {
                                final selectedDropOffUrl = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DropOffMapsScreen(),
                                  ),
                                );
                                if (selectedDropOffUrl != null) {
                                  setState(() {
                                    dropoffController.text = selectedDropOffUrl as String;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        TextField(
                            controller: durasiController,
                            decoration: const InputDecoration(labelText: "Durasi (menit)"),
                            keyboardType: TextInputType.number),
                        // Tambahkan TextField untuk Status
                        TextField(
                            controller: statusController,
                            decoration: const InputDecoration(labelText: "Status"),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (selectedId == null) {
                                  String nama = namaController.text;
                                  String email = emailController.text;
                                  String pickup = pickupController.text;
                                  String dropoff = dropoffController.text;
                                  String durasi = durasiController.text;

                                  print('Debug: Nama: $nama, Email: $email, Pickup: $pickup, Durasi: $durasi');

                                  await tambahData();
                                  sendToWhatsApp(
                                    nama: nama,
                                    email: email,
                                    pickup: pickup,
                                    dropoff: dropoff,
                                    durasi: durasi,
                                  );
                                } else {
                                  await updateData();
                                }
                              },
                              child: Text(selectedId == null
                                  ? "Tambah Data"
                                  : "Update Data"),
                            ),
                            if (selectedId != null)
                              ElevatedButton(
                                onPressed: clearFields,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey),
                                child: const Text("Batal"),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredrentalList.length,
              itemBuilder: (context, index) {
                final rental = filteredrentalList[index];
                return Card(
                  child: ListTile(
                    title: Text("${rental['Nama']} - ${rental['Status'] ?? 'Status tidak tersedia'}"),
                    subtitle: Text(
                        "Pick Up: ${rental['PickUp']} | Drop Off: ${rental['DropOff']} | Durasi: ${rental['Durasi']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              selectedId = rental['id'];
                              namaController.text = rental['Nama'];
                              emailController.text = rental['Email'];
                              nowaController.text = rental['NoWa'].toString();
                              pickupController.text = rental['PickUp'];
                              dropoffController.text = rental['DropOff'];
                              durasiController.text = rental['Durasi'].toString();
                              statusController.text = rental['Status'] ?? '';
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteData(rental['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void sendToWhatsApp({
  required String nama,
  required String email,
  required String pickup,
  required String durasi,
  required String dropoff,
}) async {
  final adminWa = '6281282307768'; // admin number
  final message = Uri.encodeFull(
      "Halo, saya ingin melakukan rental.\n"
          "Nama: ${nama}\n"
          "Email: ${email}\n"
          "Lokasi Pick Up: ${pickup}\n"
          "Lokasi Drop Off: ${dropoff}\n"
          "Durasi: ${durasi}\n"
          "Terimakasih kakak ditunggu ya!");

  String url = "https://wa.me/${adminWa}?text=${message}";

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch \$url';
  }
}