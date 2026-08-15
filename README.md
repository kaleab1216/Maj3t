# 🍽️ Maj3t — Digital Dining & Restaurant Management Platform

> A full-featured Flutter and Firebase platform that combines digital menus, restaurant management, location services, delivery, real-time tracking, bill sharing, notifications, and offline support.

---

## 📱 About The Project

**Maj3t** is a restaurant-focused mobile application developed as my final-year Computer Science project.

Instead of building only a digital menu, I designed the system as a broader digital dining platform connecting **customers, restaurants, orders, delivery, location services, and real-time communication**.

The application was built with **Flutter and Firebase**, with a focus on real-time data, secure access control, location-based functionality, responsive UI, and reliable mobile experiences.

---

## ✨ Key Features

### 🍽️ Digital Dining

- Digital restaurant menus
- Browse food and restaurant information
- Discover nearby restaurants
- Location-based restaurant discovery

### 🏪 Restaurant Management

- Restaurant management
- Menu management
- Food/product management
- Role-based access
- Restaurant-side workflows

### 🚚 Delivery

- Create delivery orders
- Delivery management
- Delivery workflows
- Delivery status updates
- Real-time delivery tracking

### 🗺️ Location & Maps

- Google Maps integration
- Location services
- Nearby restaurant discovery
- Delivery location tracking
- Map-based location visualization

### 💰 Bill Sharing

- Split restaurant bills
- Share expenses with friends
- Track individual contributions

### 🔐 Authentication & Authorization

- Email/password authentication
- Google Sign-In
- Role-based access control
- Firebase Security Rules

### 🔔 Real-Time Features

- Push notifications
- Firebase Cloud Messaging
- Real-time Firestore updates
- Firebase Cloud Functions
- Automated notifications
- Scheduled backend tasks

### 📡 Offline Support

The application supports offline usage so users can continue working when an internet connection is unavailable.

When the connection is restored, changes can synchronize with the backend.

---

## 🏗️ System Architecture

```text
                         MAJ3T
                           │
                    Flutter Application
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
 Authentication       Cloud Firestore     Storage
        │                  │                  │
 Email / Google       Real-time Data       Images
        │                  │                  │
        └────────────┬─────┴──────┬───────────┘
                     │            │
              Cloud Functions    FCM
                     │            │
              Backend Logic    Notifications
                     │
              Google Maps / REST APIs

                                  User Action
                        │
                ┌───────┴───────┐
                │               │
             Online           Offline
                │               │
                ↓               ↓
           Firestore        Local Cache
                │               │
                └───────┬───────┘
                        │
                  Synchronization
                        │
                        ↓
                  Updated State


                  Customer
   │
   ↓
Create Order
   │
   ↓
Restaurant Confirmation
   │
   ↓
Delivery Assignment
   │
   ↓
Pickup
   │
   ↓
In Transit
   │
   ↓
Real-Time Tracking
   │
   ↓
Delivered


                 Restaurant Bill
                       │
             ┌─────────┼─────────┐
             │         │         │
           Friend A  Friend B  Friend C
             │         │         │
           Share      Share     Share
             │         │         │
             └─────────┼─────────┘
                       │
                 Total Covered


                 🌟 What I Learned

Building Maj3t helped me work with concepts beyond basic mobile UI development, including:

Designing multi-role applications
Flutter application architecture
Firebase backend architecture
Real-time data synchronization
Authentication and authorization
Firebase Security Rules
Cloud Functions
Push notifications
Location-based services
Google Maps integration
REST API integration
Offline application behavior
Delivery tracking
Bill-sharing workflows
Git branching and version control
Building a complete application from idea to implementation
🚧 Future Improvements

Possible future improvements include:

Online payment integration
Advanced restaurant analytics
Improved delivery optimization
More detailed order tracking
Improved restaurant discovery
Automated testing
Performance optimization
Improved scalability
Additional restaurant features
🎓 Project Background

Maj3t was developed as my final-year Computer Science project with the goal of solving practical problems around restaurant discovery, digital menus, ordering, delivery, location services, and digital dining.

The project was intentionally designed as a complete application ecosystem rather than a simple academic CRUD application.

👨‍💻 Developer
Kaleab Getachew

Computer Science Graduate | Flutter & Mobile Application Developer

📧 kaleabgetachew43@gmail.com

📌 Project Status

🟢 Development Project

The project is continuously being improved as I explore new features, architecture improvements, and real-world applications of the platform
