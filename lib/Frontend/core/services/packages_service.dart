import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/core/models/booking_model.dart';
import 'package:yatrikaa/Frontend/core/models/guide_request_model.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';

import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';
import 'package:yatrikaa/Frontend/core/utils/app_cache.dart';

class PackagesService {
  final AuthService _authService = AuthService();

  // ── Shared auth header ─────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Packages ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPackagesPaginated({
    String? category,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final url = ApiConstants.getPackagesUrl(
        category: category,
        search: search,
        page: page,
        limit: limit,
      );
      final response = await BackendHealthManager.instance.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'] ?? [];
        bool hasMore = data['hasMore'] ?? false;

        // ── Pagination Metadata Fallback ────────────────────────────────────
        if (data['hasMore'] == null) {
          if (results.length > limit) {
            // Case A: Server returned everything (non-paginated). We slice it.
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
          } else if (results.length == limit) {
            // Case B: Server might be paginating but omitted 'hasMore'.
            // Assume there's more until we get a shorter page.
            hasMore = true;
          } else {
            // Case C: Result count is less than limit, definitely no more.
            hasMore = false;
          }
        }

        // Save to cache for offline support if it's a general request (page 1)
        if (page == 1 && category == null && search == null) {
          await AppCache.saveRawData(AppCache.keyPackages, results);
        }

        return {
          'packages': results
              .map((j) => TravelPackageModel.fromJson(j))
              .toList(),
          'hasMore': hasMore,
        };
      }
      throw Exception('Failed to fetch packages');
    } catch (e) {
      print('PackagesService.getPackagesPaginated: $e');

      // Try falling back to cache (first page only)
      if (page == 1 && category == null && search == null) {
        final cachedData = await AppCache.getRawData(AppCache.keyPackages);
        if (cachedData.isNotEmpty) {
          return {
            'packages': cachedData
                .map((j) => TravelPackageModel.fromJson(j))
                .toList(),
            'hasMore': false,
          };
        }
      }

      return {'packages': <TravelPackageModel>[], 'hasMore': false};
    }
  }

  Future<List<TravelPackageModel>> getPackages({
    String? category,
    String? search,
  }) async {
    // Legacy method – fetches everything (limit=0) for admin/guided use-cases
    try {
      final url = ApiConstants.getPackagesUrl(
        category: category,
        search: search,
        limit:
            50, // server might not like 0, use a reasonable high limit for preview
      );
      final response = await BackendHealthManager.instance.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (category == null && search == null) {
          await AppCache.saveRawData(AppCache.keyPackages, results);
        }
        return results.map((j) => TravelPackageModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch packages');
    } catch (e) {
      print('PackagesService.getPackages: $e');
      if (category == null && search == null) {
        final cachedData = await AppCache.getRawData(AppCache.keyPackages);
        if (cachedData.isNotEmpty) {
          return cachedData.map((j) => TravelPackageModel.fromJson(j)).toList();
        }
      }
      return [];
    }
  }

  Future<TravelPackageModel?> getPackageDetails(String id) async {
    try {
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getPackageDetailUrl(id),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TravelPackageModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('PackagesService.getPackageDetails: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getMyPackages({
    int page = 1,
    int limit = 12,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.getMyPackagesUrl()}?page=$page&limit=$limit';
      final response = await BackendHealthManager.instance.get(
        url,
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final bool hasMore = data['hasMore'] ?? false;
        
        return {
          'packages': results.map((j) => TravelPackageModel.fromJson(j)).toList(),
          'hasMore': hasMore,
          'totalCount': data['totalCount'] ?? results.length,
        };
      }
      throw Exception('Failed to fetch my packages');
    } catch (e) {
      print('PackagesService.getMyPackages: $e');
      return {'packages': <TravelPackageModel>[], 'hasMore': false, 'totalCount': 0};
    }
  }

  /// Create a new travel package (guide / admin only).
  Future<bool> createPackage(
    Map<String, dynamic> body, {
    List<File> imageFiles = const [],
  }) async {
    try {
      final token = await _authService.getToken();
      final streamed = await BackendHealthManager.instance.sendMultipart(
        () async {
          final uri = Uri.parse('${ApiConstants.baseUrl}/packages');
          final request = http.MultipartRequest('POST', uri);

          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }

          // Encode nested objects as JSON strings
          body.forEach((key, value) {
            if (value is Map || value is List) {
              request.fields[key] = json.encode(value);
            } else {
              request.fields[key] = value.toString();
            }
          });

          for (final file in imageFiles) {
            final ext = file.path.split('.').last.toLowerCase();
            request.files.add(
              await http.MultipartFile.fromPath(
                'images',
                file.path,
                contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
              ),
            );
          }
          return request;
        },
      );

      if (streamed.statusCode == 201) return true;

      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body);
      throw Exception(data['error'] ?? 'Failed to create package');
    } catch (e) {
      print('PackagesService.createPackage: $e');
      rethrow;
    }
  }

  /// Update an existing travel package.
  Future<bool> updatePackage(
    String id,
    Map<String, dynamic> body, {
    List<File> imageFiles = const [],
  }) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/packages/$id');
      final request = http.MultipartRequest('PATCH', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Encode nested objects as JSON strings
      body.forEach((key, value) {
        if (value is Map || value is List) {
          request.fields[key] = json.encode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      for (final file in imageFiles) {
        final ext = file.path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
          ),
        );
      }

      final streamed = await request.send();
      if (streamed.statusCode == 200) return true;

      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body);
      throw Exception(data['error'] ?? 'Failed to update package');
    } catch (e) {
      print('PackagesService.updatePackage: $e');
      rethrow;
    }
  }

  Future<bool> deletePackage(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.delete(
        '${ApiConstants.baseUrl}/packages/$id',
        headers: headers,
      );
      if (response.statusCode == 200) return true;
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete package');
    } catch (e) {
      print('PackagesService.deletePackage: $e');
      rethrow;
    }
  }

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Join / book a package.
  /// [travelers] is a list of maps: [{ 'name': ..., 'age': ..., 'gender': ... }]
  Future<BookingModel?> joinPackage({
    required String packageId,
    required List<Map<String, dynamic>> travelers,
    required String contactNumber,
    String? notes,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'travelers': travelers,
        'contactNumber': contactNumber,
        'notes': notes,
      };
      final response = await BackendHealthManager.instance.post(
        ApiConstants.getJoinPackageUrl(packageId),
        headers: headers,
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BookingModel.fromJson(data['result']);
      }
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Failed to join package');
    } catch (e) {
      print('PackagesService.joinPackage: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getMyBookingsUrl(),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => BookingModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch bookings');
    } catch (e) {
      print('PackagesService.getMyBookings: $e');
      return [];
    }
  }

  Future<String> cancelBooking(String bookingId) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.patch(
        ApiConstants.getCancelBookingUrl(bookingId),
        headers: headers,
        body: json.encode({}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data['message'] ?? 'Cancellation processed';
      }
      throw Exception(data['error'] ?? 'Failed to cancel booking');
    } catch (e) {
      print('PackagesService.cancelBooking: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> getPackageParticipants(String packageId) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getPackageParticipantsUrl(packageId),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => BookingModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch participants');
    } catch (e) {
      print('PackagesService.getPackageParticipants: $e');
      return [];
    }
  }

  Future<List<BookingModel>> getGuideAllBookings() async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getGuideAllBookingsUrl(),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => BookingModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch all guide bookings');
    } catch (e) {
      print('PackagesService.getGuideAllBookings: $e');
      return [];
    }
  }

  Future<bool> handleBooking(String bookingId, String action) async {
    try {
      final headers = await _authHeaders();
      // If organizer is handling it, ALWAYS use confirm endpoint but with target status
      // because /cancel might only be for user requests.
      final url = ApiConstants.getConfirmBookingUrl(bookingId);

      final response = await BackendHealthManager.instance.patch(
        url,
        headers: headers,
        body: json.encode({'status': action}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) return true;

      String errorMsg =
          'Failed to update booking status (${response.statusCode})';
      try {
        final data = json.decode(response.body);
        errorMsg = data['error'] ?? errorMsg;
      } catch (_) {
        errorMsg = response.reasonPhrase ?? 'Server error';
      }
      throw Exception(errorMsg);
    } catch (e) {
      print('PackagesService.handleBooking: $e');
      rethrow;
    }
  }

  Future<bool> handleTravelerStatus({
    required String bookingId,
    required String travelerId,
    required String status,
    bool isRequest = false,
  }) async {
    try {
      final headers = await _authHeaders();
      // If it's a user request, hit /cancel sub-endpoint
      // If it's an organizer action, hit the root traveler endpoint or /confirm
      String url =
          '${ApiConstants.baseUrl}/packages/bookings/$bookingId/travelers/$travelerId';

      final response = await BackendHealthManager.instance.patch(
        url,
        headers: headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) return true;

      String errorMsg = 'Failed to update traveler status';
      try {
        final data = json.decode(response.body);
        errorMsg = data['error'] ?? errorMsg;
      } catch (_) {
        errorMsg = 'Server error (${response.statusCode})';
      }
      throw Exception(errorMsg);
    } catch (e) {
      print('PackagesService.handleTravelerStatus: $e');
      rethrow;
    }
  }

  /// Admin only: Approve and publish a draft package.
  Future<bool> publishPackage(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse(ApiConstants.getPublishPackageUrl(id)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('PackagesService.publishPackage: $e');
      return false;
    }
  }

  /// Admin only: Fetch all packages regardless of status.
  Future<Map<String, dynamic>> getAdminPackages({
    String? status,
    int page = 1,
    int limit = 12,
  }) async {
    try {
      final headers = await _authHeaders();
      String url = ApiConstants.getAdminAllPackagesUrl();
      final List<String> params = ['page=$page', 'limit=$limit'];
      if (status != null) params.add('status=$status');
      url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final bool hasMore = data['hasMore'] ?? false;

        return {
          'packages': results.map((j) => TravelPackageModel.fromJson(j)).toList(),
          'hasMore': hasMore,
          'totalCount': data['totalCount'] ?? results.length,
        };
      }
      throw Exception(
        'Failed to fetch admin packages (${response.statusCode})',
      );
    } catch (e) {
      print('PackagesService.getAdminPackages Error: $e');
      return {'packages': <TravelPackageModel>[], 'hasMore': false, 'totalCount': 0};
    }
  }

  // ── Admin: Guide Requests ──────────────────────────────────────────────────

  Future<List<GuideRequestModel>> getGuideRequests() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.getGuideRequestsUrl()),
        headers: headers,
      );
      if (response.statusCode == 200) {
        print('PackagesService.getGuideRequests Response: ${response.body}');
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => GuideRequestModel.fromJson(j)).toList();
      }
      throw Exception(
        'Failed to fetch guide requests (${response.statusCode})',
      );
    } catch (e) {
      print('PackagesService.getGuideRequests Error: $e');
      rethrow;
    }
  }

  Future<bool> handleGuideRequest(String userId, String action) async {
    try {
      final headers = await _authHeaders();
      final body = {'userId': userId, 'action': action};
      final response = await http.post(
        Uri.parse(ApiConstants.getHandleGuideRequestUrl()),
        headers: headers,
        body: json.encode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('PackagesService.handleGuideRequest: $e');
      return false;
    }
  }

  Future<bool> requestGuideRole() async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.getRequestGuideRoleUrl()),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('PackagesService.requestGuideRole: $e');
      return false;
    }
  }

  Future<TravelPackageModel?> addReview(String packageId, double rating, String text) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.post(
        '${ApiConstants.baseUrl}/packages/$packageId/reviews',
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TravelPackageModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error adding review to package: $e');
      return null;
    }
  }

  Future<TravelPackageModel?> updateReview(String packageId, String reviewId, double rating, String text) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.put(
        '${ApiConstants.baseUrl}/packages/$packageId/reviews/$reviewId',
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TravelPackageModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error updating review for package: $e');
      return null;
    }
  }

  Future<TravelPackageModel?> deleteReview(String packageId, String reviewId) async {
    try {
      final headers = await _authHeaders();
      final response = await BackendHealthManager.instance.delete(
        '${ApiConstants.baseUrl}/packages/$packageId/reviews/$reviewId',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TravelPackageModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error deleting review for package: $e');
      return null;
    }
  }
}

