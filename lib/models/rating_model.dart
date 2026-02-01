class Rating {
  final String ratingId;
  final int value; // 1-5
  final String comment;
  final String customerId;
  final String restaurantId;
  final String? orderId;
  final DateTime createdAt;

  Rating({
    required this.ratingId,
    required this.value,
    required this.comment,
    required this.customerId,
    required this.restaurantId,
    this.orderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ratingId': ratingId,
      'value': value,
      'comment': comment,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'orderId': orderId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      ratingId: map['ratingId'] ?? '',
      value: (map['value'] ?? 0).toInt(),
      comment: map['comment'] ?? '',
      customerId: map['customerId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      orderId: map['orderId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}