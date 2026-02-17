const axios = require('axios');
require('dotenv').config();

const API_KEY = process.env.GOOGLE_PLACES_API_KEY;
const lat = 18.5204;
const lng = 73.8567;

async function test() {
  console.log('Testing with API Key:', API_KEY.substring(0, 10) + '...');
  try {
    const response = await axios.get('https://maps.googleapis.com/maps/api/place/nearbysearch/json', {
      params: {
        location: `${lat},${lng}`,
        radius: 5000,
        type: 'tourist_attraction',
        key: API_KEY
      }
    });
    console.log('Status:', response.data.status);
    console.log('Results Count:', response.data.results ? response.data.results.length : 0);
    if (response.data.error_message) {
      console.log('Error Message:', response.data.error_message);
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

test();
