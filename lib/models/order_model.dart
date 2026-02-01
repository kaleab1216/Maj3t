import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_item_model.dart';

class Order {
  final String orderId;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'preparing', 'ready', 'completed', 'cancelled'
  final DateTime orderDate;
  final String orderType; // 'dine_in', 'takeaway', 'delivery'
  final String? tableNumber; // For dine-in orders
  final String? deliveryAddress; // For delivery orders
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? deliveryFee;
  final String? deliveryDriverId;
  final String? deliveryStatus; // 'pending', 'assigned', 'picked_up', 'delivered'
  final String paymentMethod; // 'cash', 'card', 'mobile_money'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? specialInstructions;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  Order({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.orderType,
    this.tableNumber,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryFee,
    this.deliveryDriverId,
    this.deliveryStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    this.specialInstructions,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId.toString(),
      'customerId': customerId.toString(),
      'customerName': customerName.toString(),
      'restaurantId': restaurantId.toString(),
      'restaurantName': restaurantName.toString(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString(),
      'orderDate': orderDate.millisecondsSinceEpoch,
      'orderType': orderType.toString(),
      'tableNumber': tableNumber?.toString(),
      'deliveryAddress': deliveryAddress?.toString(),
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryFee': deliveryFee,
      'deliveryDriverId': deliveryDriverId?.toString(),
      'deliveryStatus': deliveryStatus?.toString(),
      'paymentMethod': paymentMethod.toString(),
      'paymentStatus': paymentStatus.toString(),
      'specialInstructions': specialInstructions?.toString(),
      'assignedAt': assignedAt?.millisecondsSinceEpoch,
      'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    try {
      // Robust date parsing for Firestore Timestamp vs int
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
        return DateTime.now();
      }

      return Order(
        orderId: map['orderId']?.toString() ?? '',
        customerId: map['customerId']?.toString() ?? '',
        customerName: map['customerName']?.toString() ?? '',
        restaurantId: map['restaurantId']?.toString() ?? '',
        restaurantName: map['restaurantName']?.toString() ?? '',
        items: (map['items'] as List<dynamic>?)
            ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
            [],
        totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
        status: map['status']?.toString() ?? 'pending',
        orderDate: parseDate(map['orderDate']),
        orderType: map['orderType']?.toString() ?? 'dine_in',
        tableNumber: map['tableNumber']?.toString(),
        deliveryAddress: map['deliveryAddress']?.toString(),
        deliveryLatitude: map['deliveryLatitude']?.toDouble(),
        deliveryLongitude: map['deliveryLongitude']?.toDouble(),
        deliveryFee: map['deliveryFee']?.toDouble(),
        deliveryDriverId: map['deliveryDriverId']?.toString(),
        deliveryStatus: map['deliveryStatus']?.toString(),
        paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
        paymentStatus: map['paymentStatus']?.toString() ?? 'pending',
        specialInstructions: map['specialInstructions']?.toString(),
        assignedAt: map['assignedAt'] != null ? parseDate(map['assignedAt']) : null,
        pickedUpAt: map['pickedUpAt'] != null ? parseDate(map['pickedUpAt']) : null,
        deliveredAt: map['deliveredAt'] != null ? parseDate(map['deliveredAt']) : null,
      );
    } catch (e, stack) {
      print('❌ Order.fromMap ERROR: $e');
      print('📦 Problematic Map: $map');
      print('📚 Stack: $stack');
      rethrow;
    }
  }

  // Calculate total (already done via totalAmount)
  double calculateTotal() {
    return totalAmount;
  }

  // Copy with method for updates
  Order copyWith({
    String? orderId,
    String? customerId,
    String? customerName,
    String? restaurantId,
    String? restaurantName,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? orderDate,
    String? orderType,
    String? tableNumber,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? deliveryFee,
    String? deliveryDriverId,
    String? deliveryStatus,
    String? paymentMethod,
    String? paymentStatus,
    String? specialInstructions,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryDriverId: deliveryDriverId ?? this.deliveryDriverId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}