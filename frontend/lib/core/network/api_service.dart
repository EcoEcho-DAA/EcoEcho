import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://192.168.1.18:3000';
      }
      return 'http://localhost:3000';
    }
  }
  
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

  /// Sends a PUT request to the backend.
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userToken != null) 'Authorization': 'Bearer $userToken',
    };

    try {
      return await http.put(url, headers: headers, body: jsonEncode(body));
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }

  /// Sends a DELETE request to the backend.
  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userToken != null) 'Authorization': 'Bearer $userToken',
    };

    try {
      return await http.delete(url, headers: headers);
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }

  /// Uploads an image using a multipart form request.
  static Future<http.StreamedResponse> uploadImage(String endpoint, String imagePath, Map<String, String> fields) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (userToken != null) {
      request.headers['Authorization'] = 'Bearer $userToken';
    }

    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      return await request.send();
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }

  /// Uploads an image using raw bytes (useful on Web and to avoid temp files).
  static Future<http.StreamedResponse> uploadImageBytes(String endpoint, Uint8List bytes, String filename, Map<String, String> fields) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (userToken != null) {
      request.headers['Authorization'] = 'Bearer $userToken';
    }

    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));

    try {
      return await request.send();
    } catch (e) {
      throw Exception('Network execution fault: $e');
    }
  }
}