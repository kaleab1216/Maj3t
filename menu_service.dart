import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add menu item to restaurant
  Future<void> addMenuItem({
    required String restaurantId,
    required MenuItem menuItem,
  }) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(menuItem.itemId)
          .set(menuItem.toMap());

      print('✅ Menu item added: ${menuItem.name}');
    } catch (e) {
      print('❌ Error adding menu item: $e');
      rethrow;
    }
  }

  // Get all menu items for a restaurant
  Stream<List<MenuItem>> getMenuItems(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menuItems')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MenuItem.fromMap(doc.data()))
        .toList());
  }

  // Get menu items by category
  Stream<List<MenuItem>> getMenuItemsByCategory(
      String restaurantId,
      String category,
      ) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menuItems')
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MenuItem.fromMap(doc.data()))
        .toList());
  }

  // Get menu item by ID
  Future<MenuItem?> getMenuItemById(String restaurantId, String itemId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(itemId)
          .get();

      if (doc.exists) {
        return MenuItem.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting menu item: $e');
      return null;
    }
  }

  // Update menu item
  Future<void> updateMenuItem({
    required String restaurantId,
    required MenuItem menuItem,
  }) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(menuItem.itemId)
          .update(menuItem.toMap());

      print('✅ Menu item updated: ${menuItem.name}');
    } catch (e) {
      print('❌ Error updating menu item: $e');
      rethrow;
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .doc(itemId)
          .delete();

      print('✅ Menu item deleted: $itemId');
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      rethrow;
    }
  }

  // Get all categories for a restaurant
  Stream<List<String>> getCategories(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menuItems')
        .snapshots()
        .map((snapshot) {
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc['category'] as String?;
        if (category != null) {
          categories.add(category);
        }
      }
      return categories.toList();
    });
  }
}