const axios = require('axios');

async function testApi() {
  try {
    const response = await axios.get('http://localhost:3000/api/places/search?query=Tarkarli');
    console.log(JSON.stringify(response.data.results[0], null, 2));
  } catch (err) {
    console.error(err.message);
  }
}

testApi();
