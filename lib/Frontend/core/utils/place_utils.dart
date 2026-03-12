import 'package:flutter/material.dart';

class PlaceUtils {
  static bool checkIfOpenNow(String? timings, bool? defaultIsOpen) {
    if (timings == null || timings.trim().isEmpty) return defaultIsOpen ?? false;
    
    final t = timings.toLowerCase().replaceAll('\u202f', ' ');
    if (t.contains("24 hours") || 
        t.contains("open 24 hours") || 
        t.contains("24/7") || 
        t.contains("open247") || 
        t.contains("open 24 hrs")) {
      return true;
    }
    
    try {
      final RegExp timeRegex = RegExp(
        r'(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)?\s*(?:-|–|to)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)?', 
        caseSensitive: false
      );
      final match = timeRegex.firstMatch(t);
      if (match != null) {
        int startHour = int.parse(match.group(1)!);
        int startMin = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        String startAmPm = (match.group(3) ?? "am").replaceAll('.', '').toLowerCase();
        
        int endHour = int.parse(match.group(4)!);
        int endMin = match.group(5) != null ? int.parse(match.group(5)!) : 0;
        String endAmPm = (match.group(6) ?? "pm").replaceAll('.', '').toLowerCase();
        
        if (startAmPm == "pm" && startHour < 12) startHour += 12;
        if (startAmPm == "am" && startHour == 12) startHour = 0;
        
        if (endAmPm == "pm" && endHour < 12) endHour += 12;
        if (endAmPm == "am" && endHour == 12) endHour = 0;
        
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = startHour * 60 + startMin;
        final endMinutes = endHour * 60 + endMin;
        
        if (endMinutes < startMinutes) {
          return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
        } else {
          return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
        }
      }
    } catch (e) {
      debugPrint("Error parsing timings: $e");
    }
    
    if (t == "open now" || t == "open") return true;
    if (t == "closed") return false;
    
    return defaultIsOpen ?? false;
  }
}
