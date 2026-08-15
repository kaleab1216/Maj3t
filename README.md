# 🍽️ Maj3t — Digital Dining & Restaurant Management Platform

> A full-featured Flutter and Firebase platform that combines digital
> menus, restaurant management, location services, delivery,
> real-time tracking, bill sharing, notifications, and offline support.

---

## 📱 About The Project

**Maj3t** is a restaurant-focused mobile application developed as my
final-year Computer Science project.

Instead of building only a digital menu, I designed the system as a
broader digital dining platform connecting **customers, restaurants,
orders, delivery, payments, and real-time communication**.

The application was built with **Flutter and Firebase**, with a focus
on real-time data, secure access control, location-based functionality,
and a responsive mobile experience.

---

## ✨ Key Features

### 🍽️ Digital Dining

- Browse restaurant menus
- View food and restaurant information
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
- Driver/delivery workflows
- Delivery status updates
- Real-time delivery tracking

### 🗺️ Location & Maps

- Google Maps integration
- Location services
- Nearby restaurant discovery
- Delivery location tracking
- Route/location visualization

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
- Cloud Functions
- Automated notifications

### 📡 Offline Support

The application is designed to continue working when the internet
connection is unavailable.

Changes can synchronize when the connection is restored.

---

# 🏗️ System Architecture

```text
                         MAJ3T
                           │
                    Flutter Application
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
 Authentication       Firestore          Storage
        │                  │                  │
   Email / Google      Real-time Data       Images
        │                  │                  │
        └────────────┬─────┴──────┬───────────┘
                     │            │
              Cloud Functions    FCM
                     │            │
              Backend Logic    Notifications
                     │
              Google Maps / APIs
