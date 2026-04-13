import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/event_model.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';
import '../utils/app_cache.dart';
import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';
import 'package:yatrikaa/Frontend/core/utils/logger_service.dart';

class EventsService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getEventsPaginated({
    String? category,
    bool? popular,
    int page = 1,
    int limit = 12,
  }) async {
    try {
      String url = '${ApiConstants.baseUrl}/events';
      List<String> params = ['page=$page', 'limit=$limit'];
      if (category != null && category != 'All') {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (popular != null) {
        params.add('popular=$popular');
      }
      url += '?${params.join('&')}';

      final response = await BackendHealthManager.instance.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'] ?? [];
        bool hasMore = data['hasMore'] ?? false;

        // ── Client-side Slicing Fallback ────────────────────────────────────
        if (data['hasMore'] == null && results.length > limit) {
          final int start = (page - 1) * limit;
          final int end = start + limit;
          final List fullList = List.from(results);
          
          if (start < fullList.length) {
            results = fullList.sublist(
              start,
              end < fullList.length ? end : fullList.length,
            );
            hasMore = end < fullList.length;
          } else {
            results = [];
            hasMore = false;
          }
        }

        // Cache first page of all events
        if (page == 1 && (category == null || category == 'All')) {
          await AppCache.saveRawData(AppCache.keyEvents, results);
        }

        return {
          'events': results.map<EventModel>((json) => EventModel.fromJson(json)).toList(),
          'hasMore': hasMore,
        };
      } else {
        throw Exception("Failed to fetch events");
      }
    } catch (e) {
      Log.e('Error fetching paginated events: $e');

      // Fall back to cache only on first page
      if (page == 1 && (category == null || category == 'All')) {
        final cachedData = await AppCache.getRawData(AppCache.keyEvents);
        if (cachedData.isNotEmpty) {
          return {
            'events': cachedData
                .map<EventModel>((json) => EventModel.fromJson(json))
                .toList(),
            'hasMore': false,
          };
        }
      }

      return {'events': <EventModel>[], 'hasMore': false};
    }
  }

  Future<List<EventModel>> getEvents({String? category, bool? popular}) async {
    try {
      String url = '${ApiConstants.baseUrl}/events';
      List<String> params = ['limit=0']; // fetch all for home screen/bloc
      if (category != null && category != 'All') {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (popular != null) {
        params.add('popular=$popular');
      }

      url += '?${params.join('&')}';

      final response = await BackendHealthManager.instance.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        // Save to cache for offline support if it's a general request
        if ((category == null || category == 'All')) {
          await AppCache.saveRawData(AppCache.keyEvents, results);
        }

        return results
            .map<EventModel>((json) => EventModel.fromJson(json))
            .toList();
      } else {
        throw Exception("Failed to fetch events");
      }
    } catch (e) {
      Log.e('Error fetching events: $e');

      // Try falling back to cache if it's a general request
      if (category == null || category == 'All') {
        final cachedData = await AppCache.getRawData(AppCache.keyEvents);
        if (cachedData.isNotEmpty) {
          return cachedData
              .map<EventModel>((json) => EventModel.fromJson(json))
              .toList();
        }
      }

      return <EventModel>[];
    }
  }

  Future<EventModel?> getEventDetails(String id) async {
    try {
      final response = await BackendHealthManager.instance.get(
        '${ApiConstants.baseUrl}/events/$id',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EventModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      Log.e('Error fetching event details: $e');
      return null;
    }
  }

  Future<bool> addEvent(
    Map<String, dynamic> body,
    List<File> imageFiles,
  ) async {
    try {
      final token = await _authService.getToken();
      final streamedResponse = await BackendHealthManager.instance.sendMultipart(() async {
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
        return request;
      });
      if (streamedResponse.statusCode == 201) return true;

      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to add event');
    } catch (e) {
      Log.e('Error adding event: $e');
      rethrow;
    }
  }

  Future<EventModel?> toggleInterest(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.post(
        '${ApiConstants.baseUrl}/events/$id/interest',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EventModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      Log.e('Error toggling interest: $e');
      return null;
    }
  }

  Future<bool> updateEvent(
    String id,
    Map<String, dynamic> body, {
    List<File> imageFiles = const [],
  }) async {
    try {
      final token = await _authService.getToken();
      final streamedResponse = await BackendHealthManager.instance.sendMultipart(() async {
        final uri = Uri.parse('${ApiConstants.baseUrl}/events/$id');
        var request = http.MultipartRequest('PUT', uri);

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        body.forEach((key, value) {
          if (value is List || value is Map) {
            // Use a different key for existing images to avoid collision with the file field name
            final fieldKey = key == 'images' ? 'existing_images' : key;
            request.fields[fieldKey] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        });

        if (imageFiles.isNotEmpty) {
          for (var imageFile in imageFiles) {
            final String path = imageFile.path;
            final String ext = path.split('.').last.toLowerCase();
            MediaType contentType = MediaType(
              'image',
              ext == 'png' ? 'png' : 'jpeg',
            );

            request.files.add(
              await http.MultipartFile.fromPath(
                'images', // Field name matches backend upload.array('images', 3)
                path,
                contentType: contentType,
              ),
            );
          }
        }
        return request;
      });
      if (streamedResponse.statusCode == 200) return true;

      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update event');
    } catch (e) {
      Log.e('Error updating event: $e');
      rethrow;
    }
  }
}
