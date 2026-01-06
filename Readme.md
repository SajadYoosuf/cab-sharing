# EcoRide: Sustainable Ride-Sharing Platform 🚗🌱

EcoRide is a premium, gamified ride-sharing mobile application built with Flutter and Firebase. It focuses on reducing carbon footprints by encouraging carpooling and providing real-time ECO tracking for every trip.

## ✨ Features

### 🔐 Authentication & Security
- **Secure Login/Registration**: Powered by Firebase Auth.
- **Splash Screen**: Professional onboarding experience.
- **SOS Emergency System**: One-tap emergency alert system for passenger safety.

### 🚘 Ride Management
- **Offer a Ride**: Comprehensive form for drivers to share their journey.
- **Find a Ride**: Real-time search for available carpools nearby.
- **Interactive Location Picker**: Visual map integration (OpenStreetMap) for precise origin and destination selection.
- **Ride Capacity Control**: Set seat availability and pricing dynamically.

### 💬 Real-time Communication
- **In-App Group Chat**: Real-time messaging for every ride session using Firestore streams.
- **Premium UI**: Bubble-style chat interface with sender identification.

### 🌍 ECO Tracker (Sustainability)
- **CO2 Savings Calculation**: Automatically tracks the positive environmental impact ($0.2kg$ CO2 saved per km).
- **Dashboard Stats**: Visual representation of the user's total environmental contribution.

### 🛠 Administrative Tools
- **Admin Dashboard**: Full visibility into all rides and user activities.
- **Moderation**: Ability to delete or manage ride listings for safety and compliance.

---

## 🏗 Architecture

The project follows the **Clean Architecture** pattern to ensure scalability, maintainability, and testability.

### Layer Structure:
- **📂 lib/core**: Global constants, themes, and shared services (Location, API, etc.).
- **📂 lib/features**: Modularized features (Auth, Ride, Chat, Admin, Home).
  - **📁 data**: API implementations, repositories, and models.
  - **📁 domain**: Business logic, entities, and repository interfaces.
  - **📁 presentation**: UI components (Pages, Widgets) and state management (Providers).

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Maps**: [Flutter Map](https://pub.dev/packages/flutter_map) & [OpenStreetMap](https://www.openstreetmap.org/)
- **Animations**: [Flutter Animate](https://pub.dev/packages/flutter_animate)
- **Typography**: [Google Fonts (Outfit)](https://pub.dev/packages/google_fonts)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version recommended)
- Firebase Account

### Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-repo/eco-ride.git
    cd eco-ride
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase**:
    - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
    - The project uses `firebase_options.dart` for web/desktop support.
4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📄 License
This project is developed as part of the Regional College projects.
