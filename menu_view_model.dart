import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../services/menu_service.dart';

class MenuViewModel with ChangeNotifier {
  final MenuService _menuService;
  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRestaurantId; // Track current restaurant

  MenuViewModel(this._menuService);

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRestaurantId => _currentRestaurantId;

  // Load menu items for a restaurant
  Future<void> loadMenuItems(String restaurantId) async {
    _setLoading(true);
    _currentRestaurantId = restaurantId;

    try {
      final stream = _menuService.getMenuItems(restaurantId);

      await for (final items in stream) {
        _menuItems = items;
        notifyListeners();
        break; // Get first batch
      }
    } catch (e) {
      _error = "Failed to load menu items: $e";
      print('Error loading menu items: $e');
    }

    _setLoading(false);
  }

  // Load categories for a restaurant
  Future<void> loadCategories(String restaurantId) async {
    try {
      final stream = _menuService.getCategories(restaurantId);

      await for (final categoriesList in stream) {
        _categories = categoriesList;
        notifyListeners();
        break;
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Add menu item
  Future<bool> addMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    bool isAvailable = true,
    String? imageUrl,
  }) async {
    _setLoading(true);

    try {
      final menuItem = MenuItem(
        itemId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        price: price,
        category: category,
        isAvailable: isAvailable,
        imageUrl: imageUrl,
      );

      await _menuService.addMenuItem(
        restaurantId: restaurantId,
        menuItem: menuItem,
      );

      // Add to local list
      _menuItems.insert(0, menuItem);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to add menu item: $e";
      _setLoading(false);
      return false;
    }
  }

  // Update menu item - Now requires restaurantId parameter
  Future<bool> updateMenuItem({
    required String restaurantId,
    required MenuItem menuItem,
  }) async {
    _setLoading(true);

    try {
      await _menuService.updateMenuItem(
        restaurantId: restaurantId,
        menuItem: menuItem,
      );

      // Update in local list
      final index = _menuItems.indexWhere((item) => item.itemId == menuItem.itemId);
      if (index != -1) {
        _menuItems[index] = menuItem;
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to update menu item: $e";
      _setLoading(false);
      return false;
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(String restaurantId, String itemId) async {
    _setLoading(true);

    try {
      await _menuService.deleteMenuItem(restaurantId, itemId);

      // Remove from local list
      _menuItems.removeWhere((item) => item.itemId == itemId);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Failed to delete menu item: $e";
      _setLoading(false);
      return false;
    }
  }

  // Toggle availability
  Future<bool> toggleMenuItemAvailability({
    required String restaurantId,
    required MenuItem menuItem,
  }) async {
    final updatedItem = menuItem.copyWith(isAvailable: !menuItem.isAvailable);
    return await updateMenuItem(
      restaurantId: restaurantId,
      menuItem: updatedItem,
    );
  }

  // Get menu items by category
  List<MenuItem> getItemsByCategory(String category) {
    return _menuItems.where((item) => item.category == category).toList();
  }

  // Get available menu items
  List<MenuItem> get availableItems {
    return _menuItems.where((item) => item.isAvailable).toList();
  }

  // Get unavailable menu items
  List<MenuItem> get unavailableItems {
    return _menuItems.where((item) => !item.isAvailable).toList();
  }

  // Clear menu items
  void clearMenuItems() {
    _menuItems.clear();
    _categories.clear();
    _currentRestaurantId = null;
    notifyListeners();
  }

  // Helper method
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}