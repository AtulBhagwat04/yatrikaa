<h1>
  <img src="assets/logo/LogoRounded.png" alt="Yatrikaa Logo" width="36" />
  Yatrikaa
</h1>

> **A modern travel guide application that helps users discover, plan, and explore destinations with ease.**
>
>
> ## ✨ Key Features
* 🏞️ **Discover Tourist Destinations:** Explore historical, religious, nature, adventure, and heritage places with detailed descriptions, images, timings, and travel tips.
* 🔍 **Smart Search:** Instantly search destinations by name or category with a simple and intuitive search experience.
* 📍 **Nearby Places:** Find nearby tourist attractions, hotels, restaurants, cafés, hospitals, and fuel stations using your current location.
* 🗺️ **Google Maps Integration:** Get directions, calculate travel distance, and navigate directly to your destination.
* ❤️ **Favorites:** Save your favorite destinations and access them anytime from your profile.
* 🧳 **Trip Planner:** Create and manage personalized travel itineraries for your upcoming trips.
* ☁️ **Cloud-Based Backend:** Securely stores user accounts, favorites, and trip information using MongoDB Atlas.
* 📱 **Modern UI:** Designed with Flutter and Material Design for a fast, responsive, and smooth user experience.

---

## 🛠️ Tech Stack & Architecture

Yatrikaa follows a modern full-stack architecture to ensure scalability and performance.

**Core Technologies**

* **Frontend:** Flutter, Dart
* **Backend:** Node.js, Express.js
* **Database:** MongoDB Atlas
* **State Management:** BLoC
* **Authentication:** JWT Authentication
* **Cloud Storage:** Cloudinary
* **Maps & Location:** Google Maps API
* **Architecture:** REST API + Client-Server Architecture

---
## 🧠 Technical Highlights

### 📍 Location-Based Discovery

Yatrikaa uses Google Maps and device location services to help users discover nearby attractions, restaurants, hotels, and navigate to destinations in real time.

### ☁️ Full-Stack Cloud Architecture

The Flutter application communicates with a Node.js REST API while MongoDB Atlas securely stores user data, favorites, and trip information. Images are optimized and delivered using Cloudinary for faster loading and improved performance.

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (Latest Stable)
* Android Studio / VS Code
* Node.js
* MongoDB Atlas Account
* Google Maps API Key

### Installation

1. Clone the repository

```bash
git clone https://github.com/AtulBhagwat04/yatrikaa.git
```

2. Navigate to the project

```bash
cd yatrikaa
```

3. Install Flutter dependencies

```bash
flutter pub get
```

4. Navigate to the backend folder

```bash
cd backend
```

5. Install backend dependencies

```bash
npm install
```

6. Start the backend server

```bash
npm run dev
```

7. Run the Flutter application

```bash
flutter run
```

---

## 📂 Project Structure

```text
yatrikaa/
│
├── 📂 Backend/
│   ├── 📂 scripts/
│   ├── 📂 server/
│   │   ├── 📂 scripts/
│   │   ├── 📂 src/
│   │   │   ├── 📂 config/
│   │   │   ├── 📂 controllers/
│   │   │   ├── 📂 data/
│   │   │   ├── 📂 middleware/
│   │   │   ├── 📂 models/
│   │   │   ├── 📂 routes/
│   │   │   └── 📂 services/
│   │   ├── app.js
│   │   └── index.js
│   │
│   ├── .env.example
│   ├── package.json
│   └── package-lock.json
│
├── 📂 android/
├── 📂 ios/
├── 📂 web/
├── 📂 test/
├── 📂 assets/
│
├── 📂 lib/
│   ├── 📂 core/
│   │   ├── 📂 bloc/
│   │   ├── 📂 constants/
│   │   ├── 📂 models/
│   │   ├── 📂 services/
│   │   ├── 📂 utils/
│   │   └── 📂 widgets/
│   │
│   ├── 📂 views/
│   ├── 📂 Routes/
│   ├── 📂 screens/
│   ├── 📂 widgets/
│   └── main.dart
│
├── 📂 scripts/
├── README.md
└── pubspec.yaml
```

## 📌 Future Improvements

* 🤖 AI-based Travel Recommendations
* 🌦️ Live Weather Updates
* 📴 Offline Maps
* 🌐 Multi-language Support
* 💰 Travel Expense Tracker
* 🏨 Hotel Booking Integration
* 🔔 Push Notifications

---
