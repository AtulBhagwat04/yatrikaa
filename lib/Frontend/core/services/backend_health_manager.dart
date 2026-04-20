import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/utils/logger_service.dart';

class BackendHealthManager {
  BackendHealthManager._();
  static final BackendHealthManager instance = BackendHealthManager._();

  static const String _renderBase = 'https://yatrikaa-backend.onrender.com/api';
  static const String _railwayBase =
      'https://bhatkanti-backend.up.railway.app/api';

  static const String _renderHealth =
      'https://yatrikaa-backend.onrender.com/health';

  static const Duration _renderPingTimeout = Duration(seconds: 10);
  static const Duration _renderRequestTimeout = Duration(seconds: 8);
  static const Duration _renderCheckInterval = Duration(minutes: 2);

  static const Duration _localDiscoveryInterval = Duration(seconds: 15);

  bool _usingRailway = true;
  bool _usingLocal = false;
  bool _useLocalPreference = false;

  Timer? _recoveryTimer;

  String get currentBaseUrl {
    if (_usingLocal) return ApiConstants.localUrl;
    return _usingRailway ? _railwayBase : _renderBase;
  }

  bool get isOnRailway => _usingRailway && !_usingLocal;
  bool get isOnLocal => _usingLocal;

  Future<void> initialize({bool useLocal = false}) async {
    _useLocalPreference = useLocal;

    if (_useLocalPreference) {
      Log.d('[BackendHealthManager] Attempting Local detection...');
      final localHealthUrl = ApiConstants.localUrl.replaceFirst(
        '/api',
        '/health',
      );
      final isLocalUp = await _pingBackend(
        localHealthUrl,
        const Duration(milliseconds: 1000),
      );

      if (isLocalUp) {
        _usingLocal = true;
        _usingRailway = false;
        Log.i('[BackendHealthManager] Starting on Local Backend.');
        return;
      } else {
        Log.v('[BackendHealthManager] Discovery ping failed.');
      }
      Log.d('[BackendHealthManager] Local not detected. Using Cloud.');
    }

    _usingLocal = false;
    _usingRailway = true; // Always start on Railway (FAST)
    _startRecoveryCheck();
  }

  String _convertToTargetUrl(String originalUrl, String targetBase) {
    if (originalUrl.startsWith(ApiConstants.localUrl)) {
      return originalUrl.replaceFirst(ApiConstants.localUrl, targetBase);
    }
    if (originalUrl.startsWith(_renderBase)) {
      return originalUrl.replaceFirst(_renderBase, targetBase);
    }
    if (originalUrl.startsWith(_railwayBase)) {
      return originalUrl.replaceFirst(_railwayBase, targetBase);
    }
    return originalUrl;
  }

  Future<http.Response> executeWithFallback(
    String originalUrl,
    Future<http.Response> Function(String url) requestExecutor,
  ) async {
    // RACE STRATEGY:
    // If Local is preferred, we launch Local and Railway (Cloud) almost simultaneously.
    if (_usingLocal) {
      final Completer<http.Response> completer = Completer();
      bool resolved = false;

      // 1. Local Request (Primary)
      final localFuture = requestExecutor(
        originalUrl,
      ).timeout(const Duration(seconds: 12));

      // 2. Cloud Request (Race Start after 3.5s delay for Local)
      // We give Local more time because it might be fetching from external APIs (OTM/Google)
      Timer? cloudTimer;
      cloudTimer = Timer(const Duration(milliseconds: 3500), () async {
        if (!resolved) {
          try {
            // Always race with Railway first because it is always ON (instant)
            final cloudUrl = _convertToTargetUrl(originalUrl, _railwayBase);
            final cloudResponse = await requestExecutor(
              cloudUrl,
            ).timeout(_renderRequestTimeout);
            if (!resolved) {
              resolved = true;
              completer.complete(cloudResponse);
              Log.i(
                '[BackendHealthManager] Local is slow/down. Cloud (Railway) won the race.',
              );
              _usingLocal = false;
              _usingRailway = true;
              _startRecoveryCheck();
            }
          } catch (_) {
            /* ignore cloud failures in race */
          }
        }
      });

      try {
        final localResponse = await localFuture;
        if (!resolved) {
          resolved = true;
          cloudTimer.cancel();
          completer.complete(localResponse);
          return localResponse;
        }
      } catch (e) {
        if (!resolved) {
          _usingLocal = false;
          _usingRailway = true;
          _startRecoveryCheck();
          // Let the cloud timer/future handle it or throw if it also fails
        }
      }

      return await completer.future;
    }

    // ON CLOUD:
    // Try current cloud (Railway is preferred start).
    // Fallback internally if the current cloud is slow.
    final cloudBase = _usingRailway ? _railwayBase : _renderBase;
    final cloudUrl = _convertToTargetUrl(originalUrl, cloudBase);

    try {
      return await requestExecutor(cloudUrl).timeout(_renderRequestTimeout);
    } catch (e) {
      Log.w(
        '[BackendHealthManager] 🔄 Cloud request failed/timedout. Trying final fallback.',
      );
      _usingRailway = !_usingRailway; // Flip between Render/Railway
      final finalBase = _usingRailway ? _railwayBase : _renderBase;
      final finalUrl = _convertToTargetUrl(originalUrl, finalBase);
      return await requestExecutor(
        finalUrl,
      ).timeout(const Duration(seconds: 30));
    }
  }

  void _startRecoveryCheck() {
    _recoveryTimer?.cancel();
    _checkBackendsSilently();

    final interval = _useLocalPreference && !_usingLocal
        ? _localDiscoveryInterval
        : _renderCheckInterval;

    _recoveryTimer = Timer.periodic(interval, (_) {
      _checkBackendsSilently();
    });
  }

  Future<void> _checkBackendsSilently() async {
    if (_useLocalPreference && !_usingLocal) {
      final localHealthUrl = ApiConstants.localUrl.replaceFirst(
        '/api',
        '/health',
      );
      final localUp = await _pingBackend(
        localHealthUrl,
        const Duration(seconds: 1),
      );
      if (localUp) {
        Log.i(
          '[BackendHealthManager] Local backend detected! Switching to Local.',
        );
        _usingLocal = true;
        _usingRailway = false;
        _recoveryTimer?.cancel();
        _recoveryTimer = null;
        return;
      }
    }

    if (_usingLocal) return;

    // Check if Render is back to take over from Railway
    if (_usingRailway) {
      final alive = await _pingBackend(_renderHealth, _renderPingTimeout);
      if (alive) {
        _usingRailway = false;
        Log.d('[BackendHealthManager] Render is UP → Switch back to Render');
      }
    }
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return executeWithFallback(
      url,
      (tUrl) => http.get(Uri.parse(tUrl), headers: headers),
    );
  }

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return executeWithFallback(
      url,
      (tUrl) => http.post(Uri.parse(tUrl), headers: headers, body: body),
    );
  }

  Future<http.Response> patch(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return executeWithFallback(
      url,
      (tUrl) => http.patch(Uri.parse(tUrl), headers: headers, body: body),
    );
  }

  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return executeWithFallback(
      url,
      (tUrl) => http.put(Uri.parse(tUrl), headers: headers, body: body),
    );
  }

  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    return executeWithFallback(
      url,
      (tUrl) => http.delete(Uri.parse(tUrl), headers: headers),
    );
  }

  Future<http.StreamedResponse> sendMultipart(
    Future<http.MultipartRequest> Function() requestBuilder,
  ) async {
    if (_usingLocal || _usingRailway) {
      try {
        final req = await requestBuilder();
        final targetBase = _usingLocal
            ? ApiConstants.localUrl
            : (_usingRailway ? _railwayBase : _renderBase);
        final targetUrl = _convertToTargetUrl(req.url.toString(), targetBase);

        final finalReq = http.MultipartRequest(
          req.method,
          Uri.parse(targetUrl),
        );
        finalReq.headers.addAll(req.headers);
        finalReq.fields.addAll(req.fields);
        finalReq.files.addAll(req.files);

        return await finalReq.send().timeout(const Duration(seconds: 25));
      } catch (e) {
        if (_usingLocal) {
          _usingLocal = false;
          _usingRailway = true;
          _startRecoveryCheck();
          return sendMultipart(requestBuilder);
        }
        rethrow;
      }
    }
    final req = await requestBuilder();
    return await req.send().timeout(const Duration(seconds: 15));
  }

  Future<bool> _pingBackend(String url, Duration timeout) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(timeout, onTimeout: () => http.Response('Timeout', 408));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }
}
