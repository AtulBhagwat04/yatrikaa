import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/post_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class PostService {
  final AuthService _authService = AuthService();

  Future<List<PostModel>> getAllPosts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => PostModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to fetch posts");
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<PostModel?> createPost({
    required String location,
    required String caption,
    required dynamic imageFile, // XFile from image_picker
  }) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/posts');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['location'] = location;
      request.fields['caption'] = caption;

      if (imageFile != null) {
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
            'image',
            path,
            contentType: contentType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 201) {
        return PostModel.fromJson(json.decode(responseBody));
      } else {
        print('Post failed: ${streamedResponse.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('PostService Exception: $e');
      return null;
    }
  }

  Future<PostModel?> likePost(String postId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/like'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error liking post: $e');
      return null;
    }
  }

  Future<PostModel?> commentOnPost(String postId, String text) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/comment'),
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
      print('Error commenting on post: $e');
      return null;
    }
  }

  Future<PostModel?> deleteComment(String postId, String commentId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/comments/$commentId'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error deleting comment: $e');
      return null;
    }
  }
}
