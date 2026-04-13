import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/post_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';
import '../utils/app_cache.dart';
import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';
import 'package:yatrikaa/Frontend/core/utils/logger_service.dart';

class PostService {
  final AuthService _authService = AuthService();

  Future<List<PostModel>> getAllPosts() async {
    try {
      final response = await BackendHealthManager.instance.get(
        '${ApiConstants.baseUrl}/posts',
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);

        // Cache the raw results for offline use
        await AppCache.saveRawData(AppCache.keyPosts, results);

        return results.map((json) => PostModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to fetch posts");
      }
    } catch (e) {
      Log.e('Error fetching posts: $e');

      // Fallback to cache if network fails
      final cachedData = await AppCache.getRawData(AppCache.keyPosts);
      if (cachedData.isNotEmpty) {
        return cachedData.map((json) => PostModel.fromJson(json)).toList();
      }

      return [];
    }
  }

  Future<PostModel?> createPost({
    required String location,
    required String caption,
    required List<dynamic> imageFiles, // List of XFile from image_picker
  }) async {
    try {
      final token = await _authService.getToken();
      final streamedResponse = await BackendHealthManager.instance.sendMultipart(() async {
        final uri = Uri.parse('${ApiConstants.baseUrl}/posts');
        var request = http.MultipartRequest('POST', uri);

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['location'] = location;
        request.fields['caption'] = caption;

        if (imageFiles.isNotEmpty) {
          for (var imageFile in imageFiles) {
            final String path = imageFile.path;
            final String ext = path.split('.').last.toLowerCase();

            MediaType contentType;
            if (ext == 'png') {
              contentType = MediaType('image', 'png');
            } else if (ext == 'webp') {
              contentType = MediaType('image', 'webp');
            } else {
              contentType = MediaType('image', 'jpeg');
            }

            request.files.add(
              await http.MultipartFile.fromPath(
                'images',
                path,
                contentType: contentType,
              ),
            );
          }
        }
        return request;
      });
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 201) {
        return PostModel.fromJson(json.decode(responseBody));
      } else {
        Log.e('Post failed: ${streamedResponse.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      Log.e('PostService Exception: $e');
      return null;
    }
  }

  Future<PostModel?> likePost(String postId) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.post(
        '${ApiConstants.baseUrl}/posts/$postId/like',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      Log.e('Error liking post: $e');
      return null;
    }
  }

  Future<PostModel?> commentOnPost(String postId, String text) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.post(
        '${ApiConstants.baseUrl}/posts/$postId/comment',
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      Log.e('Error commenting on post: $e');
      return null;
    }
  }

  Future<PostModel?> deleteComment(String postId, String commentId) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.delete(
        '${ApiConstants.baseUrl}/posts/$postId/comments/$commentId',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      Log.e('Error deleting comment: $e');
      return null;
    }
  }

  Future<PostModel?> editComment(
    String postId,
    String commentId,
    String text,
  ) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.put(
        '${ApiConstants.baseUrl}/posts/$postId/comments/$commentId',
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      Log.e('Error editing comment: $e');
      return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final token = await _authService.getToken();
      final response = await BackendHealthManager.instance.delete(
        '${ApiConstants.baseUrl}/posts/$postId',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      Log.e('Error deleting post: $e');
      return false;
    }
  }

  Future<PostModel?> updatePost({
    required String postId,
    required String location,
    required String caption,
    List<dynamic> imageFiles = const [],
  }) async {
    try {
      final token = await _authService.getToken();
      final streamedResponse = await BackendHealthManager.instance.sendMultipart(() async {
        final uri = Uri.parse('${ApiConstants.baseUrl}/posts/$postId');
        var request = http.MultipartRequest('PUT', uri);

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['location'] = location;
        request.fields['caption'] = caption;

        if (imageFiles.isNotEmpty) {
          for (var imageFile in imageFiles) {
            final String path = imageFile.path;
            final String ext = path.split('.').last.toLowerCase();

            MediaType contentType;
            if (ext == 'png') {
              contentType = MediaType('image', 'png');
            } else if (ext == 'webp') {
              contentType = MediaType('image', 'webp');
            } else {
              contentType = MediaType('image', 'jpeg');
            }

            request.files.add(
              await http.MultipartFile.fromPath(
                'images',
                path,
                contentType: contentType,
              ),
            );
          }
        }
        return request;
      });
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return PostModel.fromJson(json.decode(responseBody));
      } else {
        Log.e('Update failed: ${streamedResponse.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      Log.e('PostService update Exception: $e');
      return null;
    }
  }
}
