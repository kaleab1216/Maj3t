import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waitlist_model.dart';
import './table_service.dart';

class WaitlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TableService _tableService = TableService();

  // Join waitlist
  Future<WaitlistEntry> joinWaitlist({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String restaurantId,
    required String restaurantName,
    required int partySize,
    String? specialRequests,
  }) async {
    try {
      // Get current waitlist to determine queue position
      final waitlistSnapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'waiting')
          .get();

      final queuePosition = waitlistSnapshot.docs.length + 1;

      // Estimate ready time (15 minutes per group ahead)
      final estimatedReadyTime = DateTime.now().add(Duration(minutes: queuePosition * 15));

      final waitlistEntry = WaitlistEntry(
        waitlistId: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        partySize: partySize,
        joinTime: DateTime.now(),
        status: 'waiting',
        queuePosition: queuePosition,
        estimatedReadyTime: estimatedReadyTime,
        specialRequests: specialRequests,
      );

      await _firestore
          .collection('waitlist')
          .doc(waitlistEntry.waitlistId)
          .set(waitlistEntry.toMap());

      print('✅ Added to waitlist: $customerName (Position: $queuePosition)');
      return waitlistEntry;
    } catch (e) {
      print('❌ Error joining waitlist: $e');
      rethrow;
    }
  }

  // Get waitlist by restaurant
  Stream<List<WaitlistEntry>> getWaitlistByRestaurant(String restaurantId) {
    return _firestore
        .collection('waitlist')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('joinTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => WaitlistEntry.fromMap(doc.data()))
        .toList());
  }

  // Get active waitlist (waiting entries only)
  Stream<List<WaitlistEntry>> getActiveWaitlist(String restaurantId) {
    return _firestore
        .collection('waitlist')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('joinTime', descending: false)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => WaitlistEntry.fromMap(doc.data()))
          .toList();

      // Update queue positions
      for (int i = 0; i < entries.length; i++) {
        entries[i] = entries[i].copyWith(queuePosition: i + 1);
      }

      return entries;
    });
  }

  // Update waitlist status
  Future<void> updateWaitlistStatus({
    required String waitlistId,
    required String status,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (tableId != null) updates['tableId'] = tableId;
      if (tableNumber != null) updates['tableNumber'] = tableNumber;
      if (notes != null) updates['notes'] = notes;

      if (status == 'seated') {
        updates['seatedTime'] = DateTime.now().millisecondsSinceEpoch;
        // Remove estimated time
        updates['estimatedReadyTime'] = null;
      } else if (status == 'cancelled') {
        updates['cancelledTime'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore
          .collection('waitlist')
          .doc(waitlistId)
          .update(updates);

      print('✅ Waitlist status updated: $waitlistId -> $status');
    } catch (e) {
      print('❌ Error updating waitlist status: $e');
      rethrow;
    }
  }

  // Seat customer from waitlist
  Future<void> seatCustomer({
    required String waitlistId,
    required String tableId,
    required int tableNumber,
  }) async {
    // Get waitlist entry
    final doc = await _firestore
        .collection('waitlist')
        .doc(waitlistId)
        .get();

    if (!doc.exists) {
      throw Exception('Waitlist entry not found');
    }

    final entry = WaitlistEntry.fromMap(doc.data()!);

    // Update waitlist status
    await updateWaitlistStatus(
      waitlistId: waitlistId,
      status: 'seated',
      tableId: tableId,
      tableNumber: tableNumber,
    );

    // Occupy the table
    await _tableService.occupyTable(
      restaurantId: entry.restaurantId,
      tableId: tableId,
      orderId: '', // No order ID yet
      customerId: entry.customerId,
    );

    // Update queue positions for remaining waitlist entries
    await _updateQueuePositions(entry.restaurantId);
  }

  // Cancel waitlist entry
  Future<void> cancelWaitlistEntry({
    required String waitlistId,
    String? notes,
  }) async {
    await updateWaitlistStatus(
      waitlistId: waitlistId,
      status: 'cancelled',
      notes: notes,
    );

    // Get entry to update queue positions
    final doc = await _firestore
        .collection('waitlist')
        .doc(waitlistId)
        .get();

    if (doc.exists) {
      final entry = WaitlistEntry.fromMap(doc.data()!);
      await _updateQueuePositions(entry.restaurantId);
    }
  }

  // Update queue positions
  Future<void> _updateQueuePositions(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('joinTime', descending: false)
          .get();

      final entries = snapshot.docs
          .map((doc) => WaitlistEntry.fromMap(doc.data()))
          .toList();

      // Update each entry with new queue position
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        await _firestore
            .collection('waitlist')
            .doc(entry.waitlistId)
            .update({
          'queuePosition': i + 1,
          'estimatedReadyTime': DateTime.now()
              .add(Duration(minutes: (i + 1) * 15))
              .millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('❌ Error updating queue positions: $e');
    }
  }

  // Get estimated wait time
  Future<int> getEstimatedWaitTime({
    required String restaurantId,
    required int partySize,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'waiting')
          .get();

      final waitingCount = snapshot.docs.length;

      // Also check table availability
      final tablesSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .where('isActive', isEqualTo: true)
          .where('capacity', isGreaterThanOrEqualTo: partySize)
          .where('status', isEqualTo: 'available')
          .get();

      final availableTables = tablesSnapshot.docs.length;

      if (availableTables > 0) {
        // If tables are available, minimal wait
        return 10; // 10 minutes for preparation
      }

      // Estimate 15 minutes per group ahead + 10 minutes for preparation
      return (waitingCount * 15) + 10;
    } catch (e) {
      print('❌ Error estimating wait time: $e');
      return 30; // Default 30 minutes
    }
  }

  // Get waitlist statistics
  Future<Map<String, dynamic>> getWaitlistStatistics(String restaurantId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's waitlist entries
      final snapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('joinTime', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .get();

      final entries = snapshot.docs
          .map((doc) => WaitlistEntry.fromMap(doc.data()))
          .toList();

      int totalToday = entries.length;
      int waitingNow = entries.where((e) => e.status == 'waiting').length;
      int seatedToday = entries.where((e) => e.status == 'seated').length;
      int cancelledToday = entries.where((e) => e.status == 'cancelled').length;
      int noShowToday = entries.where((e) => e.status == 'no_show').length;

      // Calculate average wait time
      int totalWaitTime = 0;
      int seatedCount = 0;

      for (final entry in entries.where((e) => e.status == 'seated' && e.seatedTime != null)) {
        totalWaitTime += entry.seatedTime!.difference(entry.joinTime).inMinutes;
        seatedCount++;
      }

      final averageWaitTime = seatedCount > 0 ? totalWaitTime ~/ seatedCount : 0;

      return {
        'totalToday': totalToday,
        'waitingNow': waitingNow,
        'seatedToday': seatedToday,
        'cancelledToday': cancelledToday,
        'noShowToday': noShowToday,
        'averageWaitTime': averageWaitTime,
        'conversionRate': totalToday > 0 ? (seatedToday / totalToday) * 100 : 0,
      };
    } catch (e) {
      print('❌ Error getting waitlist statistics: $e');
      return {
        'totalToday': 0,
        'waitingNow': 0,
        'seatedToday': 0,
        'cancelledToday': 0,
        'noShowToday': 0,
        'averageWaitTime': 0,
        'conversionRate': 0,
      };
    }
  }

  // Check if customer is already on waitlist
  Future<bool> isCustomerOnWaitlist({
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'waiting')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking waitlist: $e');
      return false;
    }
  }

  // Get customer's waitlist position
  Future<WaitlistEntry?> getCustomerWaitlistPosition({
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('waitlist')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'waiting')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WaitlistEntry.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting waitlist position: $e');
      return null;
    }
  }
}