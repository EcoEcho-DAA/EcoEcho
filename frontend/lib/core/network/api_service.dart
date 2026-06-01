import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://ecoecho-backend.onrender.com';
  
  // App-wide memory variable to hold the logged-in person's session token
  static String? userToken;

  /// Sends a secure POST request to the backend container.
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userToken != null) 'Authorization': 'Bearer $userToken',
    };

    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));
      
      // If logging in, extract and store the token from the response
      if (endpoint == '/api/auth/login' && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userToken = data['token'];
      }
      
      return response;
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }

  /// Sends a strict GET request to retrieve database rows from the cloud layers.
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userToken != null) 'Authorization': 'Bearer $userToken',
    };

    try {
      return await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }
}