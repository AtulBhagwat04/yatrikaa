const mongoose = require('mongoose');
const config = require('./src/config');
const Place = require('./src/models/Place');

const checkPlace = async () => {
  try {
    await mongoose.connect(config.MONGODB_URI);
    const place = await Place.findOne({ name: /Tarkarli/i });
    if (place) {
      console.log('Place Found:', place.name);
      console.log('Images Found:', place.images.length);
      place.images.forEach((img, i) => console.log(`[${i}] ${img}`));
      console.log('ID:', place.place_id);
    } else {
      console.log('Place not found in DB');
    }
  } catch (err) {
    console.error(err);
  } finally {
    await mongoose.disconnect();
  }
};

checkPlace();
