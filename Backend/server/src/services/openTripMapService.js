const axios = require('axios');
const config = require('../config');

class OpenTripMapService {
  constructor() {
    this.apiKey = config.OPEN_TRIP_MAP_API;
    this.baseUrl = 'https://api.opentripmap.com/0.1/en/places';

    // Mapping app categories to OpenTripMap kind strings
    this.CATEGORY_MAP = {
      'Forts': 'forts,castles,historic_architecture',
      'Beaches': 'beaches,nature_reserves',
      'Temples': 'hindu_temples,temples,other_temples,religion',
      'Hill Stations': 'mountains,view_points,nature_reserves,natural',
      'Caves': 'caves,geological_formations',
      'Waterfalls': 'waterfalls,natural',
      'Museums': 'museums,art_galleries,local_museums',
      'Wildlife': 'nature_reserves,wildlife_sanctuaries,zoos',
      'Lakes': 'lakes,rivers,water',
      'Trekking': 'mountains,nature_reserves,canyons',
      'UNESCO Sites': 'unesco',
      'Spiritual': 'religion,monasteries,mosques,churches,cathedrals'
    };

    // Approximate bounding box for Maharashtra
    this.MAHARASHTRA_BBOX = {
      lon_min: 72.6,
      lat_min: 15.6,
      lon_max: 80.9,
      lat_max: 22.0
    };
  }

  /**
   * Search for places by category across a large area (Maharashtra)
   */
  async getPlacesByCategory(category, limit = 20) {
    try {
      const kinds = this.CATEGORY_MAP[category] || 'interesting_places';
      
      const response = await axios.get(`${this.baseUrl}/bbox`, {
        params: {
          lon_min: this.MAHARASHTRA_BBOX.lon_min,
          lat_min: this.MAHARASHTRA_BBOX.lat_min,
          lon_max: this.MAHARASHTRA_BBOX.lon_max,
          lat_max: this.MAHARASHTRA_BBOX.lat_max,
          kinds: kinds,
          format: 'json',
          apikey: this.apiKey
        }
      });

      const rawResults = response.data || [];
      const filtered = rawResults.filter(p => p.name && p.name.trim() !== '');
      
      // Select top results by rate
      const sorted = filtered.sort((a, b) => (b.rate || 0) - (a.rate || 0));
      const topResults = sorted.slice(0, limit);

      const detailedResults = [];
      // Fetch details for top 10 results to provide rich data and images
      for (let i = 0; i < Math.min(topResults.length, 10); i++) {
        try {
          if (i > 0) await new Promise(resolve => setTimeout(resolve, 350));
          const details = await this.getPlaceDetails(topResults[i].xid);
          detailedResults.push(this.mapToGoogleFormat(details));
        } catch (err) {
          detailedResults.push(this.mapBasicToGoogleFormat(topResults[i]));
        }
      }

      // Add the rest as basic
      for (let i = 10; i < topResults.length; i++) {
        detailedResults.push(this.mapBasicToGoogleFormat(topResults[i]));
      }

      return { status: "OK", results: detailedResults };
    } catch (error) {
      console.error("OpenTripMap BBox Error:", error.message);
      return { status: "ERROR", results: [] };
    }
  }

  /**
   * Calculates Haversine distance between two coordinates in kilometers
   */
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of Earth in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  async getNearbyPlaces(lat, lng, radius = 5000, category = null) {
    try {
      // Determine kinds from category mapping
      let kinds = 'interesting_places';
      if (category && this.CATEGORY_MAP[category]) {
        kinds = this.CATEGORY_MAP[category];
      }

      // 1. Get list of places within radius
      let response;
      try {
        response = await axios.get(`${this.baseUrl}/radius`, {
          params: {
            radius: Math.min(radius, 50000), 
            lon: lng,
            lat: lat,
            kinds: kinds, // Use mapped kinds
            format: 'json',
            apikey: this.apiKey
          }
        });
      } catch (radiusErr) {
        if (radiusErr.response && radiusErr.response.status === 429) {
          console.error("OpenTripMap Radius call rate limited (429)");
          return { status: "OK", results: [] }; // Return empty but don't crash
        }
        throw radiusErr;
      }

      const rawResults = response.data || [];
      
      // 2. Filter for places with names
      const filtered = rawResults.filter(p => p.name && p.name.trim() !== '');

      // 3. Limit processing to top 15 results
      const topResults = filtered.slice(0, 15);
      
      const detailedResults = [];
      let rateLimited = false;
      
      // 4. Fetch details for only the top 4 results to avoid 429 Too Many Requests
      // 4. Fetch details for the top results to provide images and descriptions
      // Increased to 10 results since we now have a longer frontend timeout
      for (let i = 0; i < topResults.length; i++) {
        const p = topResults[i];
        
        if (i < 10 && !rateLimited) {
          try {
            if (i > 0) await new Promise(resolve => setTimeout(resolve, 350)); 
            
            const details = await this.getPlaceDetails(p.xid);
            const mapped = this.mapToGoogleFormat(details);
            mapped.distanceCalculated = p.dist / 1000; // Convert METERS to KM
            detailedResults.push(mapped);
            continue;
          } catch (err) {
            console.error(`Failed to fetch details for ${p.xid}:`, err.message);
            if (err.message.includes('429') || (err.response && err.response.status === 429)) {
              rateLimited = true;
              console.warn("Throttling: OpenTripMap rate limit reached. Using basic data for remaining results.");
            }
          }
        }

        // Fallback to basic info if we hit rate limit or passed the fetch limit
        const basic = this.mapBasicToGoogleFormat(p);
        basic.distanceCalculated = p.dist / 1000; // Convert METERS to KM
        detailedResults.push(basic);
      }

      return {
        status: "OK",
        results: detailedResults
      };
    } catch (error) {
      console.error("OpenTripMap API Error:", error.message);
      throw new Error(`Failed to fetch nearby places from OpenTripMap: ${error.message}`);
    }
  }

  async getPlaceDetails(xid) {
    try {
      const response = await axios.get(`${this.baseUrl}/xid/${xid}`, {
        params: {
          apikey: this.apiKey
        }
      });
      return response.data;
    } catch (error) {
      throw new Error(`Failed to fetch OpenTripMap place details: ${error.message}`);
    }
  }

  /**
   * Maps OpenTripMap detail response to the format used by the frontend (Google-like)
   */
  mapToGoogleFormat(otm) {
    // 1. Determine rating
    let rating = 3.5;
    if (otm.rate) {
      const rateNum = parseInt(otm.rate);
      if (rateNum >= 3) rating = 5.0;
      else if (rateNum >= 2) rating = 4.0;
      else if (rateNum >= 1) rating = 3.0;
    }

    // 2. Map address robustly
    let formattedAddress = '';
    let city = '';
    if (otm.address) {
      const a = otm.address;
      const parts = [a.house_number, a.road, a.suburb, a.city || a.town || a.village, a.state]
        .filter(p => p);
      formattedAddress = parts.join(', ');
      city = a.city || a.town || a.village || '';
    }

    console.log(`[OTM Mapping] Processing: ${otm.name}`);
    
    // 3. Map photos
    let photoReference = otm.preview?.source || otm.image || null;
    
    // Wikidata Fallback: If no direct image, but we have a Wikidata ID, we can derive a Wikimedia Commons thumbnail
    // Note: This is an approximation. Real Wikidata fetching would require another API call.
    if (!photoReference && otm.wikidata) {
       // Wikimedia Commons URL pattern based on Wikidata is complex, 
       // but OTM usually handles it. If it's missing here, it's likely not on Wikimedia.
       console.log(`[OTM Mapping] No image for ${otm.name}, but Wikidata ID ${otm.wikidata} exists. (Potential for future enhancement)`);
    }

    // Force HTTPS
    if (photoReference && photoReference.startsWith('http:')) {
      photoReference = photoReference.replace('http:', 'https:');
    }

    if (photoReference) {
      console.log(`[OTM Mapping] ✅ Image found for ${otm.name}: ${photoReference.substring(0, 50)}...`);
    } else {
      console.log(`[OTM Mapping] ❌ No image fields found for ${otm.name}`);
    }

    const photos = photoReference ? [{
      photo_reference: photoReference,
      width: otm.preview?.width || 0,
      height: otm.preview?.height || 0
    }] : [];

    // 4. Map kinds and category
    const kinds = otm.kinds || '';
    const types = kinds.split(',');
    // Extract a cleaner category name
    let category = 'Point of Interest';
    if (kinds.includes('religion')) category = 'Temple / Spiritual';
    else if (kinds.includes('forts')) category = 'Fort';
    else if (kinds.includes('beaches')) category = 'Beach';
    else if (kinds.includes('museums')) category = 'Museum';
    else if (kinds.includes('nature')) category = 'Nature';
    else {
      category = types.find(k => k !== 'interesting_places' && k !== 'tourist_facilities') || 'Tourist Attraction';
    }

    return {
      place_id: otm.xid,
      name: otm.name,
      formatted_address: formattedAddress || kinds.split(',').slice(0, 3).join(', '),
      city: city,
      geometry: {
        location: {
          lat: otm.point.lat,
          lng: otm.point.lon
        }
      },
      rating: rating,
      user_ratings_total: otm.rate ? parseInt(otm.rate) * 50 : 100,
      photos: photos,
      images: photoReference ? [photoReference] : [],
      types: types,
      category: category.charAt(0).toUpperCase() + category.slice(1).replace(/_/g, ' '),
      editorial_summary: {
        overview: otm.info?.descr || otm.wikipedia_extracts?.text || ''
      },
      source: 'OpenTripMap'
    };
  }

  /**
   * Maps basic OpenTripMap info (from radius list) to the format used by the frontend
   */
  mapBasicToGoogleFormat(p) {
    let rating = 4.0;
    if (p.rate) {
      if (p.rate >= 3) rating = 5.0;
      else if (p.rate >= 2) rating = 4.0;
      else if (p.rate >= 1) rating = 3.0;
    }

    const kinds = p.kinds || '';

    return {
      place_id: p.xid,
      name: p.name,
      formatted_address: kinds.split(',').slice(0, 3).join(', '),
      vicinity: kinds.split(',')[0],
      geometry: {
        location: {
          lat: p.point.lat,
          lng: p.point.lon
        }
      },
      rating: rating,
      user_ratings_total: p.rate ? parseInt(p.rate) * 10 : 50,
      photos: [], 
      types: kinds.split(','),
      distanceCalculated: p.dist ? p.dist / 1000 : null,
      source: 'OpenTripMap (Basic)'
    };
  }
}

module.exports = new OpenTripMapService();
