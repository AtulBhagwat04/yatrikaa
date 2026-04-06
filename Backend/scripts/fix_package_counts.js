const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env
dotenv.config({ path: path.join(__dirname, '../server/src/.env') });

const TravelPackage = require('../server/src/models/TravelPackage');
const Booking = require('../server/src/models/Booking');

async function fixCounts() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb+srv://atulbhagwat04:fEwN3G6d3XQ7aYjJ@cluster0.z2g79.mongodb.net/yatri-kars-prod';
    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    const packages = await TravelPackage.find();
    console.log(`Found ${packages.length} packages to check.`);

    for (const pkg of packages) {
      // Find all non-cancelled bookings for this package
      const activeBookings = await Booking.find({
        package: pkg._id,
        status: { $ne: 'Cancelled' }
      });

      let actualCount = 0;
      for (const booking of activeBookings) {
        // Count travelers in each booking who are NOT cancelled
        const activeTravelers = booking.travelers.filter(t => t.status !== 'Cancelled').length;
        actualCount += activeTravelers;
      }

      console.log(`Package: ${pkg.title} | DB Count: ${pkg.currentParticipants} | Actual Count: ${actualCount}`);
      
      if (pkg.currentParticipants !== actualCount) {
        pkg.currentParticipants = actualCount;
        await pkg.save();
        console.log(`✅ Fixed!`);
      }
    }

    console.log('Done!');
    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
}

fixCounts();
