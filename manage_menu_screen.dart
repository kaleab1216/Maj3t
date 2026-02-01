import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../view_models/menu_view_model.dart';
import 'add_menu_item_screen.dart';
import '../../widgets/universal_image.dart';

class ManageMenuScreen extends StatefulWidget {
  final Restaurant restaurant;

  const ManageMenuScreen({super.key, required this.restaurant});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  late MenuViewModel _menuViewModel;
  String _selectedCategory = 'All';
  bool _showAvailableOnly = false; // Changed default to false to see all items

  @override
  void initState() {
    super.initState();
    final menuService = Provider.of<MenuService>(context, listen: false);
    _menuViewModel = MenuViewModel(menuService);
    
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu();
    });
  }

  void _loadMenu() {
    _menuViewModel.loadMenuItems(widget.restaurant.restaurantId);
    _menuViewModel.loadCategories(widget.restaurant.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Manage Menu',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E8B57), // Solid Emerald Green
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMenu,
          ),
          TextButton(
            onPressed: _generateQRCode,
            child: Text(
              'FINISH',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
             padding: const EdgeInsets.symmetric(vertical: 16),
             decoration: const BoxDecoration(
               color: Color(0xFF2E8B57),
               borderRadius: BorderRadius.only(
                 bottomLeft: Radius.circular(24),
                 bottomRight: Radius.circular(24),
               ),
             ),
             child: Column(
               children: [
                 // Categories
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: Row(
                     children: [
                       _buildFilterChip('All', _selectedCategory == 'All'),
                       ..._menuViewModel.categories.map((cat) => 
                         _buildFilterChip(cat, _selectedCategory == cat)
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 12),
                 // Availability Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Show Available Only',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: _showAvailableOnly,
                            onChanged: (val) => setState(() => _showAvailableOnly = val),
                            activeTrackColor: Colors.white,
                            activeColor: const Color(0xFF2E8B57),
                          ),
                        ),
                      ],
                    ),
                  ),
               ],
             ),
          ),

          // List
          Expanded(
            child: _buildMenuList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMenuItemScreen(
                restaurantId: widget.restaurant.restaurantId,
                restaurantName: widget.restaurant.name,
              ),
            ),
          ).then((_) => _loadMenu());
        },
        backgroundColor: const Color(0xFF2E8B57),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.1),
        selectedColor: Colors.white,
        checkmarkColor: const Color(0xFF2E8B57),
        labelStyle: GoogleFonts.inter(
          color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildMenuList() {
    if (_menuViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (_menuViewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: ${_menuViewModel.error}', style: GoogleFonts.inter(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadMenu,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    List<MenuItem> filteredItems = _menuViewModel.menuItems;

    if (_selectedCategory != 'All') {
      filteredItems = filteredItems.where((item) => item.category == _selectedCategory).toList();
    }

    if (_showAvailableOnly) {
      filteredItems = filteredItems.where((item) => item.isAvailable).toList();
    }

    if (filteredItems.isEmpty) {
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
              child: const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'No items found',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            if (_selectedCategory != 'All')
              Text(
                'for category "$_selectedCategory"',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onLongPress: () => _handleMenuAction('edit', item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Placeholder with Status
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                           borderRadius: BorderRadius.circular(12),
                           child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? UniversalImage(imageString: item.imageUrl!)
                              : const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Icon(Icons.fastfood, color: Colors.grey),
                                ),
                        ),
                      ),
                      if (!item.isAvailable)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.block, color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF2C3E50),
                                  decoration: !item.isAvailable ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Switch(
                              value: item.isAvailable, 
                              onChanged: (val) => _handleMenuAction('toggle', item),
                              activeColor: const Color(0xFF2E8B57),
                            ),
                          ],
                        ),
                        Text(
                          item.description,
                          style: GoogleFonts.inter(
                            fontSize: 12, 
                            color: Colors.grey[600]
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E8B57).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E8B57),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'ETB ${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) => _handleMenuAction(value, item),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                         value: 'edit',
                         child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                      ),
                      const PopupMenuItem(
                         value: 'delete',
                         child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, MenuItem item) async {
    switch (action) {
      case 'toggle':
        // Optimistic UI update could be tricky with current VM structure
        // But for now we just call the VM
        final success = await _menuViewModel.toggleMenuItemAvailability(
          restaurantId: widget.restaurant.restaurantId,
          menuItem: item,
        );
        if (success && mounted) {
           // We don't really rely on the snackbar as much if the switch flips
        }
        break;

      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit feature coming soon!')),
        );
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Menu Item'),
            content: Text('Are you sure you want to delete "${item.name}"?'),
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
          await _menuViewModel.deleteMenuItem(
            widget.restaurant.restaurantId,
            item.itemId,
          );
        }
        break;
    }
  }

  Future<void> _generateQRCode() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish & Generate QR Code', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'You have finished setting up your menu for "${widget.restaurant.name}". Would you like to generate your restaurant\'s scan-to-order QR code now?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
            child: const Text('Yes, Generate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // URL for QR code generation using a free service
      // We send the restaurant ID and name as parameters for the owner to identify
      final String restaurantId = widget.restaurant.restaurantId;
      final String restaurantName = widget.restaurant.name;
      
      // Data format expected by scanner: "restaurant:restaurantId:restaurantName"
      final String qrData = 'restaurant:$restaurantId:${Uri.encodeComponent(restaurantName)}';
      
      // Using QRServer API which is free and reliable
      // It generates an image that the browser will display, which the owner can save/print.
      final String qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${Uri.encodeComponent(qrData)}&caption=${Uri.encodeComponent(restaurantName)}';
      
      final Uri uri = Uri.parse(qrUrl);
      
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Opening QR Code Generator in browser...'),
                 backgroundColor: Color(0xFF2E8B57),
               ),
             );
          }
        } else {
          throw 'Could not launch QR generator';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}