import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/waitlist_model.dart';
import '../../view_models/waitlist_view_model.dart';
import '../../view_models/table_view_model.dart';

class ManageWaitlistScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ManageWaitlistScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ManageWaitlistScreen> createState() => _ManageWaitlistScreenState();
}

class _ManageWaitlistScreenState extends State<ManageWaitlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final waitlistViewModel = Provider.of<WaitlistViewModel>(context, listen: false);
    final tableViewModel = Provider.of<TableViewModel>(context, listen: false);

    waitlistViewModel.loadWaitlist(widget.restaurantId);
    tableViewModel.loadTables(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    final waitlistViewModel = Provider.of<WaitlistViewModel>(context);
    final tableViewModel = Provider.of<TableViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white background
      appBar: AppBar(
        title: Text(
          'Waitlist Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E8B57), // Emerald Green
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Banner
          _buildStatsHeader(waitlistViewModel),

          // Active Waitlist
          Expanded(
            child: _buildWaitlistList(waitlistViewModel, tableViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(WaitlistViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B57),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B57).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Waiting Now',
                '${viewModel.statistics['waitingNow'] ?? 0}',
                Icons.people,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                'Avg Wait',
                '${viewModel.statistics['averageWaitTime'] ?? 0}m',
                Icons.timer,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                'Seated',
                '${viewModel.statistics['seatedToday'] ?? 0}',
                Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildWaitlistList(
      WaitlistViewModel waitlistViewModel,
      TableViewModel tableViewModel,
      ) {
    if (waitlistViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (waitlistViewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${waitlistViewModel.error}', style: GoogleFonts.inter(color: Colors.grey[800])),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (waitlistViewModel.activeWaitlist.isEmpty) {
      return Center(
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
              child: const Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Waitlist is Empty',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'No customers currently waiting',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: waitlistViewModel.activeWaitlist.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = waitlistViewModel.activeWaitlist[index];
        return _buildWaitlistCard(entry, waitlistViewModel, tableViewModel);
      },
    );
  }

  Widget _buildWaitlistCard(
      WaitlistEntry entry,
      WaitlistViewModel waitlistViewModel,
      TableViewModel tableViewModel,
      ) {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Queue Position Indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E8B57), Color(0xFF3CB371)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8B57).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.queuePosition}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.partySize} Guests',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            entry.waitTimeText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge (if any besides 'waiting')
                if (entry.status == 'notified')
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.blue.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       'Notified',
                       style: GoogleFonts.inter(
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                         color: Colors.blue,
                       ),
                     ),
                   ),
              ],
            ),
          ),

          // Special Requests Section
          if (entry.specialRequests?.isNotEmpty ?? false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[100]!),
              ),
              child: Text(
                'Note: ${entry.specialRequests!}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[900]),
              ),
            ),
            
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSeatCustomerDialog(entry, waitlistViewModel, tableViewModel),
                    icon: const Icon(Icons.table_restaurant, size: 18),
                    label: const Text('Seat Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(entry, waitlistViewModel),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSeatCustomerDialog(
      WaitlistEntry entry,
      WaitlistViewModel waitlistViewModel,
      TableViewModel tableViewModel,
      ) async {
    final availableTables = tableViewModel.getAvailableTablesByCapacity(entry.partySize);

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available tables for this party size'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seat Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                  final success = await waitlistViewModel.seatCustomer(
                    waitlistId: entry.waitlistId,
                    tableId: table.tableId,
                    tableNumber: table.tableNumber,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${entry.customerName} seated at Table ${table.tableNumber}'),
                        backgroundColor: const Color(0xFF2E8B57),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(
      WaitlistEntry entry,
      WaitlistViewModel waitlistViewModel,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Entry', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Remove ${entry.customerName} from the waitlist?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await waitlistViewModel.cancelWaitlistEntry(
        waitlistId: entry.waitlistId,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waitlist entry removed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}