const mongoose = require('mongoose');
const config = require('./src/config');
const Place = require('./src/models/Place');

const placesData = [
  {
    "place_id": "gen_unique_id_001",
    "name": "Ajanta Caves",
    "category": "UNESCO World Heritage Site",
    "images": [
      "https://images.unsplash.com/photo-1626292376170-137b7ed1e95e?q=80&w=1000",
      "https://images.unsplash.com/photo-1615808233379-373f769df8b2?q=80&w=1000",
      "https://images.unsplash.com/photo-1626548307930-deac221f77b9?q=80&w=1000",
      "https://images.unsplash.com/photo-1625505826533-5c80aca7d157?q=80&w=1000"
    ],
    "formatted_address": "Ajanta Caves Road, Aurangabad District, Maharashtra 431117, India",
    "city": "Sambhajinagar (Aurangabad)",
    "state": "Maharashtra",
    "geometry": {
      "location": {
        "lat": 20.5519,
        "lng": 75.7031
      }
    },
    "rating": 4.7,
    "user_ratings_total": 28540,
    "description": "Nestled within the curved mountain side of the Waghur River, the Ajanta Caves represent a pinnacle of ancient Indian architectural brilliance and spiritual devotion. Dating back to the 2nd century BCE, these thirty rock-cut Buddhist cave monuments are more than just archaeological relics; they are a profound gallery of human emotion and artistic mastery. As you step into the cool, dimly lit chambers, the smell of damp stone and ancient history greets you. The walls are adorned with the famous 'Ajanta Murals'—intricate frescoes that depict the Jataka tales and the life of Lord Buddha with a fluidity and vibrant color palette that has defied the passage of two millennia. The mastery of perspective and the delicate expressions on the faces of the Bodhisattvas, particularly the Padmapani and Vajrapani, evoke a sense of serenity and timelessness. Each cave was meticulously carved by hand, transforming solid basalt into ornate pillars, grand stupas, and serene monasteries. The panoramic view of the horseshoe-shaped gorge from the viewpoint offers a breathtaking perspective of how these spiritual retreats were harmoniously integrated into the rugged Sahyadri landscape. For the modern traveler, Ajanta is not just a destination but a meditative journey back to an era where art and faith were indistinguishable, offering a quiet sanctuary away from the chaos of contemporary life.",
    "entry_fee": "₹40 (Indians), ₹600 (Foreigners)",
    "best_time": "June to March",
    "difficulty": "Moderate",
    "timings": "9:00 AM - 5:00 PM (Closed on Mondays)",
    "parking_available": true,
    "suitable_for": "History Enthusiasts, Photographers, Families",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Shuttle Bus", "Cafeteria", "Information Center"]
  },
  {
    "place_id": "gen_unique_id_002",
    "name": "Kaas Plateau (Valley of Flowers)",
    "category": "Natural Heritage Site",
    "images": [
      "https://images.unsplash.com/photo-1632344791550-936c5356993a?q=80&w=1000",
      "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1000",
      "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=1000",
      "https://images.unsplash.com/photo-1469474968028-56623f02e42e?q=80&w=1000"
    ],
    "formatted_address": "Kaas Road, Satara District, Maharashtra 415001, India",
    "city": "Satara",
    "state": "Maharashtra",
    "geometry": {
      "location": {
        "lat": 17.7196,
        "lng": 73.8181
      }
    },
    "rating": 4.5,
    "user_ratings_total": 15200,
    "description": "Known as Maharashtra's very own 'Valley of Flowers,' the Kaas Plateau is a volcanic laterite crust that transforms into a psychedelic carpet of blooms following the monsoon rains. This UNESCO World Heritage site is a botanical marvel, home to over 850 species of flowering plants, many of which are endemic and rare. Imagine standing atop a vast, wind-swept tableland where the horizon is blurred by waves of purple, pink, and yellow. The tiny, delicate flowers like the Karvy, Smithias, and various orchids create a fragile ecosystem that feels like a dreamscape. The air is crisp and carries the scent of fresh earth and wild nectar. Walking along the designated pathways, visitors are treated to a visual symphony that changes every few weeks as different species take their turn to bloom. To the west, the plateau drops off into lush green valleys, with the Kaas Lake shimmering like a sapphire in the distance. The experience is ethereal, especially during early morning when the mist clings to the ground, slowly revealing the vibrant colors as the sun rises. It is a place that demands silence and respect for nature’s delicate balance. For nature lovers and macro-photographers, Kaas offers an unparalleled opportunity to witness biodiversity in its most colorful and concentrated form, making it a bucket-list destination for anyone exploring the Western Ghats.",
    "entry_fee": "₹100",
    "best_time": "Late August to early October",
    "difficulty": "Easy",
    "timings": "8:00 AM - 6:00 PM",
    "parking_available": true,
    "suitable_for": "Nature Lovers, Couples, Botanists",
    "photography_allowed": true,
    "facilities": ["Basic Washrooms", "Parking", "Local Food Stalls"]
  },
  {
    "place_id": "gen_unique_id_003",
    "name": "Raigad Fort",
    "category": "Hill Fort / Historical Site",
    "images": [
      "https://images.unsplash.com/photo-1590050752117-23a9dee3fe74?q=80&w=1000",
      "https://images.unsplash.com/photo-1627916607164-7b20241db935?q=80&w=1000",
      "https://images.unsplash.com/photo-1615808233379-373f769df8b2?q=80&w=1000",
      "https://images.unsplash.com/photo-1589139011550-2b13e00fc826?q=80&w=1000"
    ],
    "formatted_address": "Raigad District, Raigad, Maharashtra 402305, India",
    "city": "Mahad",
    "state": "Maharashtra",
    "geometry": {
      "location": {
        "lat": 18.2347,
        "lng": 73.4411
      }
    },
    "rating": 4.8,
    "user_ratings_total": 42100,
    "description": "Perched majestically at an altitude of 2,700 feet in the Sahyadri mountain range, Raigad Fort stands as a formidable symbol of the Maratha Empire’s grit and sovereignty. Once the capital of Chhatrapati Shivaji Maharaj, this 'Gibraltar of the East' is draped in legends of bravery and strategic brilliance. Reaching the summit, either by a rigorous trek of 1,700 steps or a scenic ropeway ride, rewards the traveler with breathtaking vistas of deep valleys and jagged peaks. The fort's architecture is a masterclass in defensive engineering; from the 'Maha Darwaza' to the dizzying heights of 'Takmak Tok' (the execution point), every stone tells a story of a bygone era of warriors and kings. Walking through the ruins of the Royal Court (Raj Sabha), one can almost hear the echoes of historic proclamations. The centerpiece of the fort is the Samadhi of Chhatrapati Shivaji Maharaj, a place of immense reverence that exudes a powerful, somber energy. During the monsoon, the fort is often swallowed by clouds, with waterfalls cascading down its steep rock faces, creating an atmosphere that is both haunting and heroic. It is not just a historical site; for many, it is a pilgrimage that inspires pride and a deep connection to Maharashtra’s rich cultural heritage. The panoramic sunset from the western edge, where the sky turns a fiery orange over the rugged Konkan landscape, is a sight that remains etched in the memory forever.",
    "entry_fee": "₹25 (Indians), ₹300 (Foreigners), Ropeway extra",
    "best_time": "September to March",
    "difficulty": "Challenging (Trek) / Easy (Ropeway)",
    "timings": "8:00 AM - 6:00 PM",
    "parking_available": true,
    "suitable_for": "History Buffs, Adventure Seekers, Trekkers",
    "photography_allowed": true,
    "facilities": ["Ropeway", "Dormitories", "Local Eateries", "Guides"]
  }
];

const seedPlaces = async () => {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(config.MONGODB_URI);
    console.log('Connected successfully!');

    // First delete existing to avoid duplicates if place_id is unique
    const collection = mongoose.connection.collection('places');
    await collection.deleteMany({});
    console.log('Cleared existing places.');
    
    // Insert new data
    const result = await collection.insertMany(placesData);
    console.log(`Successfully added ${result.insertedCount} places.`);

  } catch (error) {
    console.error('Error during seeding:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
    process.exit(0);
  }
};

seedPlaces();
