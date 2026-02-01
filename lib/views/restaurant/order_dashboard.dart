import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../view_models/order_view_model.dart';

class RestaurantOrderDashboard extends StatefulWidget {
  final String restaurantId;

  const RestaurantOrderDashboard({super.key, required this.restaurantId});

  @override
  State<RestaurantOrderDashboard> createState() => _RestaurantOrderDashboardState();
}

class _RestaurantOrderDashboardState extends State<RestaurantOrderDashboard> {
  String _selectedFilter = 'active'; // active, pending, preparing, completed, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);

    if (_selectedFilter == 'active') {
      orderViewModel.loadActiveRestaurantOrders(widget.restaurantId);
    } else {
      orderViewModel.loadRestaurantOrders(widget.restaurantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Kitchen Display',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E8B57), 
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics / Filter Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E8B57),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: _buildFilterTabs(),
          ),

          // Orders Grid/List
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'value': 'active', 'label': 'Active', 'icon': Icons.flash_on},
      {'value': 'pending', 'label': 'Pending', 'icon': Icons.notifications_active},
      {'value': 'preparing', 'label': 'Prep', 'icon': Icons.soup_kitchen},
      {'value': 'ready', 'label': 'Ready', 'icon': Icons.check_circle_outline},
       // {'value': 'all', 'label': 'All', 'icon': Icons.list}, // Simplified for KDS focus
    ];

    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        // Calculate counts
        int getCount(String status) {
          if (status == 'active') {
             return viewModel.orders
                .where((order) => order.status == 'pending' || order.status == 'preparing')
                .length;
          }
          return viewModel.orders.where((order) => order.status == status).length;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: tabs.map((tab) {
               final isSelected = _selectedFilter == tab['value'];
               final count = getCount(tab['value'] as String);
               
               return Padding(
                 padding: const EdgeInsets.only(right: 12),
                 child: Material(
                   color: Colors.transparent,
                   child: InkWell(
                     onTap: () {
                        setState(() {
                          _selectedFilter = tab['value'] as String;
                        });
                        _loadOrders();
                     },
                     borderRadius: BorderRadius.circular(16),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(
                         color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(
                           color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                           width: 1
                         )
                       ),
                       child: Row(
                         children: [
                           Icon(
                             tab['icon'] as IconData,
                             color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
                             size: 20,
                           ),
                           const SizedBox(width: 8),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 tab['label'] as String,
                                 style: GoogleFonts.inter(
                                   color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
                                   fontWeight: FontWeight.w600,
                                   fontSize: 12,
                                 ),
                               ),
                               Text(
                                 count.toString(),
                                 style: GoogleFonts.robotoMono(
                                   color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 18,
                                 ),
                               ),
                             ],
                           )
                         ],
                       ),
                     ),
                   ),
                 ),
               );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Error: ${viewModel.error}', style: GoogleFonts.inter(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadOrders,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<Order> filteredOrders = viewModel.orders;

        if (_selectedFilter == 'active') {
          filteredOrders = filteredOrders
              .where((order) => order.status == 'pending' || order.status == 'preparing')
              .toList();
        } else if (_selectedFilter != 'all') {
          filteredOrders = filteredOrders
              .where((order) => order.status == _selectedFilter)
              .toList();
        }

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Orders',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
                Text(
                  'Kitchen is clear!',
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredOrders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildKDSOrderCard(order, viewModel);
          },
        );
      },
    );
  }

  Widget _buildKDSOrderCard(Order order, OrderViewModel viewModel) {
    Color statusColor;
    Color statusBg;
    String statusText = order.status.toUpperCase();
    
    switch (order.status) {
      case 'pending':
        statusColor = const Color(0xFFE67E22);
        statusBg = const Color(0xFFFDEDEC); // Light Orange
        break;
      case 'preparing':
        statusColor = const Color(0xFF3498DB);
        statusBg = const Color(0xFFEBF5FB); // Light Blue
        break;
      case 'ready':
        statusColor = const Color(0xFF27AE60);
        statusBg = const Color(0xFFEAFAF1); // Light Green
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey[100]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.orderId.substring(0, 4)}', // Show shortened ID
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _formatTimeAgo(order.orderDate),
                          style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!)
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuItemName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                            if (item.specialRequest.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50], 
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange[100]!)
                                ),
                                child: Text(
                                  'NOTE: ${item.specialRequest}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                    color: const Color(0xFFE67E22),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                     padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER NOTE:',
                          style: GoogleFonts.robotoMono(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.specialInstructions!,
                          style: GoogleFonts.inter(color: Colors.red[900]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showOrderDetails(order, viewModel),
                    icon: const Icon(Icons.info_outline, color: Colors.grey),
                    label: Text('Details', style: GoogleFonts.inter(color: Colors.grey[700])),
                  ),
                ),
                if (order.status == 'pending')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(order, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.soup_kitchen, color: Colors.white),
                      label: Text('Start Preparing', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                else if (order.status == 'preparing')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(order, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Mark Ready', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                else if (order.status == 'ready')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(order, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B57),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: Text('Mark Completed', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Copied logic for time formatting and status
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showOrderDetails(Order order, OrderViewModel viewModel) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text('Full Order Deatils', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             // Reuse existing logic or simplified view
             Text('Total: ETB ${order.totalAmount}', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E8B57))),
             const SizedBox(height: 20),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
             )
          ],
        ),
      ),
     );
  }

  void _showStatusUpdateDialog(Order order, OrderViewModel viewModel) {
    String nextStatus;
    String statusLabel;
    
    if (order.status == 'pending') {
      nextStatus = 'preparing';
      statusLabel = 'Start Cooking?';
    } else if (order.status == 'preparing') {
      nextStatus = 'ready';
      statusLabel = 'Order Ready?';
    } else {
      nextStatus = 'completed';
      statusLabel = 'Complete Order?';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(statusLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Move Order #${order.orderId.substring(0, 4)} to ${nextStatus.toUpperCase()}?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await viewModel.updateOrderStatus(order.orderId, nextStatus);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
            child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}