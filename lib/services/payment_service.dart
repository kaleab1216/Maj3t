import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Chapa Keys (User should provide these)
  static const String _chapaPublicKey = 'CHAPUBK_TEST-XXXXXXXXXXXXXXX'; 
  static const String _chapaSecretKey = 'CHASECK_TEST-XXXXXXXXXXXXXXX'; 

  // Create new payment
  Future<Payment> createPayment({
    required String orderId,
    required String customerId,
    required String restaurantId,
    required double amount,
    required String method,
    String status = 'pending',
    String? transactionId,
    String? paymentGateway,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final payment = Payment(
        paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
        orderId: orderId,
        customerId: customerId,
        restaurantId: restaurantId,
        amount: amount,
        method: method,
        status: status,
        transactionId: transactionId,
        paymentGateway: paymentGateway,
        paymentDetails: paymentDetails,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('payments')
          .doc(payment.paymentId)
          .set(payment.toMap());

      print('✅ Payment created: ${payment.paymentId}');
      return payment;
    } catch (e) {
      print('❌ Error creating payment: $e');
      rethrow;
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (doc.exists) {
        return Payment.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting payment: $e');
      return null;
    }
  }

  // Get payment by order ID
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Payment.fromMap(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting payment by order: $e');
      return null;
    }
  }

  // Get payments by customer
  Stream<List<Payment>> getPaymentsByCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Payment.fromMap(doc.data()))
        .toList());
  }

  // Get payments by restaurant
  Stream<List<Payment>> getPaymentsByRestaurant(String restaurantId) {
    return _firestore
        .collection('payments')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Payment.fromMap(doc.data()))
        .toList());
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    String? failureReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }

      if (status == 'completed') {
        updateData['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updateData);

      print('✅ Payment status updated: $paymentId -> $status');
    } catch (e) {
      print('❌ Error updating payment status: $e');
      rethrow;
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
    try {
      final txRef = 'TX-${DateTime.now().millisecondsSinceEpoch}';
      
      // DEMO/SANDBOX BYPASS: If keys are placeholders, return a dummy checkout URL
      // This allows the user to test the UI flow without having real keys yet.
      if (_chapaSecretKey.contains('XXXXX')) {
        print('⚠️ Using Chapa Demo Mode (Placeholder Keys Detected)');
        await Future.delayed(const Duration(seconds: 1)); // Simulate network
        return 'https://chapa.co'; // Redirect to Chapa home for demo
      }

      final url = Uri.parse('https://api.chapa.co/v1/transaction/initialize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_chapaSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.toString(),
          'currency': 'ETB',
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'tx_ref': txRef,
          'callback_url': 'https://webhook.site/placeholder',
          'return_url': 'maj3t://payment-callback',
          'customization': {
            'title': 'Maj3t Order',
            'description': 'Payment for Order #$orderId',
          },
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        // Record the transaction reference in Firestore
        await _firestore.collection('payments_metadata').doc(txRef).set({
          'orderId': orderId,
          'customerId': customerId,
          'amount': amount,
          'status': 'initiated',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return decoded['data']['checkout_url'];
      } else {
        print('❌ Chapa initialization failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error initializing Chapa: $e');
      return null;
    }
  }

  // Verify Chapa Payment
  Future<bool> verifyChapaPayment(String txRef) async {
    try {
      // DEMO MODE BYPASS
      if (_chapaSecretKey.contains('XXXXX')) {
        return true;
      }

      final url = Uri.parse('https://api.chapa.co/v1/transaction/verify/$txRef');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_chapaSecretKey',
        },
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        // Update payment metadata
        await _firestore.collection('payments_metadata').doc(txRef).update({
          'status': 'completed',
          'verifiedAt': FieldValue.serverTimestamp(),
          'chapaResponse': decoded['data'],
        });
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error verifying Chapa: $e');
      return false;
    }
  }

  // Process mobile money payment (simulated)
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String provider, // 'm-pesa', 'telebirr', 'cbe-birr'
  }) async {
    try {
      // Simulate API call to mobile money provider
      await Future.delayed(const Duration(seconds: 2));

      // Generate fake transaction ID
      final transactionId = 'MM${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'transactionId': transactionId,
        'message': 'Payment initiated successfully',
        'provider': provider,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Mobile money payment failed: $e',
      };
    }
  }

  // Process card payment (simulated)
  Future<Map<String, dynamic>> processCardPayment({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolder,
    required double amount,
  }) async {
    try {
      // Simulate API call to payment gateway
      await Future.delayed(const Duration(seconds: 3));

      // Generate fake transaction ID
      final transactionId = 'CARD${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'transactionId': transactionId,
        'message': 'Payment processed successfully',
        'gateway': 'stripe',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Card payment failed: $e',
      };
    }
  }

  // Get payment statistics for restaurant
  Future<Map<String, dynamic>> getPaymentStatistics(String restaurantId) async {
    try {
      final payments = await _firestore
          .collection('payments')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      int totalTransactions = payments.docs.length;

      final paymentMethods = <String, int>{};
      final dailyRevenue = <String, double>{};

      for (final doc in payments.docs) {
        final payment = Payment.fromMap(doc.data());
        totalRevenue += payment.amount;

        // Count payment methods
        paymentMethods.update(
          payment.method,
              (value) => value + 1,
          ifAbsent: () => 1,
        );

        // Group by date
        final dateKey = '${payment.createdAt.year}-${payment.createdAt.month}-${payment.createdAt.day}';
        dailyRevenue.update(
          dateKey,
              (value) => value + payment.amount,
          ifAbsent: () => payment.amount,
        );
      }

      return {
        'totalRevenue': totalRevenue,
        'totalTransactions': totalTransactions,
        'averageTransaction': totalTransactions > 0 ? totalRevenue / totalTransactions : 0,
        'paymentMethods': paymentMethods,
        'dailyRevenue': dailyRevenue,
      };
    } catch (e) {
      print('❌ Error getting payment statistics: $e');
      return {
        'totalRevenue': 0,
        'totalTransactions': 0,
        'averageTransaction': 0,
        'paymentMethods': {},
        'dailyRevenue': {},
      };
    }
  }
}