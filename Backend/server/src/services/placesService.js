const axios = require('axios');
const config = require('../config');

class PlacesService {
  constructor() {
    this.baseUrl = config.GOOGLE_PLACES_BASE_URL;
    this.apiKey = config.GOOGLE_PLACES_API_KEY;
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

  async getNearbyPlaces(lat, lng, initialRadius = 20000) {
    let currentRadius = initialRadius;
    let allResults = [];
    const maxRadius = 50000;
    
    try {
      // Step 1: Broad search centered on tourist attractions and famous keywords
      // We use textSearch for better keyword targeting compared to nearbySearch
      const keywords = ["fort", "heritage", "museum", "historical", "monument", "temple", "landmark", "tourist attraction"];
      const query = keywords.join(" | ");

      while (allResults.length < 5 && currentRadius <= maxRadius) {
        const response = await axios.get(`${this.baseUrl}/textsearch/json`, {
          params: {
            query: query,
            location: `${lat},${lng}`,
            radius: currentRadius,
            key: this.apiKey
          }
        });

        const rawResults = response.data.results || [];
        
        // Step 2: Implement strict backend filtering
        const filtered = rawResults.filter(place => {
          const types = place.types || [];
          
          // Must have basic quality requirements
          const hasMinRating = (place.rating || 0) >= 4.0;
          const hasMinReviews = (place.user_ratings_total || 0) >= 100;
          const hasPhotos = place.photos && place.photos.length > 0;
          
          // Exclude business/commercial/low-relevance types
          const isExcludedType = types.some(type => 
            ['restaurant', 'cafe', 'store', 'lodging', 'spa', 'gym', 'bank', 'atm', 'gas_station'].includes(type)
          );
          
          // Must be a recognized point of interest or attraction
          const isRelevant = types.some(type => 
            ['tourist_attraction', 'museum', 'park', 'place_of_worship', 'art_gallery', 'natural_feature', 'point_of_interest'].includes(type)
          );

          return hasMinRating && hasMinReviews && hasPhotos && !isExcludedType && isRelevant;
        });

        // Step 3: Remove duplicates (if any from overlapping logic)
        filtered.forEach(place => {
          if (!allResults.find(p => p.place_id === place.place_id)) {
            // Attach distance for sorting
            const dist = this.calculateDistance(lat, lng, place.geometry.location.lat, place.geometry.location.lng);
            place.distanceCalculated = dist;
            allResults.push(place);
          }
        });

        if (allResults.length < 5) {
          currentRadius += 15000; // Expand search area
        }
      }

      // Step 4: Multi-stage Sorting
      // Sort priority: 1. Rating (High to Low), 2. Popularity (Reviews count), 3. Distance (Close to Far)
      allResults.sort((a, b) => {
        if (b.rating !== a.rating) return b.rating - a.rating;
        if (b.user_ratings_total !== a.user_ratings_total) return b.user_ratings_total - a.user_ratings_total;
        return a.distanceCalculated - b.distanceCalculated;
      });

      // Step 5: Shuffle a bit for variety if we have enough results
      // We keep the top 10 and shuffle them to provide "new" places on refresh
      const topPool = allResults.slice(0, 15);
      for (let i = topPool.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [topPool[i], topPool[j]] = [topPool[j], topPool[i]];
      }

      return {
        status: "OK",
        results: topPool.slice(0, 10) // Return 10 unique, shuffled, high-quality matches
      };

    } catch (error) {
      console.error("Places API Error:", error.message);
      throw new Error(`Failed to fetch high-quality tourist attractions: ${error.message}`);
    }
  }

  async searchPlaces(query, lat, lng) {
    try {
      const params = {
        query,
        key: this.apiKey
      };

      if (lat && lng) {
        params.location = `${lat},${lng}`;
        params.radius = 20000; // Default search radius
      }

      const response = await axios.get(`${this.baseUrl}/textsearch/json`, { params });
      return response.data;
    } catch (error) {
      throw new Error(`Failed to search places: ${error.message}`);
    }
  }

  async getPlaceDetails(placeId) {
    try {
      const response = await axios.get(`${this.baseUrl}/details/json`, {
        params: {
          place_id: placeId,
          fields: 'name,rating,user_ratings_total,formatted_address,photos,geometry,reviews,opening_hours,website,types,address_components,editorial_summary',
          key: this.apiKey
        }
      });
      return response.data;
    } catch (error) {
      throw new Error(`Failed to fetch place details: ${error.message}`);
    }
  }

  getPhotoUrl(photoReference, maxWidth = 800) {
    return `${this.baseUrl}/photo?maxwidth=${maxWidth}&photoreference=${photoReference}&key=${this.apiKey}`;
  }
}

module.exports = new PlacesService();
