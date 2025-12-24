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

  // Clock-in with face image
  Future<Map<String, dynamic>> clockIn(File imageFile) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.clockInEndpoint}',
      );

      print('🔵 Clock-in request to: $uri');
      print('🔵 Image file: ${imageFile.path}');

      var request = http.MultipartRequest('POST', uri);
      // Add ngrok bypass header
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.headers['User-Agent'] = 'PAM-Attendance-App';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print('🔵 Sending request...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('🔵 Status Code: ${response.statusCode}');
      print('🔵 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(responseBody);
        print('✅ Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        print('❌ Error response: $responseBody');
        // Try to parse error response
        try {
          final errorResponse = json.decode(responseBody);
          return {
            'success': false,
            'status': 'error',
            'message':
                errorResponse['message'] ??
                'Failed to clock in. Status: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'status': 'error',
            'message':
                'Failed to clock in. Status: ${response.statusCode}\nResponse: $responseBody',
          };
        }
      }
    } catch (e) {
      print('❌ Exception in clockIn: $e');
      return {
        'success': false,
        'status': 'error',
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Clock-out with face image
  Future<Map<String, dynamic>> clockOut(File imageFile) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.clockOutEndpoint}',
      );

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

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {
          'success': false,
          'message': 'Failed to clock out. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Recognize face
  Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.recognizeEndpoint}',
      );

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

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {
          'success': false,
          'message': 'Failed to recognize face. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get attendance records for a person
  Future<Map<String, dynamic>> getAttendance(String name) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.attendanceEndpoint}/$name',
      );

      final response = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get attendance. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
