# 🌴 TropicaGuide – Collaborative Travel Planner

## 📌 Project Overview
TropicaGuide is a real-time collaborative travel planning mobile application that helps groups design, organize, and optimize trip itineraries together.

Instead of manually coordinating plans across messages and spreadsheets, TropicaGuide provides a shared digital space where users can build trips, manage activities, and automatically optimize schedules based on time, distance, and budget constraints.

---

## 🎯 Key Features

### 👥 Real-Time Collaboration
- Create and join group trips
- Live synchronization of itinerary updates
- Multiple users can edit shared trip data simultaneously

### 🗺️ Itinerary Management
- Add, edit, and organize travel activities
- Drag-and-drop itinerary reordering
- Timeline-based trip structure

### ⚡ Itinerary Optimization (Required Feature)
- Automatically reorders activities based on:
  - Time availability
  - Travel distance
  - Budget constraints
- Shows explanation for why activities were moved

### 🔍 Activity Discovery
- Search and add travel activities
- Store activity details with images

### 🎒 Shared Packing List & Checklist
- Collaborative real-time checklist
- Firestore transaction-based conflict prevention
- Assign items to group members

### 🔔 Push Notifications
- Notifications for:
  - Itinerary updates
  - New activities
  - Checklist changes

---

## 🏗️ Tech Stack

### Frontend
- Flutter (Cross-platform mobile development)

### Backend (Firebase)
- **Firebase Authentication** → User login & identity management
- **Cloud Firestore** → Real-time database for trips and itineraries
- **Firebase Storage** → Image and file uploads
- **Firebase Cloud Messaging (FCM)** → Push notifications

---

## 🧠 System Architecture

- Users authenticate via Firebase Authentication  
- Trip, itinerary, and checklist data stored in Firestore  
- Real-time updates sync across all connected users  
- Activity images stored in Firebase Storage  
- Notifications delivered using FCM  
- Itinerary optimizer processes activity data and dynamically reorders plans  

---

## 🔄 Firestore Data Model

```text
users/
  userId/
    name
    email
    trips[]

trips/
  tripId/
    title
    members[]
    itinerary[]
    checklist[]

activities/
  activityId/
    name
    location
    cost
    duration
    distance
    imageURL
``` id="p9kq1a"

---

## ⚙️ Core Challenges

- Real-time multi-user synchronization
- Conflict resolution in shared editing
- Drag-and-drop itinerary UI
- Complex nested Firestore data structure
- Designing and implementing optimization logic

---

## 🧪 Testing Strategy

We will test the following:

- User authentication (sign up / login)
- Trip creation and joining
- Real-time collaboration updates
- Itinerary optimization correctness
- Notification delivery system

### 📊 Testing Evidence
- Screenshots of features
- Screen recordings of workflows
- Firebase console logs
- Test case documentation

---

## 📅 Development Plan

### Phase 1
- Firebase Authentication
- User profile system

### Phase 2
- Trip creation system
- Activity database and storage integration

### Phase 3
- Real-time collaboration features
- Shared checklist system
- Itinerary optimizer implementation
- Push notifications (FCM)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Firebase project setup
- Android Studio or VS Code

### Installation

```bash
git clone https://github.com/your-team/tropica-guide.git
cd tropica-guide
flutter pub get