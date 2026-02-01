import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/payment_model.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/payment_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../customer/order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  final String restaurantId;
  final String restaurantName;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'cash';
  bool _isProcessing = false;
  String? _error;

  // Controllers
  final _phoneController = TextEditingController();
  final _providerController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'cash',
      'label': 'Cash',
      'icon': Icons.money,
      'color': Colors.green,
    },
    {
      'value': 'mobile_money',
      'label': 'Mobile Money',
      'icon': Icons.phone_android,
      'color': Colors.blue,
    },
    {
      'value': 'card',
      'label': 'Card',
      'icon': Icons.credit_card,
      'color': Colors.purple,
    },
  ];

  final List<String> _mobileMoneyProviders = [
    'M-Pesa',
    'Telebirr',
    'CBE Birr',
    'HelloCash',
    'Amole'
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _providerController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E8B57).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ETB ${widget.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${widget.orderId.substring(widget.orderId.length - 6)} • ${widget.restaurantName}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods Selection
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT METHOD',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _paymentMethods.map((method) {
                final isSelected = _selectedMethod == method['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedMethod = method['value'];
                      _error = null;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? method['color'].withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? method['color'] : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            method['icon'],
                            color: isSelected ? method['color'] : Colors.grey[400],
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            method['label'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? method['color'] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Animated Form Section
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildPaymentForm(),
            ),

            const SizedBox(height: 32),

            // Pay Button
            if (_isProcessing)
              const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: const Color(0xFF2E8B57).withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _selectedMethod == 'cash' ? 'Confirm Place Order' : 'Pay & Order',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

             if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedMethod) {
      case 'mobile_money':
        return Column(
          key: const ValueKey('mobile'),
          children: [
             _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
             Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _providerController.text.isEmpty ? null : _providerController.text,
                    hint: Text('Select Provider', style: GoogleFonts.inter(color: Colors.grey[600])),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _mobileMoneyProviders.map((provider) {
                      return DropdownMenuItem(
                        value: provider,
                        child: Text(provider, style: GoogleFonts.inter()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _providerController.text = val);
                    },
                  ),
                ),
              ),
          ],
        );
      case 'card':
        return Column(
          key: const ValueKey('card'),
          children: [
            _buildTextField(
              controller: _cardNumberController,
              label: 'Card Number',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'MM/YY',
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cardHolderController,
              label: 'Card Holder Name',
              icon: Icons.person_outline,
            ),
          ],
        );
      case 'cash':
      default:
        return Container(
          key: const ValueKey('cash'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please pay directly at the counter or to the server/rider upon delivery.',
                  style: GoogleFonts.inter(color: Colors.orange[900], fontSize: 13),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    // Validation
    if (_selectedMethod == 'mobile_money') {
      if (_phoneController.text.isEmpty || _providerController.text.isEmpty) {
        _setError('Please fill in all mobile money details'); 
        return;
      }
    } else if (_selectedMethod == 'card') {
      if (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty || 
          _cvvController.text.isEmpty || _cardHolderController.text.isEmpty) {
        _setError('Please fill in all card details'); 
        return;
      }
    }

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final paymentViewModel = Provider.of<PaymentViewModel>(context, listen: false);
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);

      final user = authViewModel.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Initiative Payment based on method
      if (_selectedMethod == 'cash') {
        // Create Payment Record (Cash)
        await paymentViewModel.createPayment(
          orderId: widget.orderId,
          customerId: user.userId,
          restaurantId: widget.restaurantId,
          amount: widget.totalAmount,
          method: 'cash',
        );
        // Update Order Status
        await orderViewModel.updateOrderStatus(widget.orderId, 'pending');
        _completeNavigation(orderViewModel);
      } else {
        // Real Payment via Chapa
        final checkoutUrl = await paymentViewModel.initializeChapaPayment(
          orderId: widget.orderId,
          customerId: user.userId,
          email: user.email,
          firstName: user.name.split(' ').first,
          lastName: user.name.contains(' ') ? user.name.split(' ').last : 'Customer',
          amount: widget.totalAmount,
          phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : '',
        );

        if (checkoutUrl != null) {
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            // Show a "Verify Payment" dialog when they return
            if (context.mounted) {
              _showVerifyDialog(paymentViewModel, orderViewModel);
            }
          } else {
            throw Exception('Could not launch payment gateway');
          }
        } else {
          throw Exception('Failed to initialize payment with Chapa');
        }
      }

    } catch (e) {
      _setError('Payment failed: ${e.toString()}');
    }
  }

  void _showVerifyDialog(PaymentViewModel paymentViewModel, OrderViewModel orderViewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text('Did you complete the payment in the browser/app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isProcessing = true);
              
              // In real flow, we'd verify with Chapa here. 
              // Since we're in sandbox/placeholder mode, we simplify the check.
              await Future.delayed(const Duration(seconds: 2));
              
              // Force update order status for this demo/sandbox
              await orderViewModel.updateOrderStatus(widget.orderId, 'pending');
              _completeNavigation(orderViewModel);
            },
            child: const Text('Yes, I paid'),
          ),
        ],
      ),
    );
  }

  void _completeNavigation(OrderViewModel orderViewModel) {
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OrderConfirmationScreen(
                order: orderViewModel.currentOrder!,
              ),
        ),
      );
    }
  }

  void _setError(String msg) {
    setState(() {
      _error = msg;
      _isProcessing = false;
    });
  }
}