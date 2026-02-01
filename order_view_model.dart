import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/order_service.dart';

class OrderViewModel with ChangeNotifier {
  final OrderService _orderService;

  List<Order> _orders = [];
  Order? _currentOrder;
  List<OrderItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _ordersSubscription;

  OrderViewModel(this._orderService);

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  List<OrderItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cartItems.length;

  // Load orders by customer (Real-time)
  void loadCustomerOrders(String customerId) {
    print('📦 OrderViewModel: Loading orders for customer: $customerId');
    _setLoading(true);
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService.getOrdersByCustomer(customerId).listen(
      (orders) {
        print('📦 OrderViewModel: Received ${orders.length} orders for customer: $customerId');
        _orders = orders;
        _isLoading = false;
        _error = null;
        Future.microtask(() => notifyListeners());
      },
      onError: (e) {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      },
    );
  }

  // Load orders by restaurant (Real-time)
  void loadRestaurantOrders(String restaurantId) {
    _setLoading(true);
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService.getOrdersByRestaurant(restaurantId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        _error = null;
        Future.microtask(() => notifyListeners());
      },
      onError: (e) {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      },
    );
  }

  // Load active orders by restaurant (Real-time)
  void loadActiveRestaurantOrders(String restaurantId) {
    _setLoading(true);
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService.getActiveOrdersByRestaurant(restaurantId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        _error = null;
        Future.microtask(() => notifyListeners());
      },
      onError: (e) {
        _error = 'Failed to load active orders: $e';
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      },
    );
  }

  // Create new order
  Future<Order?> createOrder({
    required String customerId,
    required String customerName,
    required String restaurantId,
    required String restaurantName,
    String orderType = 'dine_in',
    String? tableNumber,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? deliveryFee,
    String paymentMethod = 'cash',
    String? specialInstructions,
  }) async {
    _setLoading(true);
    try {
      final order = await _orderService.createCustomerOrder(
        customerId: customerId,
        customerName: customerName,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: List.from(_cartItems),
        orderType: orderType,
        tableNumber: tableNumber,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryFee: deliveryFee,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
      );

      _currentOrder = order;
      _orders.insert(0, order);
      _clearCart();

      _setLoading(false);
      return order;
    } catch (e) {
      _error = 'Failed to create order: $e';
      _setLoading(false);
      return null;
    }
  }

  // Cart Management
  void addToCart({
    required String menuItemId,
    required String menuItemName,
    required double price,
    int quantity = 1,
    String specialRequest = '',
  }) {
    // Check if item already in cart
    final existingIndex = _cartItems.indexWhere(
            (item) => item.menuItemId == menuItemId && item.specialRequest == specialRequest
    );

    if (existingIndex != -1) {
      // Update quantity of existing item
      _cartItems[existingIndex] = OrderItem(
        quantity: _cartItems[existingIndex].quantity + quantity,
        specialRequest: specialRequest,
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        price: price,
      );
    } else {
      // Add new item to cart
      _cartItems.add(OrderItem(
        quantity: quantity,
        specialRequest: specialRequest,
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        price: price,
      ));
    }

    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _cartItems.length && quantity > 0) {
      // Create new OrderItem with updated quantity
      final item = _cartItems[index];
      _cartItems[index] = OrderItem(
        quantity: quantity,
        specialRequest: item.specialRequest,
        menuItemId: item.menuItemId,
        menuItemName: item.menuItemName,
        price: item.price,
      );
      notifyListeners();
    }
  }

  void updateCartItemSpecialRequest(int index, String specialRequest) {
    if (index >= 0 && index < _cartItems.length) {
      // Create new OrderItem with updated special request
      final item = _cartItems[index];
      _cartItems[index] = OrderItem(
        quantity: item.quantity,
        specialRequest: specialRequest,
        menuItemId: item.menuItemId,
        menuItemName: item.menuItemName,
        price: item.price,
      );
      notifyListeners();
    }
  }
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void _clearCart() {
    _cartItems.clear();
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    try {
      await _orderService.updateOrderStatus(orderId, status);

      // Update in local list
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to update order status: $e';
      _setLoading(false);
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'cancelled');
  }

  // Complete order
  Future<bool> completeOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'completed');
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    _setLoading(true);
    try {
      final order = await _orderService.getOrderById(orderId);
      _currentOrder = order;
      _setLoading(false);
      return order;
    } catch (e) {
      _error = 'Failed to get order: $e';
      _setLoading(false);
      return null;
    }
  }

  // Helper methods
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    Future.microtask(() => notifyListeners());
  }

  void clearError() {
    _error = null;
    Future.microtask(() => notifyListeners());
  }

  // Calculate cart total
  double calculateCartTotal() {
    return _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}