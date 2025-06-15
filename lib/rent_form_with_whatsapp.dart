// rent_form_with_whatsapp.dart
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weatherapp/drop_off_maps_screen.dart'; // Import the new drop-off screen
import 'package:weatherapp/maps_screen.dart'; // Import MapsScreen

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
  final TextEditingController statusController =
      TextEditingController(); // Pastikan ini ada
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
    statusController.dispose(); // Pastikan ini ada
    emailController.dispose();
    super.dispose();
  }

  void _filterData() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredrentalList =
          rentalList.where((rental) {
            return rental['Nama'].toString().toLowerCase().contains(query) ||
                rental['Email'].toString().toLowerCase().contains(query) ||
                rental['NoWa'].toString().contains(query) ||
                rental['PickUp'].toString().toLowerCase().contains(query) ||
                rental['DropOff'].toString().toLowerCase().contains(query) ||
                rental['Status'].toString().toLowerCase().contains(
                  query,
                ) || // Tambahkan ini
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
    // Menambahkan 'Status' dengan nilai default "sedang menunggu payung"
    await supabase.from('rental').insert({
      'Nama': namaController.text,
      'Email': emailController.text,
      'NoWa': int.tryParse(nowaController.text) ?? 0,
      'PickUp': pickupController.text,
      'DropOff': dropoffController.text,
      'Durasi': int.tryParse(durasiController.text) ?? 0,
      'Status': "Sedang Menunggu Payung", // <-- Tambahkan baris ini
    });
    fetchData();
  }

  Future<void> updateData() async {
    if (selectedId != null) {
      await supabase
          .from('rental')
          .update({
            'Nama': namaController.text,
            'Email': emailController.text,
            'NoWa': int.tryParse(nowaController.text) ?? 0,
            'PickUp': pickupController.text,
            'DropOff': dropoffController.text,
            'Status':
                statusController.text, // Pastikan ini di-update juga jika perlu
            'Durasi': int.tryParse(durasiController.text) ?? 0,
          })
          .eq('id', selectedId!);

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
    statusController.clear(); // Pastikan ini juga di-clear
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
                          decoration: const InputDecoration(labelText: "Nama"),
                        ),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: "Email"),
                        ),
                        TextField(
                          controller: nowaController,
                          decoration: const InputDecoration(labelText: "No Wa"),
                          keyboardType: TextInputType.number,
                        ),
                        // Row for Pick Up with a button to select location
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pickupController,
                                decoration: const InputDecoration(
                                  labelText: "Lokasi Pick Up",
                                ),
                                readOnly:
                                    true, // Make it read-only, but allow selection via button
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () async {
                                final selectedPickupUrl = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const MapsScreen(), // Navigate to MapsScreen
                                  ),
                                );
                                if (selectedPickupUrl != null) {
                                  setState(() {
                                    pickupController.text =
                                        selectedPickupUrl as String;
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
                                decoration: const InputDecoration(
                                  labelText: "Lokasi Drop Off",
                                ),
                                readOnly: true, // Make it read-only
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () async {
                                final selectedDropOffUrl = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const DropOffMapsScreen(),
                                  ),
                                );
                                if (selectedDropOffUrl != null) {
                                  setState(() {
                                    dropoffController.text =
                                        selectedDropOffUrl as String;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        TextField(
                          controller: durasiController,
                          decoration: const InputDecoration(
                            labelText: "Durasi (menit)",
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (selectedId == null) {
                                  final nama = namaController.text;
                                  final email = emailController.text;
                                  final pickup = pickupController.text;
                                  final dropoff = dropoffController.text;
                                  final durasi = durasiController.text;

                                  await tambahData(); // Ini akan menyimpan status default
                                  sendToWhatsApp(
                                    nama: nama,
                                    email: email,
                                    pickup: pickup,
                                    dropoff: dropoff,
                                    durasi: durasi,
                                  );

                                  clearFields();
                                } else {
                                  await updateData();
                                }
                              },
                              child: Text(
                                selectedId == null
                                    ? "Tambah Data"
                                    : "Update Data",
                              ),
                            ),
                            if (selectedId != null)
                              ElevatedButton(
                                onPressed: clearFields,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
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
                    // Mengubah title untuk menampilkan nama dan status
                    title: Text(
                      "${rental['Nama']} - ${rental['Status'] ?? 'Status tidak tersedia'}",
                    ),
                    subtitle: Text("Durasi: ${rental['Durasi']} menit"),
                    // Bagian trailing telah dihapus pada instruksi sebelumnya
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

Future<void> sendToWhatsApp({
  required String nama,
  required String email,
  required String pickup,
  required String durasi,
  required String dropoff,
}) async {
  final adminWa = '6281282307768'; // admin number
  final message = Uri.encodeComponent(
    "Halo Admin, saya ingin melakukan Rental Payung.\n"
    "Nama                  : ${nama}\n"
    "Email                   : ${email}\n"
    "Lokasi Pick Up    : ${pickup}\n"
    "Lokasi Drop Off  : ${dropoff}\n"
    "Durasi                 : ${durasi} menit\n"
    "Terimakasih kakak ditunggu ya!",
  );

  //String url = "https://wa.me/${adminWa}?text=${message}";
  final whatsappUri = Uri.parse("https://wa.me/$adminWa?text=$message");
  if (await canLaunchUrl(whatsappUri)) {
    print("Launching URL: ${whatsappUri.toString()}"); //debugging
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch WhatsApp';
  }
}
