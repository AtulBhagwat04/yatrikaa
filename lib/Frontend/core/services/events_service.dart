import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/event_model.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

class EventsService {
  final AuthService _authService = AuthService();

  Future<List<EventModel>> getEvents({String? category, bool? popular}) async {
    try {
      String url = '${ApiConstants.baseUrl}/events';
      List<String> params = [];
      if (category != null && category != 'All') {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (popular != null) {
        params.add('popular=$popular');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results
            .map<EventModel>((json) => EventModel.fromJson(json))
            .toList();
      } else {
        throw Exception("Failed to fetch events");
      }
    } catch (e) {
      print('Error fetching events: $e');
      return <EventModel>[];
    }
  }

  Future<EventModel?> getEventDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EventModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error fetching event details: $e');
      return null;
    }
  }

  Future<bool> addEvent(
    Map<String, dynamic> body,
    List<File> imageFiles,
  ) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/events');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      body.forEach((key, value) {
        if (value is Map) {
          request.fields[key] = json.encode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      for (var imageFile in imageFiles) {
        final String path = imageFile.path;
        final String ext = path.split('.').last.toLowerCase();

        MediaType contentType = MediaType(
          'image',
          ext == 'png' ? 'png' : 'jpeg',
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
            contentType: contentType,
          ),
        );
      }

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 201) return true;

      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to add event');
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  Future<EventModel?> toggleInterest(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events/$id/interest'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EventModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error toggling interest: $e');
      return null;
    }
  }
}
