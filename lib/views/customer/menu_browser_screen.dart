import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_item_model.dart';
import '../../services/menu_service.dart';
import '../../services/restaurant_service.dart';
import '../../models/restaurant_model.dart';
import '../../view_models/order_view_model.dart';
import 'cart_screen.dart';
import 'make_reservation_screen.dart';
import 'join_waitlist_screen.dart';
import '../../widgets/universal_image.dart';

class CustomerMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const CustomerMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  late MenuService _menuService;
  late RestaurantService _restaurantService;
  Restaurant? _restaurant;
  List<MenuItem> _menuItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _menuService = MenuService();
    _restaurantService = RestaurantService();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load Restaurant Details
      final restaurant = await _restaurantService.getRestaurantById(widget.restaurantId);
      if (mounted) {
        setState(() {
          _restaurant = restaurant;
        });
      }

      // Load categories
      final categoriesStream = _menuService.getCategories(widget.restaurantId);
      await for (final categories in categoriesStream) {
        if (mounted) {
          setState(() {
            _categories = ['All', ...categories];
          });
        }
        break;
      }

      // Load menu items
      final itemsStream = _menuService.getMenuItems(widget.restaurantId);
      await for (final items in itemsStream) {
        if (mounted) {
          setState(() {
            _menuItems = items;
            _isLoading = false;
          });
        }
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load menu: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderViewModel = Provider.of<OrderViewModel>(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E8B57),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.restaurantName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_restaurant?.verificationStatus == 'verified') ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 16, color: Colors.white),
                  ],
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  image: null, // Removed DecorationImage
                ),
                child: Stack(
                  children: [
                    // Base Background Image
                    Positioned.fill(
                      child: _restaurant?.imageUrl != null && _restaurant!.imageUrl!.isNotEmpty
                          ? UniversalImage(imageString: _restaurant!.imageUrl!)
                          : Container(), // Or default colo
                    ),
                    // Dark Overlay
                    Positioned.fill(
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                        ),
                      );
                    },
                  ),
                  if (orderViewModel.cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE74C3C),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          orderViewModel.cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'book') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MakeReservationScreen(
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                        ),
                      ),
                    );
                  } else if (value == 'waitlist') {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinWaitlistScreen(
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'book',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF2C3E50), size: 20),
                        const SizedBox(width: 12),
                        Text('Book a Table', style: GoogleFonts.inter()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'waitlist',
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFF2C3E50), size: 20),
                        const SizedBox(width: 12),
                        Text('Join Waitlist', style: GoogleFonts.inter()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search & Filter Section (Pinned)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverCategoryDelegate(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          ),

          // Menu Items Grid/List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
                    ),
                  )
                : _error != null
                    ? SliverFillRemaining(
                        child: _buildError(),
                      )
                    : _buildMenuList(orderViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Color(0xFFE74C3C)),
          const SizedBox(height: 16),
          Text(
            'Error Loading Menu',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: GoogleFonts.inter(color: const Color(0xFF7F8C8D)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

 Widget _buildMenuList(OrderViewModel orderViewModel) {
    // Filter items
    List<MenuItem> filteredItems = _menuItems
        .where((item) => item.isAvailable)
        .toList();

    if (_selectedCategory != 'All') {
      filteredItems = filteredItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No items found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredItems[index];
          return _buildMenuItemCard(item, orderViewModel);
        },
        childCount: filteredItems.length,
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item, OrderViewModel orderViewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Placeholder
          // Image / Placeholder
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  image: null, // Removed DecorationImage
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? UniversalImage(imageString: item.imageUrl!)
                            : const Center(
                                child: Icon(Icons.fastfood, size: 60, color: Color(0xFFBDC3C7)),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Text(
                      'ETB ${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E8B57),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E8B57),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Material(
                      color: const Color(0xFF2E8B57),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          // Call your addToCart method 
                          orderViewModel.addToCart(
                            menuItemId: item.itemId,
                            menuItemName: item.name,
                            price: item.price,
                            quantity: 1,
                            specialRequest: '',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              backgroundColor: const Color(0xFF2E8B57),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  _SliverCategoryDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 70,
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.inter(
                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                   color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2E8B57),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.categories != categories;
  }
}
