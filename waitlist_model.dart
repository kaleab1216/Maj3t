import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitlistEntry {
  final String waitlistId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantId;
  final String restaurantName;
  final int partySize;
  final DateTime joinTime;
  final String status; // 'waiting', 'seated', 'cancelled', 'no_show', 'left'
  final int? queuePosition;
  final DateTime? estimatedReadyTime;
  final DateTime? seatedTime;
  final DateTime? cancelledTime;
  final String? notes;
  final String? tableId;
  final int? tableNumber;
  final String? specialRequests;

  WaitlistEntry({
    required this.waitlistId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.partySize,
    required this.joinTime,
    required this.status,
    this.queuePosition,
    this.estimatedReadyTime,
    this.seatedTime,
    this.cancelledTime,
    this.notes,
    this.tableId,
    this.tableNumber,
    this.specialRequests,
  });

  Map<String, dynamic> toMap() {
    return {
      'waitlistId': waitlistId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'partySize': partySize,
      'joinTime': joinTime.millisecondsSinceEpoch,
      'status': status,
      'queuePosition': queuePosition,
      'estimatedReadyTime': estimatedReadyTime?.millisecondsSinceEpoch,
      'seatedTime': seatedTime?.millisecondsSinceEpoch,
      'cancelledTime': cancelledTime?.millisecondsSinceEpoch,
      'notes': notes,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'specialRequests': specialRequests,
    };
  }

  factory WaitlistEntry.fromMap(Map<String, dynamic> map) {
    return WaitlistEntry(
      waitlistId: map['waitlistId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      partySize: (map['partySize'] ?? 2).toInt(),
      joinTime: DateTime.fromMillisecondsSinceEpoch(map['joinTime'] ?? 0),
      status: map['status'] ?? 'waiting',
      queuePosition: map['queuePosition'],
      estimatedReadyTime: map['estimatedReadyTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['estimatedReadyTime'])
          : null,
      seatedTime: map['seatedTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['seatedTime'])
          : null,
      cancelledTime: map['cancelledTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['cancelledTime'])
          : null,
      notes: map['notes'],
      tableId: map['tableId'],
      tableNumber: map['tableNumber'],
      specialRequests: map['specialRequests'],
    );
  }

  int get waitTime {
    if (seatedTime != null) {
      return seatedTime!.difference(joinTime).inMinutes;
    }
    if (estimatedReadyTime != null) {
      return estimatedReadyTime!.difference(DateTime.now()).inMinutes;
    }
    return 0;
  }

  String get formattedJoinTime {
    return '${joinTime.hour}:${joinTime.minute.toString().padLeft(2, '0')}';
  }

  String get waitTimeText {
    if (status == 'seated') {
      return 'Seated after $waitTime min';
    }
    if (estimatedReadyTime != null) {
      return '~$waitTime min wait';
    }
    return 'Waiting...';
  }

  bool get isWaiting => status == 'waiting';
  bool get isSeated => status == 'seated';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'waiting':
        return 'Waiting';
      case 'seated':
        return 'Seated';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      case 'left':
        return 'Left';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'seated':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.red;
      case 'left':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  WaitlistEntry copyWith({
    String? waitlistId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantId,
    String? restaurantName,
    int? partySize,
    DateTime? joinTime,
    String? status,
    int? queuePosition,
    DateTime? estimatedReadyTime,
    DateTime? seatedTime,
    DateTime? cancelledTime,
    String? notes,
    String? tableId,
    int? tableNumber,
    String? specialRequests,
  }) {
    return WaitlistEntry(
      waitlistId: waitlistId ?? this.waitlistId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      partySize: partySize ?? this.partySize,
      joinTime: joinTime ?? this.joinTime,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedReadyTime: estimatedReadyTime ?? this.estimatedReadyTime,
      seatedTime: seatedTime ?? this.seatedTime,
      cancelledTime: cancelledTime ?? this.cancelledTime,
      notes: notes ?? this.notes,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }
}