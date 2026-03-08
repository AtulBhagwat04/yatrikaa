import 'dart:io';
import '../constants/app_strings.dart';
import 'package:http/http.dart' as http;

class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return AppStrings.errNoInternet;
    } else if (error is http.ClientException) {
      return AppStrings.errServer;
    } else if (error.toString().contains('TimeoutException')) {
      return AppStrings.errTimeout;
    } else if (error.toString().contains('401') || error.toString().contains('403')) {
      return AppStrings.errUnauthorized;
    } else if (error.toString().contains('404')) {
      return AppStrings.errNotFound;
    } else if (error.toString().contains('500')) {
      return AppStrings.errServer;
    } else if (error.toString().contains('Invalid data') || error.toString().contains('400')) {
      return AppStrings.errInvalidData;
    } else if (error.toString().contains('image')) {
      return AppStrings.errImageUpload;
    } else if (error.toString().contains('Permission denied')) {
      return AppStrings.errLocationDenied;
    }

    // Default to the original error if it's already someone's custom string, 
    // but filter if it looks like a programmatic exception
    final errStr = error.toString();
    if (errStr.contains('Exception:') || errStr.contains('Error:')) {
      return AppStrings.errUnexpected;
    }
    
    return errStr.isNotEmpty ? errStr : AppStrings.errUnexpected;
  }
}
