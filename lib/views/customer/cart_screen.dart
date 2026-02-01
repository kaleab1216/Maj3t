import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/order_item_model.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const CartScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final orderViewModel = Provider.of<OrderViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Cart',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Restaurant Info
          _buildRestaurantInfo(),

          // Cart Items
          Expanded(
            child: orderViewModel.cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartItems(orderViewModel),
          ),

          // Order Summary
          if (orderViewModel.cartItems.isNotEmpty)
            _buildOrderSummary(orderViewModel, authViewModel),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF2E8B57),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurantName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ordering from this restaurant',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: Color(0xFF2E8B57),
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add delicious items from the menu to get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF7F8C8D),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Browse Menu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(OrderViewModel orderViewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orderViewModel.cartItems.length,
      itemBuilder: (context, index) {
        final item = orderViewModel.cartItems[index];
        return _buildCartItemCard(item, index, orderViewModel);
      },
    );
  }

  Widget _buildCartItemCard(OrderItem item, int index, OrderViewModel orderViewModel) {
    return Dismissible(
      key: Key(item.menuItemId + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
         orderViewModel.removeFromCart(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Quantity 
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B57).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}x',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E8B57),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuItemName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ETB ${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                    if (item.specialRequest?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, size: 16, color: Color(0xFFFF6B35)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.specialRequest!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFFF6B35),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Controls
              Row(
                children: [
                   IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 24),
                      color: const Color(0xFF95A5A6),
                      onPressed: () {
                        if (item.quantity > 1) {
                          orderViewModel.updateCartItemQuantity(index, item.quantity - 1);
                        } else {
                          orderViewModel.removeFromCart(index);
                        }
                      },
                    ),
                    
                    Text(
                      'ETB ${item.subtotal.toStringAsFixed(2)}',
                       style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C3E50),
                        ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      color: const Color(0xFF2E8B57),
                      onPressed: () {
                        orderViewModel.updateCartItemQuantity(index, item.quantity + 1);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderViewModel orderViewModel, AuthViewModel authViewModel) {
    final subtotal = orderViewModel.cartTotal;
    final tax = subtotal * 0.15; // 15% tax
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.inter(color: const Color(0xFF7F8C8D)),
              ),
              Text(
                'ETB ${subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (15%)',
                style: GoogleFonts.inter(color: const Color(0xFF7F8C8D)),
              ),
              Text(
                'ETB ${tax.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(
                'ETB ${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (authViewModel.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to checkout'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      restaurantId: widget.restaurantId,
                      restaurantName: widget.restaurantName,
                      subtotal: subtotal,
                      tax: tax,
                      total: total,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          
          // Clear Button
          const SizedBox(height: 12),
          TextButton(
             onPressed: () {
               // Show confirmation dialog logic (omitted for brevity)
               orderViewModel.clearCart();
               Navigator.pop(context);
             },
             child: Text(
               'Clear Cart', 
               style: GoogleFonts.inter(
                 color: const Color(0xFFE74C3C),
                 fontWeight: FontWeight.w600
               ),
             ),
          ),
        ],
      ),
    );
  }
}