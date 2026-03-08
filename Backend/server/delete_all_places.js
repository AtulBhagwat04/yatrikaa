const mongoose = require('mongoose');
const config = require('./src/config');

async function deleteAllPlaces() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(config.MONGODB_URI);
    console.log('Connected successfully!');

    const collection = mongoose.connection.collection('places');
    const count = await collection.countDocuments();
    
    if (count > 0) {
      console.log(`Deleting ${count} places...`);
      const result = await collection.deleteMany({});
      console.log(`Successfully deleted ${result.deletedCount} documents.`);
    } else {
      console.log('No documents found in the "places" collection.');
    }
  } catch (error) {
    console.error('Error during deletion:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
    process.exit(0);
  }
}

deleteAllPlaces();
