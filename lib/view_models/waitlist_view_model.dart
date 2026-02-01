import 'package:flutter/foundation.dart';
import '../models/waitlist_model.dart';
import '../services/waitlist_service.dart';

class WaitlistViewModel with ChangeNotifier {
  final WaitlistService _waitlistService;
  List<WaitlistEntry> _waitlist = [];
  List<WaitlistEntry> _activeWaitlist = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;

  WaitlistViewModel(this._waitlistService);

  // Getters
  List<WaitlistEntry> get waitlist => _waitlist;
  List<WaitlistEntry> get activeWaitlist => _activeWaitlist;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get waitingCount => _activeWaitlist.length;

  // Load waitlist for restaurant
  Future<void> loadWaitlist(String restaurantId) async {
    _setLoading(true);

    try {
      // Load all waitlist entries
      final allStream = _waitlistService.getWaitlistByRestaurant(restaurantId);
      await for (final entries in allStream) {
        _waitlist = entries;
        notifyListeners();
        break;
      }

      // Load active waitlist
      final activeStream = _waitlistService.getActiveWaitlist(restaurantId);
      await for (final entries in activeStream) {
        _activeWaitlist = entries;
        notifyListeners();
        break;
      }

      // Load statistics
      await _loadStatistics(restaurantId);
    } catch (e) {
      _error = "Failed to load waitlist: $e";
      print('Error loading waitlist: $e');
    }

    _setLoading(false);
  }

  // Load statistics
  Future<void> _loadStatistics(String restaurantId) async {
    try {
      _statistics = await _waitlistService.getWaitlistStatistics(restaurantId);
      notifyListeners();
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  // Join waitlist
  Future<WaitlistEntry?> joinWaitlist({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String restaurantId,
    required String restaurantName,
    required int partySize,
    String? specialRequests,
  }) async {
    _setLoading(true);

    try {
      // Check if already on waitlist
      final isAlready = await _waitlistService.isCustomerOnWaitlist(
        restaurantId: restaurantId,
        customerId: customerId,
      );

      if (isAlready) {
        _error = "You are already on the waitlist";
        _setLoading(false);
        return null;
      }

      final entry = await _waitlistService.joinWaitlist(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        partySize: partySize,
        specialRequests: specialRequests,
      );

      // Add to local lists
      _waitlist.insert(0, entry);
      _activeWaitlist.add(entry);
      _activeWaitlist.sort((a, b) => a.joinTime.compareTo(b.joinTime));
      notifyListeners();

      // Update statistics
      await _loadStatistics(restaurantId);

      _setLoading(false);
      return entry;
    } catch (e) {
      _error = "Failed to join waitlist: $e";
      _setLoading(false);
      return null;
    }
  }

  // Update waitlist status
  Future<bool> updateWaitlistStatus({
    required String waitlistId,
    required String status,
    String? tableId,
    int? tableNumber,
    String? notes,
  }) async {
    _setLoading(true);

    try {
      await _waitlistService.updateWaitlistStatus(
        waitlistId: waitlistId,
        status: status,
        tableId: tableId,
        tableNumber: tableNumber,
        notes: notes,
      );

      // Update local lists
      final index = _waitlist.indexWhere((e) => e.waitlistId == waitlistId);
      if (index != -1) {
        final entry = _waitlist[index];
        _waitlist[index] = entry.copyWith(
          status: status,
          tableId: tableId ?? entry.tableId,
          tableNumber: tableNumber ?? entry.tableNumber,
        );

        // Update active waitlist
        if (status == 'waiting') {
          if (!_activeWaitlist.any((e) => e.waitlistId == waitlistId)) {
            _activeWaitlist.add(_waitlist[index]);
            _activeWaitlist.sort((a, b) => a.joinTime.compareTo(b.joinTime));
          }
        } else {
          _activeWaitlist.removeWhere((e) => e.waitlistId == waitlistId);
        }

        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to update waitlist: $e";
      _setLoading(false);
      return false;
    }
  }

  // Seat customer
  Future<bool> seatCustomer({
    required String waitlistId,
    required String tableId,
    required int tableNumber,
  }) async {
    _setLoading(true);

    try {
      await _waitlistService.seatCustomer(
        waitlistId: waitlistId,
        tableId: tableId,
        tableNumber: tableNumber,
      );

      // Update local list
      final index = _waitlist.indexWhere((e) => e.waitlistId == waitlistId);
      if (index != -1) {
        final entry = _waitlist[index];
        _waitlist[index] = entry.copyWith(
          status: 'seated',
          tableId: tableId,
          tableNumber: tableNumber,
          seatedTime: DateTime.now(),
        );

        // Remove from active waitlist
        _activeWaitlist.removeWhere((e) => e.waitlistId == waitlistId);
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to seat customer: $e";
      _setLoading(false);
      return false;
    }
  }

  // Cancel waitlist entry
  Future<bool> cancelWaitlistEntry({
    required String waitlistId,
    String? notes,
  }) async {
    return await updateWaitlistStatus(
      waitlistId: waitlistId,
      status: 'cancelled',
      notes: notes,
    );
  }

  // Get estimated wait time
  Future<int> getEstimatedWaitTime({
    required String restaurantId,
    required int partySize,
  }) async {
    try {
      return await _waitlistService.getEstimatedWaitTime(
        restaurantId: restaurantId,
        partySize: partySize,
      );
    } catch (e) {
      print('Error getting estimated wait time: $e');
      return 30; // Default 30 minutes
    }
  }

  // Check if customer is on waitlist
  Future<bool> isCustomerOnWaitlist({
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      return await _waitlistService.isCustomerOnWaitlist(
        restaurantId: restaurantId,
        customerId: customerId,
      );
    } catch (e) {
      print('Error checking waitlist: $e');
      return false;
    }
  }

  // Get customer's waitlist position
  Future<WaitlistEntry?> getCustomerWaitlistPosition({
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      return await _waitlistService.getCustomerWaitlistPosition(
        restaurantId: restaurantId,
        customerId: customerId,
      );
    } catch (e) {
      print('Error getting waitlist position: $e');
      return null;
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
}