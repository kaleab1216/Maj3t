import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maj3t/l10n/app_localizations.dart';
import '../../models/order_model.dart';
import 'split_bill_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Order order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this
    )..forward();
    
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8B57).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF2E8B57),
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                AppLocalizations.of(context)!.orderReceived,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your order #${widget.order.orderId.substring(widget.order.orderId.length - 6)} has been placed successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(height: 48),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(AppLocalizations.of(context)!.restaurant, widget.order.restaurantName),
                    const Divider(height: 24),
                    _buildSummaryRow(AppLocalizations.of(context)!.totalAmount, 'ETB ${widget.order.totalAmount.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SplitBillScreen(order: widget.order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group_outlined, color: Color(0xFF2E8B57)),
                  label: Text(
                    AppLocalizations.of(context)!.splitBill,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E8B57),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E8B57), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: const Color(0xFF2E8B57).withOpacity(0.4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continueShopping,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to My Orders (pop until home, then push My Orders or handle nav)
                   Navigator.popUntil(context, (route) => route.isFirst);
                   // Assuming Route to MyOrders is known or access via sidebar/home
                },
                child: Text(
                  AppLocalizations.of(context)!.viewMyOrders,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF2C3E50),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}