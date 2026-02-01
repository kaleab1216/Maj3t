import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantTable {
  final String tableId;
  final String restaurantId;
  final int tableNumber;
  final int capacity; // Number of people
  final String tableType; // 'indoor', 'outdoor', 'private', 'bar'
  final String status; // 'available', 'occupied', 'reserved', 'out_of_service', 'cleaning'
  final String? locationDescription; // e.g., "Near window", "Center of restaurant"
  final bool isActive;
  final DateTime? reservedUntil; // For reservations
  final String? currentOrderId; // If occupied
  final String? currentCustomerId; // If occupied
  final DateTime? lastUpdated;

  RestaurantTable({
    required this.tableId,
    required this.restaurantId,
    required this.tableNumber,
    required this.capacity,
    required this.tableType,
    required this.status,
    this.locationDescription,
    required this.isActive,
    this.reservedUntil,
    this.currentOrderId,
    this.currentCustomerId,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'tableType': tableType,
      'status': status,
      'locationDescription': locationDescription,
      'isActive': isActive,
      'reservedUntil': reservedUntil?.millisecondsSinceEpoch,
      'currentOrderId': currentOrderId,
      'currentCustomerId': currentCustomerId,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory RestaurantTable.fromMap(Map<String, dynamic> map) {
    return RestaurantTable(
      tableId: map['tableId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      tableNumber: (map['tableNumber'] ?? 0).toInt(),
      capacity: (map['capacity'] ?? 2).toInt(),
      tableType: map['tableType'] ?? 'indoor',
      status: map['status'] ?? 'available',
      locationDescription: map['locationDescription'],
      isActive: map['isActive'] ?? true,
      reservedUntil: map['reservedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reservedUntil'])
          : null,
      currentOrderId: map['currentOrderId'],
      currentCustomerId: map['currentCustomerId'],
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
    );
  }

  RestaurantTable copyWith({
    String? tableId,
    String? restaurantId,
    int? tableNumber,
    int? capacity,
    String? tableType,
    String? status,
    String? locationDescription,
    bool? isActive,
    DateTime? reservedUntil,
    String? currentOrderId,
    String? currentCustomerId,
    DateTime? lastUpdated,
  }) {
    return RestaurantTable(
      tableId: tableId ?? this.tableId,
      restaurantId: restaurantId ?? this.restaurantId,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      tableType: tableType ?? this.tableType,
      status: status ?? this.status,
      locationDescription: locationDescription ?? this.locationDescription,
      isActive: isActive ?? this.isActive,
      reservedUntil: reservedUntil ?? this.reservedUntil,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentCustomerId: currentCustomerId ?? this.currentCustomerId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isOccupied => status == 'occupied';
  bool get isOutOfService => status == 'out_of_service';

  String get statusText {
    switch (status) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'occupied':
        return 'Occupied';
      case 'out_of_service':
        return 'Out of Service';
      case 'cleaning':
        return 'Cleaning';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'occupied':
        return Colors.red;
      case 'out_of_service':
        return Colors.grey;
      case 'cleaning':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}