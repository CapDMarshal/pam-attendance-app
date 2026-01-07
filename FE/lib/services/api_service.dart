import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Recognize face (Calls VM)
  Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.recognizeEndpoint}',
      );

      print('🔵 Recognize request to: $uri');

      var request = http.MultipartRequest('POST', uri);
      // Add ngrok bypass header
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('🔵 Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Failed to recognize face. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Exception in recognizeFace: $e');
      return {
        'success': false,
        'status': 'error',
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
