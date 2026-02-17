const placesService = require('../services/placesService');

class PlacesController {
  async getNearby(req, res) {
    const { lat, lng, radius, type } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and Longitude are required' });
    }

    try {
      const data = await placesService.getNearbyPlaces(lat, lng, radius, type);
      res.json(data);
    } catch (error) {
      console.error('Controller Error (getNearby):', error.message);
      res.status(500).json({ error: error.message });
    }
  }

  async search(req, res) {
    const { query, lat, lng } = req.query;

    if (!query) {
      return res.status(400).json({ error: 'Query is required' });
    }

    try {
      const data = await placesService.searchPlaces(query, lat, lng);
      res.json(data);
    } catch (error) {
      console.error('Controller Error (search):', error.message);
      res.status(500).json({ error: error.message });
    }
  }

  async getDetails(req, res) {
    const { placeId } = req.params;

    try {
      const data = await placesService.getPlaceDetails(placeId);
      res.json(data);
    } catch (error) {
      console.error('Controller Error (getDetails):', error.message);
      res.status(500).json({ error: error.message });
    }
  }

  getPhoto(req, res) {
    const { photoReference } = req.params;
    const { maxWidth } = req.query;
    
    const photoUrl = placesService.getPhotoUrl(photoReference, maxWidth);
    res.redirect(photoUrl);
  }
}

module.exports = new PlacesController();
