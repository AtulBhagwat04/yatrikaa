const axios = require('axios');

/**
 * WikipediaService
 * Uses the free Wikipedia GeoSearch + REST Summary APIs.
 * NO API KEY REQUIRED. No rate limits for reasonable use.
 *
 * Smart filtering: Only returns travel-relevant places (temples, forts, lakes,
 * palaces, waterfalls, etc.) — rejects universities, politicians, schools,
 * neighborhoods, companies, and other non-tourist content.
 */
class WikipediaService {
  constructor() {
    this.geoSearchUrl = 'https://en.wikipedia.org/w/api.php';
    this.summaryUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary';

    // ─── REJECT: Descriptions that match these → not a tourist place ──────────
    // Wikipedia descriptions are short & precise (e.g. "Autonomous university in Kolhapur")
    // so we can reliably reject non-travel content here.
    this.REJECT_PATTERNS = [
      /\bcollege\b/i,
      /\binstitute\b/i,
      /\binstitution\b/i,
      /\bschool\b/i,
      /\bhospital\b/i,
      /\bclinic\b/i,
      /\bpolitician\b/i,
      /\bminister\b/i,
      /\bactor\b/i,
      /\bactress\b/i,
      /\bsinger\b/i,
      /\bwriter\b/i,
      /\bauthor\b/i,
      /\bjournalist\b/i,
      /\bneighbourhood\b/i,
      /\bneighborhood\b/i,
      /\blocality\b/i,
      /\bmunicipality\b/i,
      /\bsuburb\b/i,
      /\bvillage in\b/i,
      /\btown in\b/i,
      /\bhamlet\b/i,
      /\bcensus-designated\b/i,
      /\bcompany\b/i,
      /\bcorporation\b/i,
      /\bfactory\b/i,
      /\bindustry\b/i,
      /\bnewspaper\b/i,
      /\btelevision\b/i,
      /\bradio station\b/i,
      /\bairport\b/i,
      /\brailway station\b/i,
      /\btrain station\b/i,
      /\bbus stand\b/i,
      /\bgovernment office\b/i,
      /\badministrative\b/i,
      /\bpincode\b/i,
      /\bpostcode\b/i,
      /\bdistrict headquarters\b/i,
      /\bagency\b/i,
      /\bstate\b$/i, // "Kolhapur State" -> rejected if it's the entity
      /\bcricketer\b/i,
      /\bfilm\b/i,
    ];

    // ─── ACCEPT: At least one of these must match description or extract ──────
    // These are clearly travel/tourist relevant.
    this.ACCEPT_PATTERNS = [
      /\btemple\b/i,
      /\bmandir\b/i,
      /\bshrine\b/i,
      /\bmosque\b/i,
      /\bchurch\b/i,
      /\bmasjid\b/i,
      /\bdargah\b/i,
      /\bfort\b/i,
      /\bfortress\b/i,
      /\bcastle\b/i,
      /\bpalace\b/i,
      /\bmahal\b/i,
      /\bwada\b/i,
      /\blake\b/i,
      /\btalav\b/i,
      /\breservoir\b/i,
      /\bdam\b/i,
      /\bwaterfall\b/i,
      /\bfalls\b/i,
      /\bbeach\b/i,
      /\bcoast\b/i,
      /\bcave\b/i,
      /\bcavern\b/i,
      /\bmuseum\b/i,
      /\bgallery\b/i,
      /\bmonument\b/i,
      /\bheritage\b/i,
      /\barchaeological\b/i,
      /\bruins\b/i,
      /\bhistorical\b/i,
      /\bpilgrimage\b/i,
      /\btourist\b/i,
      /\bwildlife sanctuary\b/i,
      /\bnational park\b/i,
      /\bbiosphere\b/i,
      /\bforest reserve\b/i,
      /\bhill station\b/i,
      /\bpeak\b/i,
      /\bghats\b/i,
      /\bvalley\b/i,
      /\bbotanical garden\b/i,
      /\bzoological\b/i,
      /\bzoo\b/i,
      /\bstadium\b/i,   // famous stadiums are tourist attractions
      /\bampitheatre\b/i,
      /\bmarket\b/i,    // famous markets like Mahabaleshwar market
      /\bbazaar\b/i,
      /\bchowk\b/i,    // famous chowks
      /\bgate\b/i,     // famous gates/arches (e.g. Gateway of India)
      /\barch\b/i,
      /\bghat\b/i,     // river ghats
      /\briver\b/i,
      /\bwaterbody\b/i,
      /\btank\b/i,     // temple tanks
      /\bStupa\b/i,
      /\btower\b/i,
      /\bbridge\b/i,
      /\bplaza\b/i,
      /\bsquare\b/i,
      /\bcathedral\b/i,
      /\babbey\b/i,
      /\bmonastery\b/i,
      /\bpagoda\b/i,
      /\baquarium\b/i,
      /\bplanetarium\b/i,
      /\blighthouse\b/i,
      /\b观音\b/i, // support some common multi-lingual keywords if needed, but keeping primarily English for en.wikipedia
      /\bamusement\b/i,
      /\btheme park\b/i,
      /\bgarden\b/i,
      /\bpark\b/i,
      /\brailway\b/i, // famous railways like Darjeeling Himalayan Railway
    ];
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  async getNearbyArticles(lat, lng, radius = 5000, limit = 20) {
    const response = await axios.get(this.geoSearchUrl, {
      params: {
        action: 'query',
        list: 'geosearch',
        gscoord: `${lat}|${lng}`,
        gsradius: Math.min(radius, 10000),
        gslimit: limit,
        format: 'json',
        origin: '*',
      },
      timeout: 8000,
    });
    return response.data?.query?.geosearch || [];
  }

  async getPageSummary(title) {
    const encodedTitle = encodeURIComponent(title.replace(/ /g, '_'));
    const response = await axios.get(`${this.summaryUrl}/${encodedTitle}`, {
      timeout: 6000,
      headers: { accept: 'application/json' },
    });
    return response.data;
  }

  /**
   * Main: get nearby TRAVEL-RELEVANT famous places from Wikipedia.
   * Fetches more candidates (20) then applies smart travel filter.
   */
  async getNearbyPlaces(lat, lng, radius = 20000) {
    try {
      // Fetch 30 candidates — strict filtering reduces count significantly
      const articles = await this.getNearbyArticles(lat, lng, radius, 30);
      if (!articles.length) return { status: 'OK', results: [] };

      // Step 2: Fetch summaries in parallel
      const summaryPromises = articles.map(async (article) => {
        try {
          const summary = await this.getPageSummary(article.title);
          return { article, summary };
        } catch {
          return { article, summary: null };
        }
      });

      const settled = await Promise.allSettled(summaryPromises);
      const results = [];

      for (const item of settled) {
        if (item.status !== 'fulfilled') continue;
        const { article, summary } = item.value;
        if (!summary) continue;

        const description = summary.description || '';
        const extract = summary.extract || '';

        // ── Stage 1: Hard reject non-travel content or city overview pages ──
        if (this._isRejected(article.title, description)) {
          console.log(`[Wikipedia] ❌ Rejected: "${article.title}" → "${description}"`);
          continue;
        }

        // ── Stage 2: Require at least one travel keyword ─────────
        if (!this._isTravelRelevant(description, extract, article.title)) {
          console.log(`[Wikipedia] ⚠️  Skipped (not travel): "${article.title}" → "${description}"`);
          continue;
        }

        const mapped = this.mapToPlaceFormat(article, summary);

        // ── Stage 3: Must have a real image ───────────────────────
        if (mapped && mapped.photos && mapped.photos.length > 0) {
          console.log(`[Wikipedia] ✅ Accepted: "${article.title}" → "${description}"`);
          results.push(mapped);
        }
      }

      console.log(`[Wikipedia] Result: ${results.length} travel places from ${articles.length} candidates`);
      return { status: 'OK', results };
    } catch (error) {
      console.error('[WikipediaService] getNearbyPlaces error:', error.message);
      return { status: 'ERROR', results: [] };
    }
  }

  // ── Filtering helpers ──────────────────────────────────────────────────────

  /**
   * Returns true if the description matches a NON-travel pattern.
   * Uses only the short description field (very precise).
   */
  _isRejected(title, description) {
    const text = (description || '').toLowerCase();
    const titleLower = title.toLowerCase();

    // 1. Hard rejects from patterns
    if (this.REJECT_PATTERNS.some((pattern) => pattern.test(text))) return true;

    // 2. Reject region-level "overview" pages (e.g. "Kolhapur", "Kolhapur district")
    // Use regex to catch variations: "City in Maharashtra", "City in India", "District in..."
    const regionalPattern = /\b(city|district|town|collectorate|division|taluka|subdivision)\s+in\s+/i;
    if (regionalPattern.test(text)) {
      // If the title is short (likely just the city name) and description says it's a "City in...", reject it.
      if (titleLower.length < 25) return true;
    }

    // Direct title matches for common administrative noise
    if (titleLower.endsWith(' district')) return true;
    if (titleLower.includes(' taluka')) return true;
    if (titleLower.includes(' subdivision')) return true;

    return false;
  }

  /**
   * Returns true if description OR extract contains a travel keyword.
   */
  _isTravelRelevant(description, extract, name) {
    const text = `${description} ${name}`.toLowerCase(); // description is most reliable
    const fullText = `${description} ${extract} ${name}`.toLowerCase();
    // Check description+name first (most precise), then full text
    return (
      this.ACCEPT_PATTERNS.some((p) => p.test(text)) ||
      this.ACCEPT_PATTERNS.some((p) => p.test(fullText))
    );
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  mapToPlaceFormat(article, summary) {
    const lat = article.lat ?? summary?.coordinates?.lat;
    const lng = article.lon ?? summary?.coordinates?.lon;
    if (!lat || !lng) return null;

    const name = summary?.title || article.title;
    const description = summary?.description || '';
    const extract = summary?.extract || '';
    const thumbnail = summary?.thumbnail?.source || null;
    const distanceKm = article.dist ? article.dist / 1000 : null;
    const category = this._inferCategory(description, extract, name);

    const photos = thumbnail
      ? [{ photo_reference: thumbnail, width: summary?.thumbnail?.width || 320, height: summary?.thumbnail?.height || 180 }]
      : [];

    return {
      place_id: `wiki_${article.pageid}`,
      name,
      formatted_address: description || `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
      city: this._extractCity(description),
      geometry: { location: { lat, lng } },
      rating: 4.2,
      user_ratings_total: 0,
      photos,
      images: thumbnail ? [thumbnail] : [],
      types: [category.toLowerCase().replace(/ /g, '_')],
      category,
      editorial_summary: { overview: extract ? extract.substring(0, 300) : '' },
      distanceCalculated: distanceKm,
      website: `https://en.wikipedia.org/wiki/${encodeURIComponent(article.title.replace(/ /g, '_'))}`,
      source: 'Wikipedia',
    };
  }

  _inferCategory(description, extract, name) {
    const text = `${description} ${extract} ${name}`.toLowerCase();
    if (text.includes('fort') || text.includes('fortress') || text.includes('castle')) return 'Fort';
    if (text.includes('temple') || text.includes('mandir') || text.includes('shrine') || text.includes('dargah') || text.includes('mosque') || text.includes('church') || text.includes('masjid') || text.includes('cathedral') || text.includes('monastery') || text.includes('pagoda') || text.includes('abbey')) return 'Religious Site';
    if (text.includes('beach') || text.includes('coast') || text.includes('shore') || text.includes('island')) return 'Beach';
    if (text.includes('waterfall') || text.includes('falls')) return 'Waterfall';
    if (text.includes('cave') || text.includes('cavern')) return 'Cave';
    if (text.includes('museum') || text.includes('gallery') || text.includes('exhibition')) return 'Museum';
    if (text.includes('lake') || text.includes('talav') || text.includes('dam') || text.includes('reservoir') || text.includes('river')) return 'Water Body';
    if (text.includes('mountain') || text.includes('hill') || text.includes('peak') || text.includes('ghat') || text.includes('valley')) return 'Nature';
    if (text.includes('wildlife') || text.includes('sanctuary') || text.includes('national park') || text.includes('reserve')) return 'Wildlife';
    if (text.includes('palace') || text.includes('mahal') || text.includes('wada') || text.includes('heritage') || text.includes('monument') || text.includes('historical') || text.includes('archaeological') || text.includes('tower') || text.includes('bridge')) return 'Heritage';
    if (text.includes('garden') || text.includes('botanical') || text.includes('zoo') || text.includes('park') || text.includes('plaza') || text.includes('square')) return 'Park';
    if (text.includes('market') || text.includes('bazaar') || text.includes('chowk') || text.includes('mall') || text.includes('district')) return 'Market';
    return 'Tourist Attraction';
  }

  _extractCity(description) {
    if (!description) return '';
    const inIdx = description.indexOf(' in ');
    if (inIdx !== -1) {
      const rest = description.substring(inIdx + 4);
      return rest.split(',')[0].trim();
    }
    return description.split(',')[0]?.trim() || '';
  }
}

module.exports = new WikipediaService();
