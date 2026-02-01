import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_user_user_model.dart';
import '../../models/restaurant_model.dart';
import '../../view_models/restaurant_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'add_restaurant_screen.dart';
import 'restaurant_details_screen.dart';
import '../../widgets/universal_image.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
    });
  }

  void _loadRestaurants() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final restaurantViewModel = Provider.of<RestaurantViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      restaurantViewModel.loadRestaurantsByOwner(authViewModel.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final restaurantViewModel = Provider.of<RestaurantViewModel>(context);
    final user = authViewModel.currentUser;
    final restaurants = restaurantViewModel.restaurants;

    // Status Bar Settings
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF2E8B57), // Solid Emerald Green
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Manage your business',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadRestaurants,
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        restaurants.length.toString(),
                        Icons.store_mall_directory,
                        Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        restaurants.where((r) => r.isActive).length.toString(),
                        Icons.check_circle,
                         Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Revenue',
                        'ETB 0', // Mock data for now
                        Icons.attach_money,
                         Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildBody(restaurantViewModel, user),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRestaurantScreen(),
            ),
          ).then((_) => _loadRestaurants());
        },
        backgroundColor: const Color(0xFF2E8B57),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Restaurant', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RestaurantViewModel viewModel, AppUser? user) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${viewModel.error}', style: GoogleFonts.inter(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadRestaurants,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'No Restaurants Yet',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            Text(
              'Add your first restaurant to get started',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: viewModel.restaurants.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemBuilder: (context, index) {
        final restaurant = viewModel.restaurants[index];
        return _buildRestaurantCard(restaurant, viewModel);
      },
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, RestaurantViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            viewModel.selectRestaurant(restaurant);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsScreen(
                  restaurantId: restaurant.restaurantId,
                  initialRestaurant: restaurant,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: UniversalImage(imageString: restaurant.imageUrl!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.restaurant, color: Color(0xFF2E8B57), size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildVerificationBadge(restaurant.verificationStatus),
                                  const SizedBox(height: 4),
                                  _buildStatusChip(restaurant.isActive),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.address,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF7F8C8D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toString(),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                         _handleMenuAction('toggle', restaurant, viewModel);
                      },
                      icon: Icon(
                        restaurant.isActive ? Icons.store : Icons.domain_disabled, 
                        size: 18, 
                        color: restaurant.isActive ? Colors.orange : Colors.green[700]
                      ),
                      label: Text(
                        restaurant.isActive ? 'Deactivate' : 'Activate',
                        style: GoogleFonts.inter(
                          color: restaurant.isActive ? Colors.orange : Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF7F8C8D)),
                          onPressed: () => _handleMenuAction('edit', restaurant, viewModel),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE74C3C)),
                          onPressed: () => _handleMenuAction('delete', restaurant, viewModel),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Color(0xFFBDC3C7)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E8B57).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          color: isActive ? const Color(0xFF2E8B57) : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Restaurant restaurant, RestaurantViewModel viewModel) async {
    switch (action) {
      case 'view':
        viewModel.selectRestaurant(restaurant);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurantId: restaurant.restaurantId,
              initialRestaurant: restaurant,
            ),
          ),
        );
        break;

      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit feature coming soon!')),
        );
        break;

      case 'toggle':
        // Optimistic update
        final updatedRestaurant = restaurant.copyWith(isActive: !restaurant.isActive);
        await viewModel.updateRestaurant(updatedRestaurant);
        // Toast handled by logic or not needed if UI updates automatically
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Restaurant'),
            content: Text('Are you sure you want to delete "${restaurant.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await viewModel.deleteRestaurant(restaurant.restaurantId);
        }
        break;
    }
  }

  Widget _buildVerificationBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'verified':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E8B57);
        icon = Icons.verified;
        label = 'Verified';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE74C3C);
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFFFF9800);
        icon = Icons.pending;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}