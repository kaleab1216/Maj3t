import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Reservation {
  final String reservationId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantId;
  final String restaurantName;
  final DateTime reservationDate;
  final TimeOfDay reservationTime;
  final int partySize;
  final String status; // 'pending', 'confirmed', 'seated', 'cancelled', 'no_show', 'completed'
  final String? tableId;
  final int? tableNumber;
  final String? specialRequests;
  final String? notes; // Internal notes from restaurant
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? seatedAt;
  final DateTime? cancelledAt;

  Reservation({
    required this.reservationId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.reservationDate,
    required this.reservationTime,
    required this.partySize,
    required this.status,
    this.tableId,
    this.tableNumber,
    this.specialRequests,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.seatedAt,
    this.cancelledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'reservationDate': reservationDate.millisecondsSinceEpoch,
      'reservationTimeHour': reservationTime.hour,
      'reservationTimeMinute': reservationTime.minute,
      'partySize': partySize,
      'status': status,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'specialRequests': specialRequests,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'seatedAt': seatedAt?.millisecondsSinceEpoch,
      'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      reservationId: map['reservationId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      reservationDate: DateTime.fromMillisecondsSinceEpoch(map['reservationDate'] ?? 0),
      reservationTime: TimeOfDay(
        hour: (map['reservationTimeHour'] ?? 12).toInt(),
        minute: (map['reservationTimeMinute'] ?? 0).toInt(),
      ),
      partySize: (map['partySize'] ?? 2).toInt(),
      status: map['status'] ?? 'pending',
      tableId: map['tableId'],
      tableNumber: map['tableNumber'],
      specialRequests: map['specialRequests'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      seatedAt: map['seatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['seatedAt'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['cancelledAt'])
          : null,
    );
  }

  DateTime get reservationDateTime {
    return DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      reservationTime.hour,
      reservationTime.minute,
    );
  }

  String get formattedTime {
    final hour = reservationTime.hourOfPeriod;
    final minute = reservationTime.minute.toString().padLeft(2, '0');
    final period = reservationTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get formattedDate {
    return '${reservationDate.day}/${reservationDate.month}/${reservationDate.year}';
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return reservationDateTime.isAfter(now) && status != 'cancelled';
  }

  bool get isToday {
    final now = DateTime.now();
    return reservationDate.year == now.year &&
        reservationDate.month == now.month &&
        reservationDate.day == now.day;
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'seated':
        return 'Seated';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'seated':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Reservation copyWith({
    String? reservationId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantId,
    String? restaurantName,
    DateTime? reservationDate,
    TimeOfDay? reservationTime,
    int? partySize,
    String? status,
    String? tableId,
    int? tableNumber,
    String? specialRequests,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? seatedAt,
    DateTime? cancelledAt,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      specialRequests: specialRequests ?? this.specialRequests,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seatedAt: seatedAt ?? this.seatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}