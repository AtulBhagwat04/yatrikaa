import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../utils/logger_service.dart';

/// WikipediaService — Calls Wikipedia APIs directly from the Flutter client.
/// ✅ Completely FREE. No API key. No sign-up. No backend required.
///
/// Smart two-stage filtering:
///   Stage 1 → REJECT: universities, politicians, schools, neighborhoods, companies
///   Stage 2 → ACCEPT: only travel-relevant places (temples, forts, lakes, palaces…)
class WikipediaService {
  static const String _geoSearchBase = 'https://en.wikipedia.org/w/api.php';
  static const String _summaryBase =
      'https://en.wikipedia.org/api/rest_v1/page/summary';

  static final WikipediaService _instance = WikipediaService._internal();
  factory WikipediaService() => _instance;
  WikipediaService._internal();

  // ── Reject patterns (Wikipedia description field) ──────────────────────────
  // These descriptions clearly indicate non-tourist content.
  static final List<RegExp> _rejectPatterns = [
    RegExp(r'\bcollege\b', caseSensitive: false),
    RegExp(r'\binstitute\b', caseSensitive: false),
    RegExp(r'\binstitution\b', caseSensitive: false),
    RegExp(r'\bschool\b', caseSensitive: false),
    RegExp(r'\bhospital\b', caseSensitive: false),
    RegExp(r'\bclinic\b', caseSensitive: false),
    RegExp(r'\bpolitician\b', caseSensitive: false),
    RegExp(r'\bminister\b', caseSensitive: false),
    RegExp(r'\bactor\b', caseSensitive: false),
    RegExp(r'\bactress\b', caseSensitive: false),
    RegExp(r'\bsinger\b', caseSensitive: false),
    RegExp(r'\bwriter\b', caseSensitive: false),
    RegExp(r'\bjournalist\b', caseSensitive: false),
    RegExp(r'\bneighbourhood\b', caseSensitive: false),
    RegExp(r'\bneighborhood\b', caseSensitive: false),
    RegExp(r'\blocality\b', caseSensitive: false),
    RegExp(r'\bmunicipality\b', caseSensitive: false),
    RegExp(r'\bsuburb\b', caseSensitive: false),
    RegExp(r'\bvillage in\b', caseSensitive: false),
    RegExp(r'\btown in\b', caseSensitive: false),
    RegExp(r'\bcompany\b', caseSensitive: false),
    RegExp(r'\bcorporation\b', caseSensitive: false),
    RegExp(r'\bfactory\b', caseSensitive: false),
    RegExp(r'\brailway station\b', caseSensitive: false),
    RegExp(r'\btrain station\b', caseSensitive: false),
    RegExp(r'\bairport\b', caseSensitive: false),
    RegExp(r'\bbus stand\b', caseSensitive: false),
    RegExp(r'\bgovernment office\b', caseSensitive: false),
    RegExp(r'\badministrative\b', caseSensitive: false),
    RegExp(r'\bcricketer\b', caseSensitive: false),
    RegExp(r'\bfilm\b', caseSensitive: false),
    RegExp(r'\bagency\b', caseSensitive: false),
    RegExp(r'\bstate$', caseSensitive: false),
    RegExp(r'\bcensus.designated\b', caseSensitive: false),
  ];

  // ── Accept patterns (travel/tourist relevant) ──────────────────────────────
  static final List<RegExp> _acceptPatterns = [
    RegExp(r'\btemple\b', caseSensitive: false),
    RegExp(r'\bmandir\b', caseSensitive: false),
    RegExp(r'\bshrine\b', caseSensitive: false),
    RegExp(r'\bmosque\b', caseSensitive: false),
    RegExp(r'\bmasjid\b', caseSensitive: false),
    RegExp(r'\bchurch\b', caseSensitive: false),
    RegExp(r'\bdargah\b', caseSensitive: false),
    RegExp(r'\bfort\b', caseSensitive: false),
    RegExp(r'\bfortress\b', caseSensitive: false),
    RegExp(r'\bcastle\b', caseSensitive: false),
    RegExp(r'\bpalace\b', caseSensitive: false),
    RegExp(r'\bmahal\b', caseSensitive: false),
    RegExp(r'\bwada\b', caseSensitive: false),
    RegExp(r'\blake\b', caseSensitive: false),
    RegExp(r'\btalav\b', caseSensitive: false),
    RegExp(r'\breservoir\b', caseSensitive: false),
    RegExp(r'\bdam\b', caseSensitive: false),
    RegExp(r'\bwaterfall\b', caseSensitive: false),
    RegExp(r'\bfalls\b', caseSensitive: false),
    RegExp(r'\bbeach\b', caseSensitive: false),
    RegExp(r'\bcoast\b', caseSensitive: false),
    RegExp(r'\bcave\b', caseSensitive: false),
    RegExp(r'\bcavern\b', caseSensitive: false),
    RegExp(r'\bmuseum\b', caseSensitive: false),
    RegExp(r'\bgallery\b', caseSensitive: false),
    RegExp(r'\bmonument\b', caseSensitive: false),
    RegExp(r'\bheritage\b', caseSensitive: false),
    RegExp(r'\barchaeological\b', caseSensitive: false),
    RegExp(r'\bruins\b', caseSensitive: false),
    RegExp(r'\bhistorical\b', caseSensitive: false),
    RegExp(r'\bpilgrimage\b', caseSensitive: false),
    RegExp(r'\btourist\b', caseSensitive: false),
    RegExp(r'\bwildlife sanctuary\b', caseSensitive: false),
    RegExp(r'\bnational park\b', caseSensitive: false),
    RegExp(r'\bhill station\b', caseSensitive: false),
    RegExp(r'\bpeak\b', caseSensitive: false),
    RegExp(r'\bghats\b', caseSensitive: false),
    RegExp(r'\bghat\b', caseSensitive: false),
    RegExp(r'\bvalley\b', caseSensitive: false),
    RegExp(r'\bbotanical\b', caseSensitive: false),
    RegExp(r'\bzoo\b', caseSensitive: false),
    RegExp(r'\bbazaar\b', caseSensitive: false),
    RegExp(r'\bstupa\b', caseSensitive: false),
    RegExp(r'\bgate\b', caseSensitive: false),
    RegExp(r'\briver\b', caseSensitive: false),
    RegExp(r'\btank\b', caseSensitive: false),
    RegExp(r'\btower\b', caseSensitive: false),
    RegExp(r'\bbridge\b', caseSensitive: false),
    RegExp(r'\bplaza\b', caseSensitive: false),
    RegExp(r'\bsquare\b', caseSensitive: false),
    RegExp(r'\bcathedral\b', caseSensitive: false),
    RegExp(r'\babbey\b', caseSensitive: false),
    RegExp(r'\bmonastery\b', caseSensitive: false),
    RegExp(r'\bpagoda\b', caseSensitive: false),
    RegExp(r'\baquarium\b', caseSensitive: false),
    RegExp(r'\bplanetarium\b', caseSensitive: false),
    RegExp(r'\blighthouse\b', caseSensitive: false),
    RegExp(r'\bamusement\b', caseSensitive: false),
    RegExp(r'\btheme park\b', caseSensitive: false),
    RegExp(r'\bgarden\b', caseSensitive: false),
    RegExp(r'\bpark\b', caseSensitive: false),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetch nearby TRAVEL-RELEVANT famous places from Wikipedia.
  Future<List<PlaceModel>> getNearbyPlaces(
    double lat,
    double lng, {
    int radius = 5000,
    int limit = 20, // Fetch more candidates to compensate for filtering
  }) async {
    try {
      // Step 1: GeoSearch
      final geoArticles = await _geoSearch(lat, lng, radius: radius, limit: limit);
      if (geoArticles.isEmpty) return [];

      // Step 2: Fetch summaries in parallel
      final futures = geoArticles.map((a) => _fetchSummary(a)).toList();
      final results = await Future.wait(futures, eagerError: false);

      final places = <PlaceModel>[];
      for (final place in results) {
        if (place != null &&
            place.images.isNotEmpty &&
            place.images.first.startsWith('http')) {
          places.add(place);
        }
      }

      Log.d('[Wikipedia] ${places.length} travel places found (of ${geoArticles.length} candidates)');
      return places;
    } catch (e) {
      Log.e('[Wikipedia] getNearbyPlaces error: $e');
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _geoSearch(
    double lat,
    double lng, {
    int radius = 5000,
    int limit = 20,
  }) async {
    final uri = Uri.parse(_geoSearchBase).replace(queryParameters: {
      'action': 'query',
      'list': 'geosearch',
      'gscoord': '$lat|$lng',
      'gsradius': '${radius.clamp(100, 10000)}',
      'gslimit': '$limit',
      'format': 'json',
      'origin': '*',
    });

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];
    final data = json.decode(response.body);
    final geosearch = data['query']?['geosearch'] as List? ?? [];
    return geosearch.cast<Map<String, dynamic>>();
  }

  Future<PlaceModel?> _fetchSummary(Map<String, dynamic> article) async {
    try {
      final title = article['title'] as String? ?? '';
      if (title.isEmpty) return null;

      final encodedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final response = await http
          .get(Uri.parse('$_summaryBase/$encodedTitle'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final summary = json.decode(response.body) as Map<String, dynamic>;

      final description = summary['description'] as String? ?? '';
      final extract = summary['extract'] as String? ?? '';

      // ── Stage 1: Hard reject non-travel content or city pages ───────────
      if (_isRejected(title, description)) {
        Log.d('[Wikipedia] ❌ Rejected: "$title" → "$description"');
        return null;
      }

      // ── Stage 2: Require at least one travel keyword ─────────────────────
      if (!_isTravelRelevant(description, extract, title)) {
        Log.d('[Wikipedia] ⚠️ Skipped (not travel): "$title" → "$description"');
        return null;
      }

      return _mapToPlaceModel(article, summary);
    } catch (e) {
      return null;
    }
  }

  bool _isRejected(String title, String description) {
    final text = description.toLowerCase();
    final titleLower = title.toLowerCase();

    // 1. Hard rejects from patterns
    if (_rejectPatterns.any((p) => p.hasMatch(description))) return true;

    // 2. Reject region-level "overview" pages (e.g. "Kolhapur", "Kolhapur district")
    // Use regex to catch variations: "City in Maharashtra", "City in India", "District in..."
    final regionalPattern =
        RegExp(r'\b(city|district|town|collectorate|division|taluka|subdivision)\s+in\s+', caseSensitive: false);
    if (regionalPattern.hasMatch(text)) {
      // If the title is short (likely just the city name) and description says it's a region, reject it.
      if (titleLower.length < 25) return true;
    }

    if (titleLower.endsWith(' district')) return true;
    if (titleLower.contains(' taluka')) return true;
    if (titleLower.contains(' subdivision')) return true;

    return false;
  }

  bool _isTravelRelevant(String description, String extract, String name) {
    final shortText = '$description $name';
    final fullText = '$description $extract $name';
    return _acceptPatterns.any((p) => p.hasMatch(shortText)) ||
        _acceptPatterns.any((p) => p.hasMatch(fullText));
  }

  PlaceModel? _mapToPlaceModel(
    Map<String, dynamic> article,
    Map<String, dynamic> summary,
  ) {
    final lat = (article['lat'] as num?)?.toDouble() ??
        (summary['coordinates']?['lat'] as num?)?.toDouble();
    final lng = (article['lon'] as num?)?.toDouble() ??
        (summary['coordinates']?['lon'] as num?)?.toDouble();

    if (lat == null || lng == null) return null;

    final name = summary['title'] as String? ?? article['title'] as String? ?? '';
    if (name.isEmpty) return null;

    final description = summary['description'] as String? ?? '';
    final extract = summary['extract'] as String? ?? '';

    final thumbnail = summary['thumbnail'] as Map<String, dynamic>?;
    final imageUrl = thumbnail?['source'] as String?;
    final images = imageUrl != null ? [imageUrl] : <String>[];

    final distMeters = (article['dist'] as num?)?.toDouble();
    final distKm = distMeters != null ? distMeters / 1000 : null;

    final category = _inferCategory(description, extract, name);

    return PlaceModel(
      id: 'wiki_${article['pageid']}',
      name: name,
      address: description.isNotEmpty ? description : null,
      city: _extractCity(description),
      category: category,
      description: extract.isNotEmpty
          ? extract.substring(0, extract.length.clamp(0, 300))
          : null,
      images: images,
      rating: 4.2,
      userRatingsTotal: 0,
      photoReference: imageUrl,
      lat: lat,
      lng: lng,
      distance: distKm,
      website:
          'https://en.wikipedia.org/wiki/${Uri.encodeComponent(name.replaceAll(' ', '_'))}',
    );
  }

  String _inferCategory(String description, String extract, String name) {
    final text = '$description $extract $name'.toLowerCase();
    if (text.contains('fort') || text.contains('fortress') || text.contains('castle')) return 'Fort';
    if (text.contains('temple') || text.contains('mandir') || text.contains('shrine') || text.contains('dargah') || text.contains('mosque') || text.contains('church') || text.contains('cathedral') || text.contains('monastery') || text.contains('pagoda')) return 'Religious Site';
    if (text.contains('beach') || text.contains('coast') || text.contains('shore') || text.contains('island')) return 'Beach';
    if (text.contains('waterfall') || text.contains('falls')) return 'Waterfall';
    if (text.contains('cave') || text.contains('cavern')) return 'Cave';
    if (text.contains('museum') || text.contains('gallery') || text.contains('exhibition')) return 'Museum';
    if (text.contains('lake') || text.contains('talav') || text.contains('dam') || text.contains('reservoir') || text.contains('river')) return 'Water Body';
    if (text.contains('mountain') || text.contains('hill') || text.contains('peak') || text.contains('ghat') || text.contains('valley')) return 'Nature';
    if (text.contains('wildlife') || text.contains('sanctuary') || text.contains('national park') || text.contains('reserve')) return 'Wildlife';
    if (text.contains('palace') || text.contains('mahal') || text.contains('wada') || text.contains('heritage') || text.contains('monument') || text.contains('historical') || text.contains('archaeological') || text.contains('tower') || text.contains('bridge')) return 'Heritage';
    if (text.contains('garden') || text.contains('botanical') || text.contains('zoo') || text.contains('park') || text.contains('plaza') || text.contains('square')) return 'Park';
    if (text.contains('market') || text.contains('bazaar') || text.contains('mall')) return 'Market';
    return 'Tourist Attraction';
  }

  String? _extractCity(String description) {
    if (description.isEmpty) return null;
    final inIdx = description.indexOf(' in ');
    if (inIdx != -1) {
      final rest = description.substring(inIdx + 4);
      return rest.split(',').first.trim();
    }
    return description.split(',').first.trim();
  }
}
