import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maj3t/views/restaurant/order_dashboard.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../view_models/restaurant_view_model.dart';
import 'manage_menu_screen.dart';
import 'manage_reservations_screen.dart';
import 'manage_tables_screen.dart';
import 'manage_waitlist_screen.dart';
import '../../widgets/universal_image.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final String restaurantId;
  final Restaurant? initialRestaurant; // Keep as fallback/preview

  const RestaurantDetailsScreen({
    super.key, 
    required this.restaurantId,
    this.initialRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    // Consume latest data from ViewModel
    final restaurantViewModel = Provider.of<RestaurantViewModel>(context);
    final restaurant = restaurantViewModel.restaurants.firstWhere(
      (r) => r.restaurantId == restaurantId,
      orElse: () => initialRestaurant!,
    );

    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2E8B57),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2E8B57), // Solid Color
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                         child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                            ? UniversalImage(imageString: restaurant.imageUrl!)
                            : const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(Icons.store, size: 40, color: Color(0xFF2E8B57)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber[300], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.rating} Rating',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            restaurant.isActive ? Icons.check_circle : Icons.error, 
                            color: restaurant.isActive ? Colors.green[100] : Colors.red[100], 
                            size: 16
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.isActive ? 'Active' : 'Inactive',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildVerificationBadge(restaurant.verificationStatus),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusAlert(context, restaurant),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.location_on_outlined, restaurant.address),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.phone_outlined, restaurant.contact),
                        if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
                          const Divider(height: 24),
                           _buildInfoRow(Icons.info_outline, restaurant.description!),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Management Modules',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  if (restaurant.verificationStatus != 'verified')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'These features are disabled until your restaurant is verified.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFE74C3C),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grid Actions
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  context,
                  title: 'Orders',
                  icon: Icons.receipt_long,
                  color: const Color(0xFF3498DB),
                  isLocked: restaurant.verificationStatus != 'verified',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantOrderDashboard(
                        restaurantId: restaurant.restaurantId,
                      ),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  title: 'Menu',
                  icon: Icons.restaurant_menu,
                  color: const Color(0xFFE67E22),
                  isLocked: restaurant.verificationStatus != 'verified',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageMenuScreen(restaurant: restaurant),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  title: 'Reservations',
                  icon: Icons.calendar_today,
                  color: const Color(0xFF9B59B6),
                  isLocked: restaurant.verificationStatus != 'verified',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageReservationsScreen(
                        restaurantId: restaurant.restaurantId,
                        restaurantName: restaurant.name,
                      ),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  title: 'Tables',
                  icon: Icons.table_restaurant,
                  color: const Color(0xFF2E8B57), // Theme Color
                  isLocked: restaurant.verificationStatus != 'verified',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageTablesScreen(
                        restaurantId: restaurant.restaurantId,
                        restaurantName: restaurant.name,
                      ),
                    ),
                  ),
                ),
                 _buildActionCard(
                  context,
                  title: 'Waitlist',
                  icon: Icons.timer,
                  color: const Color(0xFFE74C3C),
                  isLocked: restaurant.verificationStatus != 'verified',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageWaitlistScreen(
                        restaurantId: restaurant.restaurantId,
                        restaurantName: restaurant.name,
                      ),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  title: 'Settings',
                  icon: Icons.settings,
                  color: const Color(0xFF7F8C8D),
                  isLocked: false, // Settings usually okay? Or maybe keep locked too.
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
              ]),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
    );
  }

  Widget _buildStatusAlert(BuildContext context, Restaurant restaurant) {
    if (restaurant.verificationStatus == 'verified') return const SizedBox.shrink();

    final isRejected = restaurant.verificationStatus == 'rejected';
    final color = isRejected ? const Color(0xFFE74C3C) : const Color(0xFFFF9800);
    final icon = isRejected ? Icons.error_outline : Icons.pending_outlined;
    final title = isRejected ? 'Verification Rejected' : 'Verification Pending';
    final message = isRejected 
        ? 'Reason: ${restaurant.rejectionReason ?? "Does not meet requirements."}'
        : 'Your documents are being reviewed by our administration team. This usually takes 24-48 hours.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: color.withOpacity(0.9),
                  ),
                ),
                if (isRejected) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Please contact support to update your information.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'verified':
        color = const Color(0xFFE8F5E9);
        icon = Icons.verified;
        label = 'Verified';
        break;
      case 'rejected':
        color = const Color(0xFFFFEBEE);
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      default:
        color = const Color(0xFFFFF3CD);
        icon = Icons.pending;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7F8C8D)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF2C3E50),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: isLocked 
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This module is locked until verification is complete.'),
                    backgroundColor: Color(0xFFE74C3C),
                  ),
                );
              }
            : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
               boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                if (isLocked)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}