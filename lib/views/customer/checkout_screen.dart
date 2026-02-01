import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/order_service.dart';
import 'my_orders_screen.dart';
import '../../services/location_service.dart';
import '../../services/restaurant_service.dart';
import '../../models/restaurant_model.dart';
import 'payment_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double subtotal;
  final double tax;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _orderType = 'Dine-in'; // Dine-in, Takeaway, Delivery
  String _paymentMethod = 'Cash'; // Cash, Digital
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  final LocationService _locationService = LocationService();
  final RestaurantService _restaurantService = RestaurantService();
  
  double _deliveryFee = 0.0;
  double? _customerLat;
  double? _customerLon;
  Restaurant? _restaurant;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final restaurant = await _restaurantService.getRestaurantById(widget.restaurantId);
    if (mounted) {
      setState(() => _restaurant = restaurant);
    }
  }

  Future<void> _calculateDeliveryFee() async {
    if (_orderType != 'Delivery' || _restaurant == null) {
      setState(() => _deliveryFee = 0.0);
      return;
    }

    final restaurant = _restaurant;
    if (restaurant == null || restaurant.latitude == null || restaurant.longitude == null) {
      _showError('Restaurant location not available for delivery calculation');
      return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final distance = _locationService.calculateDistance(
          restaurant.latitude!,
          restaurant.longitude!,
          position.latitude,
          position.longitude,
        );
        
        // Use user's formula: distance based
        // base 20 for first 2km, then 5 per km
        double fee = 20.0;
        if (distance > 2.0) {
          fee += (distance - 2.0) * 5.0;
        }

        setState(() {
          _deliveryFee = fee;
          _customerLat = position.latitude;
          _customerLon = position.longitude;
        });
      }
    } catch (e) {
      _showError('Error calculating delivery fee: $e');
    }
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    // Validation
    if (_orderType == 'Dine-in' && _tableNumberController.text.isEmpty) {
      _showError('Please enter your table number');
      return;
    }
    if (_orderType == 'Delivery' && _addressController.text.isEmpty) {
      _showError('Please enter your delivery address');
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.currentUser;

      if (user == null) {
        _showError('Please login to place an order');
        return;
      }

      String deliveryAddress = '';
      String? tableNumber;
      
      if (_orderType == 'Dine-in') {
        tableNumber = _tableNumberController.text;
      } else if (_orderType == 'Delivery') {
        deliveryAddress = _addressController.text;
      } else {
        // Takeaway
      }

      final order = await orderViewModel.createOrder(
         customerId: user.userId,
         customerName: user.name,
         restaurantId: widget.restaurantId,
         restaurantName: widget.restaurantName,
         orderType: _orderType.toLowerCase().replaceAll('-', '_'),
         tableNumber: tableNumber,
         deliveryAddress: _orderType == 'Delivery' ? deliveryAddress : null,
         deliveryLatitude: _customerLat,
         deliveryLongitude: _customerLon,
         deliveryFee: _orderType == 'Delivery' ? _deliveryFee : null,
         paymentMethod: _paymentMethod,
         specialInstructions: _noteController.text,
      );

      if (order != null && mounted) {
        if (_paymentMethod == 'Cash') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
               builder: (context) => OrderConfirmationScreen(order: order),
            ),
          );
        } else {
          // Navigate to Payment Screen for Digital Payments
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                totalAmount: widget.total + _deliveryFee,
                orderId: order.orderId,
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
              ),
            ),
          );
        }
      } else {
        _showError(orderViewModel.error ?? 'Failed to place order. Please try again.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
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
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Section
            _buildSectionHeader('Order Type', Icons.dining_outlined),
            const SizedBox(height: 12),
            _buildOrderTypeSelector(),
            const SizedBox(height: 24),

            // Details Section based on Order Type
            _buildDetailsSection(),
            const SizedBox(height: 24),

            // Special Instructions
            _buildSectionHeader('Special Instructions', Icons.edit_note),
            const SizedBox(height: 12),
            _buildNoteField(),
            const SizedBox(height: 24),

            // Order Summary
            _buildSectionHeader('Order Summary', Icons.receipt_long),
            const SizedBox(height: 12),
            _buildOrderSummaryCard(),
            const SizedBox(height: 24),
            
             // Payment Method
            _buildSectionHeader('Payment Method', Icons.payment),
            const SizedBox(height: 12),
            _buildPaymentSelector(),
            const SizedBox(height: 32),

            // Place Order Button
            _buildPlaceOrderButton(),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E8B57), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelector() {
    return Container(
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
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['Dine-in', 'Takeaway', 'Delivery'].map((type) {
          final isSelected = _orderType == type;
          return Expanded(
            child: GestureDetector(
            onTap: () {
                setState(() => _orderType = type);
                if (type == 'Delivery') {
                  _calculateDeliveryFee();
                } else {
                  setState(() => _deliveryFee = 0.0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E8B57) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsSection() {
    if (_orderType == 'Takeaway') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
           _orderType == 'Dine-in' ? 'Table Number' : 'Delivery Address',
           _orderType == 'Dine-in' ? Icons.table_restaurant : Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        Container(
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
          child: TextField(
            controller: _orderType == 'Dine-in' ? _tableNumberController : _addressController,
            decoration: InputDecoration(
              hintText: _orderType == 'Dine-in' ? 'Enter your table number (e.g. 5)' : 'Enter full delivery address',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            keyboardType: _orderType == 'Dine-in' ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.inter(color: const Color(0xFF2C3E50)),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Container(
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
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: 'Any special requests (e.g. less spicy, no onions)',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        maxLines: 3,
        style: GoogleFonts.inter(color: const Color(0xFF2C3E50)),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', widget.subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax (15%)', widget.tax),
          if (_orderType == 'Delivery') ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Delivery Fee', _deliveryFee),
          ],
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
                'ETB ${(widget.total + _deliveryFee).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: const Color(0xFF7F8C8D)),
        ),
        Text(
          'ETB ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentSelector() {
     return Container(
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
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['Cash', 'Telebirr', 'CBE Mobile'].map((method) {
          final isSelected = _paymentMethod == method;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E8B57) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                    fontSize: 12
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E8B57),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color(0xFF2E8B57).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Place Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline, size: 24),
                ],
              ),
      ),
    );
  }
}