import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class ReservationViewModel with ChangeNotifier {
  final ReservationService _reservationService;
  List<Reservation> _reservations = [];
  List<Reservation> _todayReservations = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  // Stream Subscriptions
  StreamSubscription<List<Reservation>>? _allReservationsSub;
  StreamSubscription<List<Reservation>>? _todayReservationsSub;

  ReservationViewModel(this._reservationService);

  // Getters
  List<Reservation> get reservations => _reservations;
  List<Reservation> get todayReservations => _todayReservations;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Reservation> get upcomingReservations {
    return _reservations.where((r) => r.isUpcoming).toList();
  }

  List<Reservation> get pendingReservations {
    return _reservations.where((r) => r.status == 'pending').toList();
  }

  List<Reservation> get confirmedReservations {
    return _reservations.where((r) => r.status == 'confirmed').toList();
  }

  // Helper for sorting by time components (client-side)
  void _sortReservations(List<Reservation> list) {
    list.sort((a, b) {
      // First by date
      int dateCompare = a.reservationDate.compareTo(b.reservationDate);
      if (dateCompare != 0) return dateCompare;
      
      // Then by hour
      int hourCompare = a.reservationTime.hour.compareTo(b.reservationTime.hour);
      if (hourCompare != 0) return hourCompare;
      
      // Then by minute
      return a.reservationTime.minute.compareTo(b.reservationTime.minute);
    });
  }

  // Load reservations by customer
  Future<void> loadCustomerReservations(String customerId) async {
    _setLoading(true);

    try {
      final stream = _reservationService.getReservationsByCustomer(customerId);

      await for (final reservations in stream) {
        _reservations = reservations;
        notifyListeners();
        break; // Keep legacy behavior for customers for now unless needed
      }
    } catch (e) {
      _error = "Failed to load reservations: $e";
      print('Error loading reservations: $e');
    }

    _setLoading(false);
  }

  // Load reservations by restaurant (Real-time + Future Fallback)
  void loadRestaurantReservations(String restaurantId) {
    debugPrint('=========================================');
    debugPrint('RESERVATION_DIAGNOSTIC: Loading for ID: $restaurantId');
    debugPrint('=========================================');
    
    _setLoading(true);

    _allReservationsSub?.cancel();
    _todayReservationsSub?.cancel();

    // 1. One-time fetch to quickly clear errors if streams have issues
    _reservationService.getReservationsByRestaurantFuture(restaurantId).then((reservations) {
      if (reservations.isNotEmpty) {
        debugPrint('RESERVATION_DIAGNOSTIC: Future fetch success! Count: ${reservations.length}');
        _reservations = List.from(reservations);
        _sortReservations(_reservations);
        _isLoading = false;
        _notifyUpdate();
      }
    }).catchError((e) {
      debugPrint('RESERVATION_DIAGNOSTIC: Future fetch failed: $e');
    });

    try {
      // 2. Real-time stream
      _allReservationsSub = _reservationService
          .getReservationsByRestaurant(restaurantId)
          .listen((reservations) {
            debugPrint('RESERVATION_DIAGNOSTIC: Stream update received. Count: ${reservations.length}');
            _reservations = List.from(reservations);
            _sortReservations(_reservations);
            _isLoading = false;
            _notifyUpdate();
          }, onError: (e) {
            debugPrint('RESERVATION_DIAGNOSTIC: Stream error: $e');
            _error = "[RESERVATION_DEBUG_V3] Failed: ${e.toString()}";
            _isLoading = false;
            _notifyUpdate();
          });

      // 3. Today's reservations stream
      _todayReservationsSub = _reservationService
          .getTodayReservations(restaurantId)
          .listen((reservations) {
            _todayReservations = List.from(reservations);
            _sortReservations(_todayReservations);
            _loadStatistics(restaurantId);
            _notifyUpdate();
          }, onError: (e) {
            debugPrint('RESERVATION_DIAGNOSTIC: Today stream error: $e');
          });

    } catch (e) {
      debugPrint('RESERVATION_DIAGNOSTIC: General exception: $e');
      _error = "[RESERVATION_DEBUG_V3] General crash: $e";
      _isLoading = false;
      _notifyUpdate();
    }
  }

  // Load statistics
  Future<void> _loadStatistics(String restaurantId) async {
    try {
      _statistics = await _reservationService.getReservationStatistics(restaurantId);
      // We don't call notifyListeners here directly to avoid double-painting
      // if it's called from a stream listener that already notifies.
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  // Batch notifications to prevent UI churn
  bool _isUpdatePending = false;
  void _notifyUpdate() {
    if (_isUpdatePending) return;
    _isUpdatePending = true;
    
    // Use a microtask to batch multiple updates in one frame
    scheduleMicrotask(() {
      _isUpdatePending = false;
      notifyListeners();
    });
  }

  // Create new reservation
  Future<Reservation?> createReservation({
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
    _setLoading(true);

    try {
      final reservation = await _reservationService.createReservation(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        reservationDate: reservationDate,
        reservationTime: reservationTime,
        partySize: partySize,
        specialRequests: specialRequests,
        tableId: tableId,
      );

      // No need to manually insert into lists if we have an active stream listener
      // But we'll do it for fallback/immediate response
      _reservations.insert(0, reservation);
      _sortReservations(_reservations);
      
      if (reservation.isToday) {
        _todayReservations.add(reservation);
        _sortReservations(_todayReservations);
      }
      notifyListeners();

      // Update statistics
      await _loadStatistics(restaurantId);

      _setLoading(false);
      return reservation;
    } catch (e) {
      _error = "Failed to create reservation: $e";
      _setLoading(false);
      return null;
    }
  }

  // Update reservation status
  Future<bool> updateReservationStatus({
    required String reservationId,
    required String status,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    _setLoading(true);

    try {
      await _reservationService.updateReservationStatus(
        reservationId: reservationId,
        status: status,
        tableId: tableId,
        tableNumber: tableNumber,
        notes: notes,
      );

      // Local updates are handled by the stream listener usually, 
      // but we update manually for snappy UI
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        _reservations[index] = reservation.copyWith(
          status: status,
          tableId: tableId ?? reservation.tableId,
          tableNumber: tableNumber ?? reservation.tableNumber,
        );

        if (reservation.isToday) {
          final todayIndex = _todayReservations.indexWhere((r) => r.reservationId == reservationId);
          if (todayIndex != -1) {
            _todayReservations[todayIndex] = _reservations[index];
          }
        }

        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to update reservation: $e";
      _setLoading(false);
      return false;
    }
  }

  // Confirm reservation
  Future<bool> confirmReservation({
    required String reservationId,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    return await updateReservationStatus(
      reservationId: reservationId,
      status: 'confirmed',
      tableId: tableId,
      tableNumber: tableNumber,
      notes: notes,
    );
  }

  // Mark as seated
  Future<bool> markAsSeated({
    required String reservationId,
    required String tableId,
    required int tableNumber,
  }) async {
    _setLoading(true);

    try {
      await _reservationService.markAsSeated(
        reservationId: reservationId,
        tableId: tableId,
        tableNumber: tableNumber,
      );

      // Local update
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        _reservations[index] = reservation.copyWith(
          status: 'seated',
          tableId: tableId,
          tableNumber: tableNumber,
          seatedAt: DateTime.now(),
        );

        if (reservation.isToday) {
          _todayReservations.removeWhere((r) => r.reservationId == reservationId);
        }

        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to mark as seated: $e";
      _setLoading(false);
      return false;
    }
  }

  // Cancel reservation
  Future<bool> cancelReservation({
    required String reservationId,
    String? notes,
  }) async {
    _setLoading(true);

    try {
      await _reservationService.cancelReservation(
        reservationId: reservationId,
        notes: notes,
      );

      // Local update
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        _reservations[index] = reservation.copyWith(
          status: 'cancelled',
          cancelledAt: DateTime.now(),
        );

        if (reservation.isToday) {
          _todayReservations.removeWhere((r) => r.reservationId == reservationId);
        }

        notifyListeners();
      }

      // Update statistics
      if (_reservations.isNotEmpty) {
        final restaurantId = _reservations.first.restaurantId;
        await _loadStatistics(restaurantId);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to cancel reservation: $e";
      _setLoading(false);
      return false;
    }
  }

  // Check availability
  Future<bool> checkAvailability({
    required String restaurantId,
    required DateTime date,
    required TimeOfDay time,
    required int partySize,
  }) async {
    try {
      return await _reservationService.checkAvailability(
        restaurantId: restaurantId,
        date: date,
        time: time,
        partySize: partySize,
      );
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _allReservationsSub?.cancel();
    _todayReservationsSub?.cancel();
    super.dispose();
  }
}
