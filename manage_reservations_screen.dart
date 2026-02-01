import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_model.dart';
import '../../view_models/reservation_view_model.dart';
import '../../view_models/table_view_model.dart';

class ManageReservationsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ManageReservationsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ManageReservationsScreen> createState() => _ManageReservationsScreenState();
}

class _ManageReservationsScreenState extends State<ManageReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all'; // 'all', 'pending', 'confirmed', 'seated', 'cancelled'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Only rebuild when the swipe is settled
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final reservationViewModel = Provider.of<ReservationViewModel>(context, listen: false);
    final tableViewModel = Provider.of<TableViewModel>(context, listen: false);

    reservationViewModel.loadRestaurantReservations(widget.restaurantId);
    tableViewModel.loadTables(widget.restaurantId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    final reservationViewModel = Provider.of<ReservationViewModel>(context);
    final tableViewModel = Provider.of<TableViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Reservations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E8B57),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: RepaintBoundary(
          child: Column(
            children: [
              // Statistics Banner
              _buildStatsHeader(reservationViewModel),
    
              // Status Filters
              _buildStatusFilters(),
    
              // List
              Expanded(
                child: _buildReservationsList(reservationViewModel, tableViewModel),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildStatsHeader(ReservationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'Total Today',
                '${viewModel.statistics['totalToday'] ?? 0}',
                Colors.blue,
                Icons.calendar_today,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Confirmed',
                '${viewModel.statistics['confirmedToday'] ?? 0}',
                const Color(0xFF2E8B57),
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Seated',
                '${viewModel.statistics['seatedToday'] ?? 0}',
                Colors.orange,
                Icons.chair_alt,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // No Show Rate Bar
          Row(
            children: [
              Text(
                'No-show Rate',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (viewModel.statistics['noShowRate'] ?? 0) / 100,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (viewModel.statistics['noShowRate'] ?? 0) > 20 ? Colors.red : const Color(0xFF2E8B57),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(viewModel.statistics['noShowRate'] ?? 0).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final statuses = ['all', 'pending', 'confirmed', 'seated', 'cancelled'];
    
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          return FilterChip(
            label: Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = status);
              }
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF2E8B57),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
            elevation: isSelected ? 2 : 0,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildReservationsList(
      ReservationViewModel reservationViewModel,
      TableViewModel tableViewModel,
      ) {
    if (reservationViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (reservationViewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${reservationViewModel.error}'),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    List<Reservation> filteredReservations = [];
    final bool showToday = _tabController.index == 0;

    if (showToday) {
      filteredReservations = reservationViewModel.todayReservations;
    } else {
      filteredReservations = reservationViewModel.upcomingReservations;
    }

    // Apply status filter
    if (_selectedStatus != 'all') {
      filteredReservations = filteredReservations
          .where((reservation) => reservation.status == _selectedStatus)
          .toList();
    }

    if (filteredReservations.isEmpty) {
      return Center(
        key: ValueKey('empty_list_${_tabController.index}_$_selectedStatus'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Icon(
                showToday ? Icons.today : Icons.event_note,
                size: 64,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              showToday ? 'No Reservations Today' : 'No Upcoming Reservations',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('reservations_list_${_tabController.index}_$_selectedStatus'),
      itemCount: filteredReservations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        return _buildReservationCard(
          reservation, 
          reservationViewModel, 
          tableViewModel,
          key: ValueKey(reservation.reservationId),
        );
      },
    );
  }

  Widget _buildReservationCard(
    Reservation reservation,
    ReservationViewModel reservationViewModel,
    TableViewModel tableViewModel,
    {Key? key}
  ) {

    Color statusColor;
    switch (reservation.status) {
      case 'confirmed': statusColor = const Color(0xFF2E8B57); break;
      case 'pending': statusColor = Colors.orange; break;
      case 'seated': statusColor = Colors.blue; break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
                     Icon(Icons.face, size: 16, color: statusColor),
                     const SizedBox(width: 8),
                     Text(
                       reservation.customerName,
                       style: GoogleFonts.inter(
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         color: Colors.black87,
                       ),
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: statusColor,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     reservation.statusText.toUpperCase(),
                     style: GoogleFonts.inter(
                       fontSize: 10,
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                     ),
                   ),
                 ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.access_time, '${reservation.formattedTime} • ${reservation.formattedDate}'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.people_outline, '${reservation.partySize} Guests'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.phone_outlined, reservation.customerPhone),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Table Assignment Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!)
                      ),
                      child: Column(
                        children: [
                           Icon(Icons.table_bar, color: reservation.tableNumber != null ? const Color(0xFF2E8B57) : Colors.grey),
                           const SizedBox(height: 4),
                           Text(
                             reservation.tableNumber != null ? 'Table ${reservation.tableNumber}' : 'Unassigned',
                             style: GoogleFonts.inter(
                               fontSize: 12,
                               fontWeight: FontWeight.w600,
                               color: reservation.tableNumber != null ? const Color(0xFF2E8B57) : Colors.grey,
                             ),
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (reservation.specialRequests?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[100]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bookmark_outline, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reservation.specialRequests!, style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[900]))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Action Buttons
          if (reservation.status != 'cancelled' && reservation.status != 'completed')
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reservation.status == 'pending')
                      ElevatedButton.icon(
                        onPressed: () => _showConfirmDialog(reservation, reservationViewModel),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    if (reservation.status == 'confirmed' && reservation.tableId == null)
                      ElevatedButton.icon(
                        onPressed: () => _showAssignTableDialog(reservation, reservationViewModel, tableViewModel),
                        icon: const Icon(Icons.event_seat, size: 16),
                        label: const Text('Assign Table'),
                         style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    if (reservation.status == 'confirmed' && reservation.tableId != null)
                      ElevatedButton.icon(
                        onPressed: () => _showMarkSeatedDialog(reservation, reservationViewModel),
                        icon: const Icon(Icons.accessibility_new, size: 16),
                        label: const Text('Seated'),
                         style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                      
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(reservation, reservationViewModel),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }

  // --- Dialogs (Styled) ---

  Future<void> _showConfirmDialog(Reservation reservation, ReservationViewModel reservationViewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Reservation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Confirm this reservation for ${reservation.customerName}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await reservationViewModel.confirmReservation(reservationId: reservation.reservationId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation confirmed'), backgroundColor: Color(0xFF2E8B57)));
      }
    }
  }

  Future<void> _showAssignTableDialog(Reservation reservation, ReservationViewModel reservationViewModel, TableViewModel tableViewModel) async {
    final availableTables = tableViewModel.getAvailableTablesByCapacity(reservation.partySize);

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No suitable tables available!'), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Table', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableTables.length,
            itemBuilder: (context, index) {
              final table = availableTables[index];
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.table_restaurant, color: Color(0xFF2E8B57))),
                title: Text('Table ${table.tableNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('${table.capacity} seats • ${table.locationDescription ?? ''}', style: GoogleFonts.inter(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await reservationViewModel.confirmReservation(
                    reservationId: reservation.reservationId,
                    tableId: table.tableId,
                    tableNumber: table.tableNumber,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Table ${table.tableNumber} assigned'), backgroundColor: const Color(0xFF2E8B57)));
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _showMarkSeatedDialog(Reservation reservation, ReservationViewModel reservationViewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Seated', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Customer ${reservation.customerName} has arrived?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
            child: const Text('Yes, Seated', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reservation.tableId != null) {
      final success = await reservationViewModel.markAsSeated(
        reservationId: reservation.reservationId,
        tableId: reservation.tableId!,
        tableNumber: reservation.tableNumber!,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer marked as seated'), backgroundColor: Color(0xFF2E8B57)));
      }
    }
  }

  Future<void> _showCancelDialog(Reservation reservation, ReservationViewModel reservationViewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Reservation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Reservation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await reservationViewModel.cancelReservation(reservationId: reservation.reservationId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation cancelled'), backgroundColor: Colors.red));
      }
    }
  }
}