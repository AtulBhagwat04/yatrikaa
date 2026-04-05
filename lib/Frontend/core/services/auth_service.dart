import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';
import 'package:yatrikaa/Frontend/core/services/notification_service.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _guideRequestStatusKey = 'user_guide_status';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _tripsCountKey = 'user_trips_count';
  static const String _savedCountKey = 'user_saved_count';
  static const String _reviewsCountKey = 'user_reviews_count';
  static const String _postsCountKey = 'user_posts_count';
  static const String _idKey = 'user_id';
  static const String _phoneNumberKey = 'user_phone';
  static const String _genderKey = 'user_gender';
  static const String _profilePictureKey = 'user_profile_picture';

  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 1. Try to sign in with Firebase
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (fe) {
        // Log the error code for debugging
        debugPrint('[AuthService] Firebase login failed with code: ${fe.code}');
        
        // 2. Fallback to MongoDB authentication if Firebase fails for any reason (account missing, password mismatch, etc.)
        // This ensures Admin accounts or legacy users can always get back into the app.
        try {
          debugPrint('[AuthService] Attempting legacy MongoDB fallback for $email...');
          return await _handleLegacyLogin(email, password);
        } catch (legacyError) {
          debugPrint('[AuthService] Legacy fallback also failed: $legacyError');
          // If both fail, rethrow the original Firebase error which is more user-friendly
          rethrow;
        }
      }

      if (userCredential.user == null) {
        throw Exception('Login failed: User not found after Firebase sign-in');
      }

      // 3. Get ID Token
      String? idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw Exception('Login failed: Could not retrieve Firebase ID token');
      }

      // 4. Sync with Backend
      final result = await syncWithBackend(idToken);
      
      // 5. Update FCM Token
      NotificationService().updateToken();
      
      return result;
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') message = 'Wrong password provided.';
      else if (e.code == 'invalid-email') message = 'The email address is badly formatted.';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Handles users who exist in MongoDB but not yet in Firebase
  Future<Map<String, dynamic>> _handleLegacyLogin(String email, String password) async {
    // 1. Call the old manual login endpoint
    final response = await BackendHealthManager.instance.post(
      '${ApiConstants.baseUrl}/auth/login',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        UserCredential? userCredential;
        try {
          // 2. Try to create the Firebase account to migrate them
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('[AuthService] Auto-migrated legacy user to Firebase: $email');
        } on FirebaseAuthException catch (fe) {
          if (fe.code == 'email-already-in-use') {
            debugPrint('[AuthService] User already in Firebase, attempting sign-in to sync session...');
            try {
              userCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
            } catch (se) {
              debugPrint('[AuthService] Firebase sign-in failed during sync: $se');
            }
          } else {
            debugPrint('[AuthService] Firebase migration failed with code: ${fe.code}');
          }
        }

        if (userCredential?.user != null) {
          await userCredential!.user!.updateDisplayName(data['name'] ?? 'Traveler');
          String? idToken = await userCredential.user!.getIdToken();
          if (idToken != null) {
            // 3. Sync with backend to link the new Firebase UID to their existing MongoDB ID
            return await syncWithBackend(idToken);
          }
        }
        
        // If we reach here, we have a valid Mongo account but Firebase session is unavailable.
        // We MUST save the Mongo token to give them access!
        await _saveAuthDataFromResponse(data);
        return data; 
      } catch (e) {
        debugPrint('[AuthService] Error during auto-migration process: $e');
        await _saveAuthDataFromResponse(data);
        return data;
      }
    } else {
      throw Exception('Invalid email or password');
    }
  }


  /// Helper to map common response data to SharedPreferences
  Future<void> _saveAuthDataFromResponse(Map<String, dynamic> data) async {
    await _saveAuthData(
      token: data['token'] ?? '',
      id: data['id'] ?? '',
      role: data['role'] ?? 'user',
      guideRequestStatus: data['guideRequestStatus'] ?? 'None',
      name: data['name'] ?? 'Traveler',
      email: data['email'] ?? '',
      tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
      savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
      reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
      phoneNumber: data['phoneNumber'],
      gender: data['gender'],
      profilePicture: data['profilePicture'],
    );
  }



  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      // 1. Register with Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed: User not created in Firebase');
      }

      // Update Firebase display name
      await userCredential.user!.updateDisplayName(name);

      // 2. Get ID Token
      String? idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw Exception('Registration failed: Could not retrieve Firebase ID token');
      }

      // 3. Sync with Backend (will handle creating user in MongoDB)
      final result = await syncWithBackend(idToken, role);
      
      // 4. Update FCM Token
      NotificationService().updateToken();
      
      return result;
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'weak-password') message = 'The password provided is too weak.';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> syncWithBackend(String firebaseIdToken, [String? role]) async {
    final response = await BackendHealthManager.instance.post(
      '${ApiConstants.baseUrl}/auth/firebase-sync',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseIdToken',
      },
      body: role != null ? jsonEncode({'role': role}) : null,
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveAuthData(
        token: data['token'] ?? '',
        id: data['id'] ?? '',
        role: data['role'] ?? 'user',
        guideRequestStatus: data['guideRequestStatus'] ?? 'None',
        name: data['name'] ?? 'Traveler',
        email: data['email'] ?? '',
        tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
        savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
        reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
        postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
        phoneNumber: data['phoneNumber'],
        gender: data['gender'],
        profilePicture: data['profilePicture'],
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Backend synchronization failed');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }


  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phoneNumber,
    String? gender,
    XFile? profileImage,
  }) async {
    final token = await getToken();
    final streamedResponse = await BackendHealthManager.instance.sendMultipart(() async {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;
      if (gender != null) request.fields['gender'] = gender;

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture',
            profileImage.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      return request;
    });
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(
        token: data['token'] ?? '',
        id: data['id'] ?? '',
        role: data['role'] ?? 'user',
        guideRequestStatus: data['guideRequestStatus'] ?? 'None',
        name: data['name'] ?? name,
        email: data['email'] ?? email,
        tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
        savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
        reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
        postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
        phoneNumber: data['phoneNumber'],
        gender: data['gender'],
        profilePicture: data['profilePicture'],
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    final response = await BackendHealthManager.instance.put(
      '${ApiConstants.baseUrl}/auth/change-password',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to change password');
    }
  }

  Future<void> updateTripsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tripsCountKey, count);
  }

  Future<void> updateSavedCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_savedCountKey, count);
  }

  Future<void> updateReviewsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reviewsCountKey, count);
  }

  Future<void> updatePostsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_postsCountKey, count);
  }

  Future<void> _saveAuthData({
    required String token,
    required String id,
    required String role,
    required String guideRequestStatus,
    required String name,
    required String email,
    required int tripsCount,
    required int savedCount,
    required int reviewsCount,
    required int postsCount,
    String? phoneNumber,
    String? gender,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, id);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_guideRequestStatusKey, guideRequestStatus);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_tripsCountKey, tripsCount);
    await prefs.setInt(_savedCountKey, savedCount);
    await prefs.setInt(_reviewsCountKey, reviewsCount);
    await prefs.setInt(_postsCountKey, postsCount);
    if (phoneNumber != null) {
      await prefs.setString(_phoneNumberKey, phoneNumber);
    }
    if (gender != null) await prefs.setString(_genderKey, gender);
    if (profilePicture != null) {
      await prefs.setString(_profilePictureKey, profilePicture);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String> getGuideRequestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guideRequestStatusKey) ?? 'None';
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<int> getTripsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tripsCountKey) ?? 0;
  }

  Future<int> getSavedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_savedCountKey) ?? 0;
  }

  Future<int> getReviewsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reviewsCountKey) ?? 0;
  }

  Future<int> getPostsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_postsCountKey) ?? 0;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey);
  }

  Future<String?> getProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePictureKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_guideRequestStatusKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_tripsCountKey);
    await prefs.remove(_savedCountKey);
    await prefs.remove(_reviewsCountKey);
    await prefs.remove(_postsCountKey);
    await prefs.remove(_idKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_profilePictureKey);
    await _auth.signOut();
  }


  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
