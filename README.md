# EcoRide - Advanced AI Cab-Sharing & Eco-Tracker

EcoRide is a premium, state-of-the-art cab-sharing application built with Flutter and Firebase. It focuses on sustainability, safety, and a seamless user experience, featuring an advanced verification system, real-time tracking, and a comprehensive admin oversight dashboard.

## 🚀 Key Features

### 🔐 Advanced Verification Flow
*   **Identity Verification**: Users must upload an identity document for security.
*   **Selfie Matching**: Real-time selfie upload for profile authenticity.
*   **Driving License**: Mandatory for users who wish to offer rides.
*   **Approval Workflow**: A dedicated admin panel verifies and approves/rejects users based on their documents.

### 🚗 Ride Management
*   **Offer/Request Rides**: Users can offer their vehicle or request to join others.
*   **Seat Management**: Real-time seat availability updates on request acceptance.
*   **Preferences**: Set trip rules like No Smoking, No Alcohol, No Pets, or No Luggage.
*   **Trip Status**: Lifecycle management from `Open` -> `Booked` -> `Ongoing` -> `Completed`.

### 📱 Dynamic Home Page
*   **My Active Rides**: A dedicated horizontal section for all current engagements (Hosted, Accepted, or Pending).
*   **Real-time Notifications**: Badge-based alerts for new administrative announcements or ride updates.
*   **Eco-Tracker**: Real-time calculation of CO2 saved by carpooling compared to individual travel.

### 🗺️ Real-time Tracking & Safety
*   **Live Location Sharing**: Hosts can share their live location with passengers during an ongoing trip.
*   **Interactive Maps**: High-performance maps showing picking/dropping points and live markers.
*   **Emergency SOS**: Instant SOS button in trip details for immediate assistance/alerts.

### 💬 Communication & Feedback
*   **Group Chat**: Secure, real-time chat for every ride to coordinate with participants.
*   **Trip Feedback**: Mandatory rating and review system after trip completion.
*   **Verified Profiles**: Visual badges for verified users and star ratings for hosts.

### 🛠️ Admin Dashboard
*   **Overview Stats**: Visualized platform stats (Total Rides, Verified Users, Eco Impact).
*   **User Verification**: List-view and detail-view for reviewing high-res document uploads.
*   **Ride Feedback Log**: Complete oversight of user reviews with links to specific profiles.
*   **Global Announcements**: Ability to broadcast notifications to the entire user base.

## 🛠️ Technology Stack
*   **Frontend**: Flutter (State management via `Provider`)
*   **Backend**: Firebase (Auth, Firestore, Storage)
*   **Design**: Custom Vanilla CSS inspired UI with Glassmorphism and Modern Typography (Outfit).
*   **Analytics**: FL Chart for environmental impact visualization.

## 📦 Getting Started

1.  **Clone the project**
    ```bash
    git clone [repository-url]
    ```
2.  **Install dependencies**
    ```bash
    flutter pub get
    ```
3.  **Setup Firebase**
    *   Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
    *   Initialize Firebase using `flutterfire configure`.
4.  **Run the app**
    ```bash
    flutter run
    ```

## 🔒 Security & Privacy
*   **Encrypted Storage**: Sensitive documents are stored securely in Firebase Storage.
*   **Role-Based Access**: Strict separation between User and Admin functionalities.
*   **Document Masking**: Initial identity reviews are handled exclusively through the secure Admin dashboard.

---
*Built with ❤️ for a Greener Planet.*

## 🧠 Core Logic & Architecture

### 1. User Verification Logic (The "Security Gate")
This distinguishes between a guest, a verified passenger, and a verified driver.
*   **Approval Workflow**: The Admin views high-res files in the Admin Panel.
*   **Dynamic Permissions**: If Admin hits 'Approve', `verificationStatus` becomes `approved`. If a license is present, `licenseStatus` also becomes `approved`, finally unlocking the "Create Ride" feature for that user.

### 2. Ride engagement Logic (The "Booking Loop")
*   **Atomic Seat Management**: When a host accepts a `RideRequest`, the system automatically decrements the `availableSeats`. 
*   **Auto-Status transition**: If seats reach `0`, the ride status changes from `open` to `booked` automatically, preventing over-booking.
*   **Lifecycle Control**: Trips transition through `Open` -> `Booked` -> `Ongoing` -> `Completed`, with specific UI actions (like Live Tracking or Feedback) unlocked at each stage.

### 3. Sustainability Logic (The "Eco-Tracker")
*   **Impact Calculation**: When a trip is marked `completed`, the system calculates CO2 savings based on the distance and number of passengers vs. individual travel.
*   **Global vs. Local Stats**: Savings are attributed to the individual user's profile and aggregated into the Platform's global sustainability dashboard.

### 4. Real-time Communication & Safety
*   **Stream-Based Chat**: Every ride has a dedicated `groupId`. Participants are automatically added upon request acceptance, enabling real-time coordination.
*   **SOS & Live Tracking**: These features are status-locked—only available during `ongoing` trips to ensure privacy while maximizing safety during the actual journey.

### 5. Automated Feedback Loops
*   **Post-Trip Trigger**: Upon ride completion, passengers are presented with a mandatory feedback dialog.
*   **Admin Audit Trail**: Feedback is stored with cross-references to `hostId` and `passengerId`, allowing Admins to audit user behavior directly from the feedback log by tapping into user profiles.
