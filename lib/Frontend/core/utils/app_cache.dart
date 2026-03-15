import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';

class AppCache {
  static const String _keyRecommended = 'home_recommended';
  static const String _keyNearby = 'home_nearby';
  static const String _keyEvents = 'home_events';
  static const String _keyPackages = 'home_packages';
  static const String _keyExplore = 'explore_places';
  static const String _keyPosts = 'cached_posts';
  static const String _keyLocation = 'home_location_text';
  static const String _keyLastUpdate = 'home_last_update';

  static Future<void> saveRawData(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<dynamic>> getRawData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return [];
    try {
      return json.decode(data);
    } catch (_) {
      return [];
    }
  }

  static String get keyExplore => _keyExplore;
  static String get keyEvents => _keyEvents;
  static String get keyPackages => _keyPackages;
  static String get keyPosts => _keyPosts;
  static String get keyRecommended => _keyRecommended;
  static String get keyNearby => _keyNearby;

  static Future<void> saveHomeData({
    List<PlaceModel>? recommended,
    List<PlaceModel>? nearby,
    List<EventModel>? events,
    List<TravelPackageModel>? packages,
    String? location,
  }) async {
    if (recommended != null) {
      await saveRawData(_keyRecommended, recommended.map((p) => p.toJson()).toList());
    }
    
    if (nearby != null) {
      await saveRawData(_keyNearby, nearby.map((p) => p.toJson()).toList());
    }
    
    if (events != null) {
      await saveRawData(_keyEvents, events.map((e) => e.toJson()).toList());
    }

    if (packages != null) {
      await saveRawData(_keyPackages, packages.map((p) => p.toJson()).toList());
    }
    
    if (location != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocation, location);
    }
  }

  static Future<Map<String, dynamic>> getCachedHomeData() async {
    final recommendedData = await getRawData(_keyRecommended);
    final nearbyData = await getRawData(_keyNearby);
    final eventsData = await getRawData(_keyEvents);
    final packagesData = await getRawData(_keyPackages);
    
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString(_keyLocation);
    final lastUpdate = prefs.getInt(_keyLastUpdate);

    return {
      'recommended': recommendedData.map((j) => PlaceModel.fromJson(j)).toList(),
      'nearby': nearbyData.map((j) => PlaceModel.fromJson(j)).toList(),
      'events': eventsData.map((j) => EventModel.fromJson(j)).toList(),
      'packages': packagesData.map((j) => TravelPackageModel.fromJson(j)).toList(),
      'location': location,
      'lastUpdate': lastUpdate,
    };
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecommended);
    await prefs.remove(_keyNearby);
    await prefs.remove(_keyEvents);
    await prefs.remove(_keyPackages);
    await prefs.remove(_keyExplore);
    await prefs.remove(_keyPosts);
    await prefs.remove(_keyLocation);
    await prefs.remove(_keyLastUpdate);
  }
}