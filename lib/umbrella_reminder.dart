import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> checkAndBorrowUmbrella(String weatherDescription) async {
  if (weatherDescription.toLowerCase().contains('rain')) {
    final borrowUrl = Uri.parse('http://localhost:3000/api/umbrella/borrow');
    final response = await http.post(borrowUrl);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return "Kondisi hujan, payung telah dipinjam (ID: ${data['id']})";
    } else {
      return "Hujan, tapi tidak ada payung tersedia";
    }
  }
  return "Cuaca cerah, tidak perlu payung";
}
