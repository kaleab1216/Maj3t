class Payment {
  final String paymentId;
  final String orderId;
  final String customerId;
  final String restaurantId;
  final double amount;
  final String method; // 'card', 'mobile_money', 'cash', 'bank_transfer'
  final String status; // 'pending', 'processing', 'completed', 'failed', 'refunded'
  final String? transactionId; // From payment gateway
  final String? paymentGateway; // 'stripe', 'paypal', 'mobile_money_provider'
  final Map<String, dynamic>? paymentDetails; // Additional payment info
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  Payment({
    required this.paymentId,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.paymentGateway,
    this.paymentDetails,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'amount': amount,
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'paymentGateway': paymentGateway,
      'paymentDetails': paymentDetails,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['paymentId'] ?? '',
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      method: map['method'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      paymentGateway: map['paymentGateway'],
      paymentDetails: map['paymentDetails'] != null
          ? Map<String, dynamic>.from(map['paymentDetails'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      failureReason: map['failureReason'],
    );
  }

  Payment copyWith({
    String? paymentId,
    String? orderId,
    String? customerId,
    String? restaurantId,
    double? amount,
    String? method,
    String? status,
    String? transactionId,
    String? paymentGateway,
    Map<String, dynamic>? paymentDetails,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}