import 'dart:convert';
import 'package:http/http.dart' as http;

class WordService {
  // Using a free API that returns a random word
  static const String _baseUrl = 'https://random-word-api.herokuapp.com/word?number=1';

  Future<String?> fetchRandomWord() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        // The API returns a list like ["apple"], so we decode and get the first item
        List<dynamic> data = jsonDecode(response.body);
        return data[0].toString();
      } else {
        print('Failed to load word. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching word: $e');
      return null;
    }
  }
}