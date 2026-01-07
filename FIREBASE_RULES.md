# UPDATED Firebase Security Rules

**IMPORTANT**: You MUST apply these rules in your Firebase Console for the application to work correctly.

## 1. Cloud Firestore Rules
Go to **Firestore Database** -> **Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Function to check if user is admin
    function isAdmin() {
      return request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Allow users to read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && (request.auth.uid == userId || isAdmin());
    }
    
    // Allow admins to read everything, everyone else can read/write everything 
    // (TEMPORARY FOR DEVELOPMENT - REMOVE IN PRODUCTION)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 2. Storage Rules
Go to **Storage** -> **Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
       // Allow authenticated users to read/write
      allow read, write: if request.auth != null;
    }
  }
}
```
