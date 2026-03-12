import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/core/models/booking_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';

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

  Future<List<TravelPackageModel>> getPackages({
    String? category,
    String? search,
  }) async {
    try {
      final url = ApiConstants.getPackagesUrl(category: category, search: search);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => TravelPackageModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch packages');
    } catch (e) {
      print('PackagesService.getPackages: $e');
      return [];
    }
  }

  Future<TravelPackageModel?> getPackageDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getPackageDetailUrl(id)),
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

  Future<List<TravelPackageModel>> getMyPackages() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.getMyPackagesUrl()),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((j) => TravelPackageModel.fromJson(j)).toList();
      }
      throw Exception('Failed to fetch my packages');
    } catch (e) {
      print('PackagesService.getMyPackages: $e');
      return [];
    }
  }

  /// Create a new travel package (guide / admin only).
  Future<bool> createPackage(
    Map<String, dynamic> body, {
    List<File> imageFiles = const [],
  }) async {
    try {
      final token = await _authService.getToken();
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
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          file.path,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ));
      }

      final streamed = await request.send();
      if (streamed.statusCode == 201) return true;

      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body);
      throw Exception(data['error'] ?? 'Failed to create package');
    } catch (e) {
      print('PackagesService.createPackage: $e');
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
        if (notes != null) 'notes': notes,
      };
      final response = await http.post(
        Uri.parse(ApiConstants.getJoinPackageUrl(packageId)),
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
      final response = await http.get(
        Uri.parse(ApiConstants.getMyBookingsUrl()),
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

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse(ApiConstants.getCancelBookingUrl(bookingId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('PackagesService.cancelBooking: $e');
      return false;
    }
  }
}
