import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../models/table_model.dart';
import './table_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TableService _tableService = TableService();

  // Create new reservation
  Future<Reservation> createReservation({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String restaurantId,
    required String restaurantName,
    required DateTime reservationDate,
    required TimeOfDay reservationTime,
    required int partySize,
    String? specialRequests,
    String? tableId,
  }) async {
    try {
      final reservation = Reservation(
        reservationId: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        reservationDate: reservationDate,
        reservationTime: reservationTime,
        partySize: partySize,
        status: 'pending',
        specialRequests: specialRequests,
        tableId: tableId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservation.reservationId)
          .set(reservation.toMap());

      // If table is specified, reserve it
      if (tableId != null) {
        final reservationEndTime = reservation.reservationDateTime.add(Duration(hours: 2));
        await _tableService.reserveTable(
          restaurantId: restaurantId,
          tableId: tableId,
          reservedUntil: reservationEndTime,
          customerId: customerId,
        );
      }

      print('✅ Reservation created: ${reservation.reservationId}');
      return reservation;
    } catch (e) {
      print('❌ Error creating reservation: $e');
      rethrow;
    }
  }

  // Get reservation by ID
  Future<Reservation?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (doc.exists) {
        return Reservation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting reservation: $e');
      return null;
    }
  }

  // Get reservations by customer
  Stream<List<Reservation>> getReservationsByCustomer(String customerId) {
    return _firestore
        .collection('reservations')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Reservation.fromMap(doc.data()))
        .toList());
  }

  // Get reservations by restaurant
  Stream<List<Reservation>> getReservationsByRestaurant(String restaurantId) {
    return _firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Reservation.fromMap(doc.data()))
        .toList());
  }

  // Get today's reservations (Now uses memory filtering)
  Stream<List<Reservation>> getTodayReservations(String restaurantId) {
    return getReservationsByRestaurant(restaurantId).map((list) {
      final now = DateTime.now();
      return list.where((r) {
        final isToday = r.reservationDate.year == now.year &&
            r.reservationDate.month == now.month &&
            r.reservationDate.day == now.day;
        final isNotCancelled = r.status != 'cancelled';
        return isToday && isNotCancelled;
      }).toList();
    });
  }

  // Get reservations by restaurant (One-time fetch for diagnostics)
  Future<List<Reservation>> getReservationsByRestaurantFuture(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('RESERVATION_DIAGNOSTIC (Service Future): $e');
      rethrow;
    }
  }

  // Update reservation status
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (tableId != null) updates['tableId'] = tableId;
      if (tableNumber != null) updates['tableNumber'] = tableNumber;
      if (notes != null) updates['notes'] = notes;

      if (status == 'seated') {
        updates['seatedAt'] = DateTime.now().millisecondsSinceEpoch;
      } else if (status == 'cancelled') {
        updates['cancelledAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updates);

      print('✅ Reservation status updated: $reservationId -> $status');
    } catch (e) {
      print('❌ Error updating reservation status: $e');
      rethrow;
    }
  }

  // Confirm reservation
  Future<void> confirmReservation({
    required String reservationId,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    await updateReservationStatus(
      reservationId: reservationId,
      status: 'confirmed',
      tableId: tableId,
      tableNumber: tableNumber,
      notes: notes,
    );
  }

  // Mark as seated
  Future<void> markAsSeated({
    required String reservationId,
    required String tableId,
    required int tableNumber,
  }) async {
    // First update reservation
    await updateReservationStatus(
      reservationId: reservationId,
      status: 'seated',
      tableId: tableId,
      tableNumber: tableNumber,
    );

    // Then occupy the table
    final reservation = await getReservationById(reservationId);
    if (reservation != null) {
      await _tableService.occupyTable(
        restaurantId: reservation.restaurantId,
        tableId: tableId,
        orderId: '', // No order ID yet
        customerId: reservation.customerId,
      );
    }
  }

  // Cancel reservation
  Future<void> cancelReservation({
    required String reservationId,
    String? notes,
  }) async {
    final reservation = await getReservationById(reservationId);

    if (reservation != null && reservation.tableId != null) {
      // Free the table if it was reserved
      await _tableService.freeTable(
        restaurantId: reservation.restaurantId,
        tableId: reservation.tableId!,
      );
    }

    await updateReservationStatus(
      reservationId: reservationId,
      status: 'cancelled',
      notes: notes,
    );
  }

  // Check availability for a time slot
  Future<bool> checkAvailability({
    required String restaurantId,
    required DateTime date,
    required TimeOfDay time,
    required int partySize,
  }) async {
    try {
      // 1. Get ALL active tables that can accommodate this party size
      // 1. Get ALL active tables for this restaurant
      final tablesSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter by capacity in memory to avoid needing a Firestore composite index
      final allMatchingTables = tablesSnapshot.docs
          .map((doc) => RestaurantTable.fromMap(doc.data()))
          .where((t) => t.capacity >= partySize)
          .map((t) => t.tableId)
          .toList();

      // 2. Get reservations for that specific date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('reservationDate', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('reservationDate', isLessThan: endOfDay.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed', 'seated'])
          .get();

      final existingReservations = reservationsSnapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();

      // 3. Check for overlapping reservations
      final requestedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      
      // Track which tables are busy at this exact time
      final busyTableIds = <String>{};
      
      for (final res in existingReservations) {
        // Assume each reservation takes 2 hours (this could be configurable later)
        final resStart = res.reservationDateTime;
        final resEnd = resStart.add(Duration(hours: 2));
        
        final requestedEnd = requestedTime.add(Duration(hours: 2));

        // Standard overlap check: (StartA < EndB) and (EndA > StartB)
        if (requestedTime.isBefore(resEnd) && requestedEnd.isAfter(resStart)) {
          if (res.tableId != null) {
            busyTableIds.add(res.tableId!);
          } else {
            // If a reservation doesn't have a specific table assigned yet, 
            // we should still account for it by "consuming" one of the matching tables
            // This is a bit simplified; in a complex system, we'd need to track unassigned counts
            // For now, let's just mark one anonymous "busy" slot if we hit it
            // (Wait, if tableId is null, we can't easily mark it busy in our Set)
          }
        }
      }

      // Calculate how many matching tables are actually free
      final freeTables = allMatchingTables.where((id) => !busyTableIds.contains(id)).toList();
      
      // Handle unassigned reservations (the ones with null tableId)
      int unassignedOverlaps = existingReservations.where((res) {
        final resStart = res.reservationDateTime;
        final resEnd = resStart.add(Duration(hours: 2));
        final requestedEnd = requestedTime.add(Duration(hours: 2));
        return res.tableId == null && requestedTime.isBefore(resEnd) && requestedEnd.isAfter(resStart);
      }).length;

      return (freeTables.length - unassignedOverlaps) > 0;
    } catch (e) {
      print('❌ Error checking availability: $e');
      return false;
    }
  }

  // Get reservation statistics
  Future<Map<String, dynamic>> getReservationStatistics(String restaurantId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's reservations
      final todaySnapshot = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('reservationDate', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .get();

      final todayReservations = todaySnapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();

      int totalToday = todayReservations.length;
      int confirmedToday = todayReservations.where((r) => r.status == 'confirmed').length;
      int seatedToday = todayReservations.where((r) => r.status == 'seated').length;
      int pendingToday = todayReservations.where((r) => r.status == 'pending').length;
      int cancelledToday = todayReservations.where((r) => r.status == 'cancelled').length;

      // Get upcoming reservations
      final upcomingSnapshot = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('reservationDate', isGreaterThanOrEqualTo: now.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final upcomingReservations = upcomingSnapshot.docs.length;

      return {
        'totalToday': totalToday,
        'confirmedToday': confirmedToday,
        'seatedToday': seatedToday,
        'pendingToday': pendingToday,
        'cancelledToday': cancelledToday,
        'upcomingReservations': upcomingReservations,
        'noShowRate': totalToday > 0 ? (cancelledToday / totalToday) * 100 : 0,
      };
    } catch (e) {
      print('❌ Error getting reservation statistics: $e');
      return {
        'totalToday': 0,
        'confirmedToday': 0,
        'seatedToday': 0,
        'pendingToday': 0,
        'cancelledToday': 0,
        'upcomingReservations': 0,
        'noShowRate': 0,
      };
    }
  }
}