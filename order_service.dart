import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new order from customer
  Future<Order> createCustomerOrder({
    required String customerId,
    required String customerName,
    required String restaurantId,
    required String restaurantName,
    required List<OrderItem> items,
    String orderType = 'dine_in',
    String? tableNumber,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? deliveryFee,
    String paymentMethod = 'cash',
    String? specialInstructions,
  }) async {
    try {
      // Calculate total
      final totalAmount = items.fold(
        0.0,
            (sum, item) => sum + item.subtotal,
      );

      final order = Order(
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId,
        customerName: customerName,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: items,
        totalAmount: totalAmount,
        status: 'pending',
        orderDate: DateTime.now(),
        orderType: orderType,
        tableNumber: tableNumber,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryFee: deliveryFee,
        deliveryStatus: orderType == 'delivery' ? 'pending' : null,
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        specialInstructions: specialInstructions,
      );

      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap());

      print('✅ Order created: ${order.orderId}');
      return order;
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return Order.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      return null;
    }
  }

  // Get orders by customer
  Stream<List<Order>> getOrdersByCustomer(String customerId) {
    print('🔥 Firestore: Fetching orders for customerId: $customerId');
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          print('🔥 Firestore: Found ${snapshot.docs.length} order documents for customerId: $customerId');
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          // Sort client-side to avoid index requirement
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  // Get orders by restaurant
  Stream<List<Order>> getOrdersByRestaurant(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          // Sort client-side to avoid index requirement
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  // Get active orders by restaurant (pending, preparing)
  Stream<List<Order>> getActiveOrdersByRestaurant(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['pending', 'preparing', 'ready']) // Included 'ready' for safety
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          // Sort client-side: Oldest first for kitchen
          orders.sort((a, b) => a.orderDate.compareTo(b.orderDate));
          return orders;
        });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Order status updated: $orderId -> $status');
    } catch (e) {
      print('❌ Error updating order status: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': paymentStatus,
      });

      print('✅ Payment status updated: $orderId -> $paymentStatus');
    } catch (e) {
      print('❌ Error updating payment status: $e');
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  // Mark order as completed
  Future<void> completeOrder(String orderId) async {
    await updateOrderStatus(orderId, 'completed');
  }

  // Calculate order total
  double calculateOrderTotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Get today's orders for restaurant
  Stream<List<Order>> getTodaysOrders(String restaurantId) {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('orderDate', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          // Sort client-side
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }
}