import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentViewModel with ChangeNotifier {
  final PaymentService _paymentService;

  List<Payment> _payments = [];
  Payment? _currentPayment;
  bool _isProcessing = false;
  String? _error;

  PaymentViewModel(this._paymentService);

  // Getters
  List<Payment> get payments => _payments;
  Payment? get currentPayment => _currentPayment;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  // Load payments by customer
  Future<void> loadCustomerPayments(String customerId) async {
    _setProcessing(true);
    try {
      final stream = _paymentService.getPaymentsByCustomer(customerId);
      await for (final payments in stream) {
        _payments = payments;
        notifyListeners();
        break;
      }
    } catch (e) {
      _error = 'Failed to load payments: $e';
      print('Error loading payments: $e');
    }
    _setProcessing(false);
  }

  // Load payments by restaurant
  Future<void> loadRestaurantPayments(String restaurantId) async {
    _setProcessing(true);
    try {
      final stream = _paymentService.getPaymentsByRestaurant(restaurantId);
      await for (final payments in stream) {
        _payments = payments;
        notifyListeners();
        break;
      }
    } catch (e) {
      _error = 'Failed to load payments: $e';
      print('Error loading payments: $e');
    }
    _setProcessing(false);
  }

  // Create payment
  Future<Payment?> createPayment({
    required String orderId,
    required String customerId,
    required String restaurantId,
    required double amount,
    required String method,
    String? transactionId,
    String? paymentGateway,
    Map<String, dynamic>? paymentDetails,
  }) async {
    _setProcessing(true);
    try {
      final payment = await _paymentService.createPayment(
        orderId: orderId,
        customerId: customerId,
        restaurantId: restaurantId,
        amount: amount,
        method: method,
        transactionId: transactionId,
        paymentGateway: paymentGateway,
        paymentDetails: paymentDetails,
      );

      _currentPayment = payment;
      _payments.insert(0, payment);
      notifyListeners();

      _setProcessing(false);
      return payment;
    } catch (e) {
      _error = 'Failed to create payment: $e';
      _setProcessing(false);
      return null;
    }
  }

  // Initialize Chapa Payment
  Future<String?> initializeChapaPayment({
    required String orderId,
    required String customerId,
    required String email,
    required String firstName,
    required String lastName,
    required double amount,
    required String phoneNumber,
  }) async {
    _setProcessing(true);
    try {
      final url = await _paymentService.initializeChapaPayment(
        orderId: orderId,
        customerId: customerId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        amount: amount,
        phoneNumber: phoneNumber,
      );
      _setProcessing(false);
      return url;
    } catch (e) {
      _error = 'Failed to initialize Chapa: $e';
      _setProcessing(false);
      return null;
    }
  }

  // Verify Chapa Payment
  Future<bool> verifyChapaPayment(String txRef) async {
    _setProcessing(true);
    try {
      final success = await _paymentService.verifyChapaPayment(txRef);
      _setProcessing(false);
      return success;
    } catch (e) {
      _error = 'Failed to verify Chapa: $e';
      _setProcessing(false);
      return false;
    }
  }

  // Process mobile money payment
  Future<Map<String, dynamic>> processMobileMoney({
    required String phoneNumber,
    required double amount,
    required String provider,
  }) async {
    _setProcessing(true);
    try {
      final result = await _paymentService.processMobileMoneyPayment(
        phoneNumber: phoneNumber,
        amount: amount,
        provider: provider,
      );

      _setProcessing(false);
      return result;
    } catch (e) {
      _setProcessing(false);
      return {
        'success': false,
        'error': 'Mobile money processing failed: $e',
      };
    }
  }

  // Process card payment
  Future<Map<String, dynamic>> processCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolder,
    required double amount,
  }) async {
    _setProcessing(true);
    try {
      final result = await _paymentService.processCardPayment(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        cardHolder: cardHolder,
        amount: amount,
      );

      _setProcessing(false);
      return result;
    } catch (e) {
      _setProcessing(false);
      return {
        'success': false,
        'error': 'Card processing failed: $e',
      };
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    String? failureReason,
  }) async {
    _setProcessing(true);
    try {
      await _paymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        transactionId: transactionId,
        failureReason: failureReason,
      );

      // Update in local list
      final index = _payments.indexWhere((p) => p.paymentId == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(status: status);
        if (_currentPayment?.paymentId == paymentId) {
          _currentPayment = _currentPayment!.copyWith(status: status);
        }
        notifyListeners();
      }

      _setProcessing(false);
      return true;
    } catch (e) {
      _error = 'Failed to update payment status: $e';
      _setProcessing(false);
      return false;
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getStatistics(String restaurantId) async {
    _setProcessing(true);
    try {
      final stats = await _paymentService.getPaymentStatistics(restaurantId);
      _setProcessing(false);
      return stats;
    } catch (e) {
      _error = 'Failed to get statistics: $e';
      _setProcessing(false);
      return {};
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    _setProcessing(true);
    try {
      final payment = await _paymentService.getPaymentById(paymentId);
      _currentPayment = payment;
      _setProcessing(false);
      return payment;
    } catch (e) {
      _error = 'Failed to get payment: $e';
      _setProcessing(false);
      return null;
    }
  }

  // Get payment by order ID
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    _setProcessing(true);
    try {
      final payment = await _paymentService.getPaymentByOrderId(orderId);
      _currentPayment = payment;
      _setProcessing(false);
      return payment;
    } catch (e) {
      _error = 'Failed to get payment: $e';
      _setProcessing(false);
      return null;
    }
  }

  // Helper methods
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}