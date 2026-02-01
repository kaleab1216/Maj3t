import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'track_delivery_screen.dart';
import 'package:maj3t/l10n/app_localizations.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'completed'
  String? _lastLoadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrdersProactively();
  }

  void _loadOrdersProactively() {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;
    
    if (user != null && user.userId != _lastLoadedUserId) {
      _lastLoadedUserId = user.userId;
      Future.microtask(() {
        if (mounted) {
          Provider.of<OrderViewModel>(context, listen: false).loadCustomerOrders(user.userId);
        }
      });
    }
  }

  void _refreshOrders() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;
    if (user != null) {
      Provider.of<OrderViewModel>(context, listen: false).loadCustomerOrders(user.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myOrders,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E8B57)),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Consumer<OrderViewModel>(
              builder: (context, orderViewModel, child) {
                if (orderViewModel.isLoading && orderViewModel.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
                }

                if (orderViewModel.error != null && orderViewModel.orders.isEmpty) {
                  return _buildErrorState(orderViewModel.error!);
                }

                final filteredOrders = _getFilteredOrders(orderViewModel.orders);

                if (filteredOrders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildChoiceChip(AppLocalizations.of(context)!.all, 'all'),
          const SizedBox(width: 8),
          _buildChoiceChip(AppLocalizations.of(context)!.active, 'active'),
          const SizedBox(width: 8),
          _buildChoiceChip(AppLocalizations.of(context)!.history, 'completed'),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E8B57),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? const Color(0xFF2E8B57) : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedFilter == 'all') return orders;
    
    // Explicit list of terminal/history statuses
    final historyStatuses = ['completed', 'cancelled', 'delivered'];
    
    print('📦 MyOrdersScreen: Filtering ${orders.length} orders by "$_selectedFilter"');
    for (var i = 0; i < orders.length && i < 3; i++) {
       print('📦 Order ${orders[i].orderId} status: "${orders[i].status}"');
    }

    if (_selectedFilter == 'active') {
      return orders.where((o) => !historyStatuses.contains(o.status.toLowerCase())).toList();
    }
    
    // History tab
    final filtered = orders.where((o) => historyStatuses.contains(o.status.toLowerCase())).toList();
    print('📦 MyOrdersScreen: Found ${filtered.length} history orders');
    return filtered;
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.restaurantName.isEmpty ? AppLocalizations.of(context)!.restaurant : order.restaurantName,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(order.status, statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(order.orderDate),
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalAmount,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        'ETB ${order.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E8B57)),
                      ),
                    ],
                  ),
                  if (order.orderType == 'delivery' && !['completed', 'cancelled'].contains(order.status))
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDeliveryScreen(orderId: order.orderId))),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(AppLocalizations.of(context)!.track),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B57),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.orderSummary, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailRow(AppLocalizations.of(context)!.restaurant, order.restaurantName),
                  _buildDetailRow(AppLocalizations.of(context)!.orderId, '#${order.orderId}'),
                  _buildDetailRow(AppLocalizations.of(context)!.status, order.status.toUpperCase()),
                  _buildDetailRow(AppLocalizations.of(context)!.type, order.orderType),
                  const Divider(height: 32),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.menuItemName)),
                        Text('ETB ${item.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('ETB ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noOrdersFound, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
