import 'package:cloud_firestore/cloud_firestore.dart';

class SplitParticipant {
  final String name;
  final double shareAmount;
  final bool isPaid;
  final String? txRef;
  final DateTime? paidAt;

  SplitParticipant({
    required this.name,
    required this.shareAmount,
    this.isPaid = false,
    this.txRef,
    this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shareAmount': shareAmount,
      'isPaid': isPaid,
      'txRef': txRef,
      'paidAt': paidAt?.millisecondsSinceEpoch,
    };
  }

  factory SplitParticipant.fromMap(Map<String, dynamic> map) {
    return SplitParticipant(
      name: map['name'] ?? '',
      shareAmount: (map['shareAmount'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      txRef: map['txRef'],
      paidAt: map['paidAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['paidAt']) : null,
    );
  }
}

class SplitRequest {
  final String id;
  final String orderId;
  final String creatorId;
  final double totalAmount;
  final List<SplitParticipant> participants;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;

  SplitRequest({
    required this.id,
    required this.orderId,
    required this.creatorId,
    required this.totalAmount,
    required this.participants,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'creatorId': creatorId,
      'totalAmount': totalAmount,
      'participants': participants.map((p) => p.toMap()).toList(),
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SplitRequest.fromMap(Map<String, dynamic> map) {
    return SplitRequest(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      participants: (map['participants'] as List<dynamic>?)
          ?.map((p) => SplitParticipant.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
  
  double get paidAmount {
    return participants.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.shareAmount);
  }

  bool get isFullyPaid => status == 'completed' || paidAmount >= totalAmount;
}
