const mongoose = require('mongoose');
const cloudinary = require('cloudinary').v2;
const config = require('./src/config');
const Place = require('./src/models/Place');

// Cloudinary Config
cloudinary.config({
  cloud_name: config.CLOUDINARY.CLOUD_NAME,
  api_key: config.CLOUDINARY.API_KEY,
  api_secret: config.CLOUDINARY.API_SECRET
});

const beachesData = [
  {
    "place_id": "place_01",
    "name": "Tarkarli Beach & Devbag Sangam",
    "category": "Beach & Watersports",
    "images": [
      "https://images.unsplash.com/photo-1590513931008-816223253767?q=80&w=1000",
      "https://images.unsplash.com/photo-1621319306105-02058e578687?q=80&w=1000",
      "https://images.unsplash.com/photo-1544919982-b61976f0ba43?q=80&w=1000",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000"
    ],
    "formatted_address": "Tarkarli-Devbag Road, Malvan, Sindhudurg, Maharashtra 416606, India",
    "city": "Malvan",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 16.0355, "lng": 73.4912 } },
    "rating": 4.8,
    "user_ratings_total": 24500,
    "description": "Tarkarli is the crown jewel of the Konkan coast, where the emerald Karli River gracefully merges into the sapphire Arabian Sea at the Devbag Sangam. This destination is celebrated for its rare, crystal-clear waters that offer a window into a vibrant underwater world, making it Maharashtra’s premier hub for scuba diving and snorkeling. The shoreline is a pristine ribbon of powdery white sand, shaded by swaying Casuarina trees that create a melodic rustle in the salty breeze. Whether you are gliding through the backwaters in a traditional houseboat or exploring the nearby historic Sindhudurg Fort, the atmosphere is one of pure, unhurried serenity. As the sun sets over the Tsunami Island sandbar, the sky ignites in shades of violet and gold, offering a cinematic backdrop that has made Tarkarli a viral sensation for nature lovers and soul-seekers alike.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Family & Adventure",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Parking", "Scuba Centers", "Shacks"]
  },
  {
    "place_id": "place_02",
    "name": "Ganpatipule Beach",
    "category": "Beach & Pilgrimage",
    "images": [
      "https://images.unsplash.com/photo-1591140049915-998845c4844d?q=80&w=1000",
      "https://images.unsplash.com/photo-1570733117311-d990c3806f47?q=80&w=1000",
      "https://images.unsplash.com/photo-1590050752117-23952b981d3f?q=80&w=1000",
      "https://images.unsplash.com/photo-1541006505085-f5d47e4529bc?q=80&w=1000"
    ],
    "formatted_address": "Ganpatipule Beach, Ratnagiri District, Maharashtra 415615, India",
    "city": "Ganpatipule",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.1481, "lng": 73.2684 } },
    "rating": 4.7,
    "user_ratings_total": 35200,
    "description": "Ganpatipule is a unique confluence of spirituality and scenic grandeur, famous for its 400-year-old Swayambhu Ganpati Temple nestled right against the silver sands. The deity here is considered the 'Paschim Dwardevata' or the Western Sentinel. The beach itself is a breathtaking curve of golden sand flanked by dramatic red laterite cliffs and lush coconut groves. Unlike typical commercial shores, Ganpatipule maintains a tranquil, sacred energy where the sound of temple bells harmonizes with the rhythmic crashing of the Arabian Sea. Visitors can partake in the 'Pradakshina' of the hill, which is shaped like Lord Ganesha, or enjoy thrilling water sports near the MTDC resort. The vibrant red soil and the deep blue of the ocean create a striking visual contrast, making it a favorite for photographers seeking that perfect Konkan aesthetic. It is a place of peace, where the soul finds rest and the eyes find beauty.",
    "entry_fee": "Free",
    "best_time": "November to February",
    "difficulty": "Easy",
    "timings": "6:00 AM - 9:00 PM (Temple)",
    "parking_available": true,
    "suitable_for": "Family & Religious",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Parking", "Drinking Water", "Locker Room"]
  },
  {
    "place_id": "place_03",
    "name": "Kashid Beach",
    "category": "Beach Resort",
    "images": [
      "https://images.unsplash.com/photo-1590001158193-79013018e2de?q=80&w=1000",
      "https://images.unsplash.com/photo-1582913130082-743e93b9fe81?q=80&w=1000",
      "https://images.unsplash.com/photo-1548013146-72479768bbaa?q=80&w=1000",
      "https://images.unsplash.com/photo-1519046904884-53103b34b206?q=80&w=1000"
    ],
    "formatted_address": "Kashid, Alibaug-Murud Road, Raigad, Maharashtra 402401, India",
    "city": "Alibaug",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 18.4357, "lng": 72.9103 } },
    "rating": 4.6,
    "user_ratings_total": 28900,
    "description": "Known as the 'Mini Goa' of Alibaug, Kashid Beach is a three-kilometer stretch of milky-white sand tucked between two rocky hillocks. This coastal escape is a favorite for Mumbaikars and Punekars seeking a premium weekend retreat. The beach is lined with dense thickets of Casuarina trees, providing natural shade for those wanting to lounge by the crashing surf. Kashid is particularly famous for its high waves, making it an exciting spot for surfing and adventure activities like parasailing and banana boat rides. The nearby Phansad Wildlife Sanctuary and the historic Revdanda Fort add a touch of heritage and nature to the beach experience. Whether you are staying in a luxury boutique resort or a quaint local homestay, Kashid offers a perfect blend of high-energy water sports and quiet seaside relaxation. The sunset here is legendary, casting a golden hue over the white sands that is truly Instagram-worthy.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Couples & Friends",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Parking", "Water Sports", "Food Stalls"]
  },
  {
    "place_id": "place_04",
    "name": "Aare-Ware Beach",
    "category": "Scenic Beach",
    "images": [
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1000",
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1000",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000",
      "https://images.unsplash.com/photo-1473116763249-2faaef81ccda?q=80&w=1000"
    ],
    "formatted_address": "Aare-Ware Coastal Rd, Ratnagiri, Maharashtra 415612, India",
    "city": "Ratnagiri",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.0792, "lng": 73.2847 } },
    "rating": 4.8,
    "user_ratings_total": 12400,
    "description": "Aare-Ware is widely considered the most scenic coastal drive in all of Maharashtra. This twin-beach destination features a winding road carved into the edge of a cliff, offering panoramic views reminiscent of the Great Ocean Road. The 'Aare' and 'Ware' beaches are separated by a small hillock, each offering vast, untouched stretches of silver sand and deep blue water. Unlike more popular tourist spots, Aare-Ware remains delightfully secluded, making it a haven for those who value privacy and raw natural beauty. The highlight for any traveler is the Aare-Ware Point, where you can watch the waves crash against the rocks hundreds of feet below while the sea breeze carries the scent of salt and wild shrubs. It is a preferred location for cinematic photography and pre-wedding shoots due to its dramatic vistas and the absence of commercial crowds. It represents the Konkan at its most wild and wonderful, where the Sahyadris meet the sea.",
    "entry_fee": "Free",
    "best_time": "August to February",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Photography & Couples",
    "photography_allowed": true,
    "facilities": ["Viewpoint", "Parking", "Nearby Small Eateries"]
  },
  {
    "place_id": "place_05",
    "name": "Diveagar Beach",
    "category": "Beach & Heritage",
    "images": [
      "https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?q=80&w=1000",
      "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?q=80&w=1000",
      "https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?q=80&w=1000",
      "https://images.unsplash.com/photo-1540206351-d6465b3ac5c1?q=80&w=1000"
    ],
    "formatted_address": "Diveagar Beach Rd, Shrivardhan, Raigad, Maharashtra 402404, India",
    "city": "Diveagar",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 18.1754, "lng": 72.9856 } },
    "rating": 4.7,
    "user_ratings_total": 21300,
    "description": "Diveagar is a quintessential Konkan village that feels like a slice of paradise found. The beach is a stunning five-kilometer arc of firm, gray sand, perfectly safe for long walks and morning jogs. What makes Diveagar special is its history; it gained fame after a golden idol of Lord Ganesha was discovered in a copper trunk in a local field. The beach is lined with lush coconut and betel nut plantations (Wadis), giving it a tropical, secluded feel. The waters are relatively shallow and calm, making it a top choice for families with children. As the sun dips below the horizon, the beach transforms into a quiet sanctuary where you can hear nothing but the wind and the waves. The local culture is deeply rooted in hospitality, with many families offering traditional 'Ukadiche Modak' and fresh seafood. Diveagar is the perfect destination for those looking to disconnect from the digital world and reconnect with the simple rhythms of coastal life.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Family & Peace Seekers",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Parking", "Homestays", "Water Sports"]
  },
  {
    "place_id": "place_06",
    "name": "Harihareshwar",
    "category": "Beach & Pilgrimage",
    "images": [
      "https://images.unsplash.com/photo-1590050752117-23952b981d3f?q=80&w=1000",
      "https://images.unsplash.com/photo-1541006505085-f5d47e4529bc?q=80&w=1000",
      "https://images.unsplash.com/photo-1588096344356-9b6343f8885b?q=80&w=1000",
      "https://images.unsplash.com/photo-1610410051515-998f869910ba?q=80&w=1000"
    ],
    "formatted_address": "Harihareshwar Temple Road, Raigad, Maharashtra 402110, India",
    "city": "Shrivardhan",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.9950, "lng": 73.0250 } },
    "rating": 4.6,
    "user_ratings_total": 18200,
    "description": "Harihareshwar, often revered as the 'Dakshin Kashi', is a mystical blend of rugged cliffs, ancient temples, and two serene beaches. Nestled between the hills of Harihareshwar, Harshinachal, and Pushpadri, the town is anchored by the venerable Kalbhairav and Harihareshwar temple complex. The unique 'Pradakshina' path here is a viral favorite for travelers; it takes you through narrow rock-cut steps behind the temple that open directly onto the sea-beaten rocky shore. As the waves crash against the black stone sculptures carved by nature over centuries, the atmosphere becomes truly otherworldly. The beach to the north offers long stretches of soft sand, perfect for meditative walks. Whether you are seeking spiritual solace or a dramatic coastal trek, Harihareshwar provides a profound sense of peace. The sight of the temple orange flags fluttering against the deep blue Arabian Sea is a hallmark of Konkan's divine beauty.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Moderate (Stairs)",
    "timings": "6:00 AM - 9:00 PM",
    "parking_available": true,
    "suitable_for": "Family & Religious",
    "photography_allowed": true,
    "facilities": ["Washrooms", "MTDC Resort", "Prasadam Hall"]
  },
  {
    "place_id": "place_07",
    "name": "Guhagar Beach",
    "category": "Pristine Beach",
    "images": [
      "https://images.unsplash.com/photo-1519046904884-53103b34b206?q=80&w=1000",
      "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?q=80&w=1000",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000",
      "https://images.unsplash.com/photo-1540206351-d6465b3ac5c1?q=80&w=1000"
    ],
    "formatted_address": "Guhagar Beach, Ratnagiri District, Maharashtra 415703, India",
    "city": "Guhagar",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.4816, "lng": 73.1896 } },
    "rating": 4.7,
    "user_ratings_total": 9800,
    "description": "Guhagar is the quintessential 'Temple Town' of the Konkan, offering one of the longest and cleanest white-sand beaches in Maharashtra. Stretching over six kilometers, the shoreline is remarkably wide and flanked by dense stands of Suru (Casuarina) and coconut trees that provide a lush, green backdrop. The beach is famous for its peaceful, uncommercialized vibe, where the primary sounds are the chirping of sea-eagles and the gentle lap of the waves. It is an ideal spot for those who want to escape the 'Maximum City' chaos and slow down. In the evenings, the sun sets directly over the horizon, painting the sky in soft pastel oranges and pinks—a dream for landscape photographers. Nearby, the ancient Vyadeshwar Shiva temple adds a cultural soul to the visit. Guhagar is not just a beach; it’s a retreat into the heart of Konkani hospitality, where simplicity is the ultimate luxury.",
    "entry_fee": "Free",
    "best_time": "November to February",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Family & Peace Seekers",
    "photography_allowed": true,
    "facilities": ["Washrooms", "Local Eateries", "Children's Play Area"]
  },
  {
    "place_id": "place_08",
    "name": "Anjarle Beach & Kadyavarcha Ganpati",
    "category": "Beach & Scenic Temple",
    "images": [
      "https://images.unsplash.com/photo-1473116763249-2faaef81ccda?q=80&w=1000",
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1000",
      "https://images.unsplash.com/photo-1621259182978-f09e5e2ca845?q=80&w=1000",
      "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000"
    ],
    "formatted_address": "Kadyavarcha Ganpati Rd, Anjarle, Ratnagiri, Maharashtra 415712, India",
    "city": "Dapoli",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.8541, "lng": 73.0877 } },
    "rating": 4.8,
    "user_ratings_total": 5600,
    "description": "Anjarle is a hidden gem that captures the essence of rural Konkan. It is most famous for the 'Kadyavarcha Ganpati' temple, situated on a steep cliff overlooking the Arabian Sea. The temple’s unique idol features Ganesha with his trunk turned to the right, and the view from the top is a spectacular panorama of the Anjarle creek and its white sandy beach. The beach itself is a tranquil paradise, famous for being a nesting site for Olive Ridley turtles. Every year during the turtle festival, visitors gather to witness tiny hatchlings making their first journey to the sea. Lined with betel nut and coconut plantations, the village of Anjarle offers an authentic homestay experience. For the traveler, it’s a place of vibrant colors—from the bright orange of the temple's roof to the deep green of the palms and the shimmering blue of the ocean.",
    "entry_fee": "Free",
    "best_time": "September to March (Turtle Festival: Feb-Apr)",
    "difficulty": "Easy",
    "timings": "7:00 AM - 7:00 PM",
    "parking_available": true,
    "suitable_for": "Nature Enthusiasts & Family",
    "photography_allowed": true,
    "facilities": ["Homestays", "Drinking Water", "Temple Parking"]
  },
  {
    "place_id": "place_09",
    "name": "Vengurla Rocks (Nivati Rocks)",
    "category": "Island Archipelago / Adventure",
    "images": [
      "https://images.unsplash.com/photo-1599661046289-e318878567c4?q=80&w=1000",
      "https://images.unsplash.com/photo-1566550999633-67141f27e7a9?q=80&w=1000",
      "https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?q=80&w=1000",
      "https://images.unsplash.com/photo-1570160897040-d0187aa7d8de?q=80&w=1000"
    ],
    "formatted_address": "Vengurla Rocks, Sindhudurg, Maharashtra 416516, India",
    "city": "Vengurla",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 15.8554, "lng": 73.6150 } },
    "rating": 4.9,
    "user_ratings_total": 850,
    "description": "For those seeking the offbeat, the Vengurla Rocks (also known as Burnt Island) offer an adventurous escape. This archipelago of 20 basalt rocks rises dramatically from the deep sea, about 10km off the Vengurla coast. It is home to a historic British-era lighthouse and serves as a vital nesting ground for rare birds like the Bridled Tern and Indian Swiftlet. Accessible only by a mechanized boat during the fair season, the journey itself is a thrilling ride through the azure waves. The rocks are surrounded by some of the clearest waters in India, making the area a hotspot for elite divers and nature photographers. The raw, jagged beauty of the rocks against the vast, empty horizon creates a sense of isolation that is hard to find elsewhere. It is a place of primal nature, where the wind and salt spray tell stories of ancient mariners and seafaring legends.",
    "entry_fee": "Boat hire charges apply (approx. ₹2000-4000)",
    "best_time": "December to February",
    "difficulty": "Hard (Boat access only)",
    "timings": "Sunrise - Sunset",
    "parking_available": false,
    "suitable_for": "Adventure Seekers & Birdwatchers",
    "photography_allowed": true,
    "facilities": ["None (Carry Water/Food)"]
  },
  {
    "place_id": "place_10",
    "name": "Kihim Beach",
    "category": "Beach & Nature",
    "images": [
      "https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?q=80&w=1000",
      "https://images.unsplash.com/photo-1582913130082-743e93b9fe81?q=80&w=1000",
      "https://images.unsplash.com/photo-1548013146-72479768bbaa?q=80&w=1000",
      "https://images.unsplash.com/photo-1519046904884-53103b34b206?q=80&w=1000"
    ],
    "formatted_address": "Kihim Beach, Alibaug, Raigad, Maharashtra 402201, India",
    "city": "Alibaug",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 18.7231, "lng": 72.8711 } },
    "rating": 4.5,
    "user_ratings_total": 15400,
    "description": "Kihim is where Alibaug feels slower, greener, and more private. Known as a 'Butterfly Paradise,' this beach is hidden behind a dense cover of coconut and casuarina trees, interspersed with colorful wildflowers. The sand is exceptionally soft, and the shoreline is dotted with unique rocky outcrops that create beautiful tide pools during low tide. Kihim has a distinctively nature-first feel; it’s a hub for birdwatchers who come to spot rare migratory species in the surrounding woods. For the casual traveler, it offers a more relaxed sunset vibe compared to the busier Alibaug or Mandwa beaches. You can spend the afternoon reading under the shade of the palms and then walk out to the water as the breeze cools. The presence of rare seashells and the sight of the Kolaba Fort in the distance make every stroll a treasure hunt. It is the ultimate spot for introspection and reconnecting with nature's quiet rhythms.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Nature Lovers & Couples",
    "photography_allowed": true,
    "facilities": ["Homestays", "Local Seafood Stalls", "Parking"]
  },
  {
    "place_id": "place_11",
    "name": "Velas Beach",
    "category": "Eco-Tourism / Beach",
    "images": [
      "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?q=80&w=1000",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1000",
      "https://images.unsplash.com/photo-1544919982-b61976f0ba43?q=80&w=1000",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000"
    ],
    "formatted_address": "Velas Beach, Ratnagiri, Maharashtra 415013, India",
    "city": "Mandangad",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.9547, "lng": 73.0234 } },
    "rating": 4.6,
    "user_ratings_total": 4200,
    "description": "Velas is a remote fishing village that has become a global beacon for eco-tourism, famous for the annual Velas Turtle Festival. This quiet stretch of golden sand serves as a critical nesting site for the endangered Olive Ridley sea turtles. Between February and April, the village transforms as hundreds of travelers gather to witness the miraculous sight of tiny hatchlings emerging from their sandy cocoons and crawling toward the vast ocean. The conservation model here is unique, with local villagers hosting tourists in traditional Konkani homestays, offering a truly immersive cultural experience. Beyond the turtles, the beach is a picture of tranquility—untouched by commercial resorts and surrounded by lush green hills and the historic Bankot Fort. The silence of the village, the authentic Malvani home-cooked meals, and the raw beauty of the starlit beach make Velas a soul-stirring destination for anyone looking to support conservation while finding peace.",
    "entry_fee": "Free",
    "best_time": "February to April (Turtle Season)",
    "difficulty": "Easy",
    "timings": "6:00 AM - 6:00 PM",
    "parking_available": true,
    "suitable_for": "Eco-Travelers & Families",
    "photography_allowed": true,
    "facilities": ["Homestays", "Volunteer Guides", "Basic Toilets"]
  },
  {
    "place_id": "place_12",
    "name": "Dapoli (Karde Beach)",
    "category": "Beach & Wildlife",
    "images": [
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000",
      "https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?q=80&w=1000",
      "https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?q=80&w=1000",
      "https://images.unsplash.com/photo-1540206351-d6465b3ac5c1?q=80&w=1000"
    ],
    "formatted_address": "Karde Beach Road, Dapoli, Ratnagiri, Maharashtra 415712, India",
    "city": "Dapoli",
    "state": "Maharashtra",
    "geometry": { "location": { "lat": 17.7554, "lng": 73.1022 } },
    "rating": 4.5,
    "user_ratings_total": 7800,
    "description": "Karde Beach, located near the town of Dapoli, is one of the safest and most serene stretches along the Konkan coast. Famous for its firm, dark sand and gentle gradient, it is an ideal spot for long, barefoot walks and morning yoga. However, the true highlight of Karde is the dolphin-watching safaris. Every morning, local boats take travelers into the deep sea, where playful Indo-Pacific humpback dolphins can often be seen leaping through the waves. The beach is fringed with a variety of resorts and homestays that allow you to wake up to the sound of the ocean. For the adventurous, water sports like parasailing and jet skiing are available, but Karde remains primarily a place for relaxation. As the sun sets, the long horizon provides a blazing display of colors, perfect for capturing that definitive beach vacation photo. It is a harmonious blend of nature, wildlife, and coastal leisure.",
    "entry_fee": "Free",
    "best_time": "October to March",
    "difficulty": "Easy",
    "timings": "Open 24 Hours",
    "parking_available": true,
    "suitable_for": "Family & Wildlife Lovers",
    "photography_allowed": true,
    "facilities": ["Beach Resorts", "Water Sports", "Parking"]
  }
];

const seedBeaches = async () => {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(config.MONGODB_URI);
    console.log('Connected successfully!');

    // Sanitization function for folders
    const sanitize = (name) => name.replace(/\s+/g, '_').replace(/[^\w-]/g, '');

    for (const beach of beachesData) {
      console.log(`Processing: ${beach.name}...`);
      
      const folderName = `Bhatkanti/Places/${sanitize(beach.name)}`;
      const cloudinaryUrls = [];

      // DELETE existing to force-refresh with correct Cloudinary images
      await Place.deleteOne({ place_id: beach.place_id });
      console.log(`- Cleared existing entry for ${beach.name}`);

      for (let i = 0; i < beach.images.length; i++) {
        const imgUrl = beach.images[i];
        try {
          console.log(`  > Uploading image ${i + 1}/${beach.images.length}...`);
          // Use axios to fetch the image as a buffer first to avoid stream issues if any
          const uploadRes = await cloudinary.uploader.upload(imgUrl, {
            folder: folderName,
            use_filename: true,
            unique_filename: true,
            resource_type: "auto"
          });
          cloudinaryUrls.push(uploadRes.secure_url);
        } catch (uploadErr) {
          console.error(`  ! Error uploading image ${i + 1}:`, uploadErr.message);
          cloudinaryUrls.push(imgUrl);
        }
      }

      // Update images with Cloudinary URLs
      beach.images = cloudinaryUrls;

      // Map to Place model
      const placeToSave = new Place({
        ...beach,
        types: [beach.category.toLowerCase(), 'beach', 'tourist_attraction'],
        editorial_summary: { overview: beach.description },
        opening_hours: {
            weekday_text: [beach.timings],
            open_now: true
        }
      });

      await placeToSave.save();
      console.log(`- Saved ${beach.name} with ${cloudinaryUrls.length} Cloudinary images.`);
    }

    console.log('\nRe-seeding completed successfully!');

  } catch (error) {
    console.error('Error during seeding:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
    process.exit(0);
  }
};

seedBeaches();
