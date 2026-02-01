import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/table_model.dart';
import '../../view_models/table_view_model.dart';

class ManageTablesScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ManageTablesScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends State<ManageTablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTables();
    });
  }

  void _loadTables() {
    final tableViewModel = Provider.of<TableViewModel>(context, listen: false);
    tableViewModel.loadTables(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    // Green header -> Light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    final tableViewModel = Provider.of<TableViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Floor Plan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E8B57), // Emerald Green
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddTableDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics
          _buildStatistics(tableViewModel),

          // Tables Grid
          Expanded(
            child: _buildTablesGrid(tableViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(TableViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
           Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Occupancy',
                       style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                     ),
                     const SizedBox(height: 4),
                     ClipRRect(
                       borderRadius: BorderRadius.circular(4),
                       child: LinearProgressIndicator(
                         value: (viewModel.statistics['occupancyRate'] ?? 0) / 100,
                         backgroundColor: Colors.grey[100],
                         valueColor: AlwaysStoppedAnimation<Color>(
                           (viewModel.statistics['occupancyRate'] ?? 0) > 80
                               ? Colors.red
                               : (viewModel.statistics['occupancyRate'] ?? 0) > 50
                               ? Colors.orange
                               : const Color(0xFF2E8B57),
                         ),
                         minHeight: 8,
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(width: 16),
               Text(
                 '${(viewModel.statistics['occupancyRate'] ?? 0).toStringAsFixed(0)}%',
                 style: GoogleFonts.poppins(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                   color: Colors.black87,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildStatusChip('Available', viewModel.statistics['availableTables'] ?? 0, Colors.green),
               _buildStatusChip('Reserved', viewModel.statistics['reservedTables'] ?? 0, Colors.orange),
               _buildStatusChip('Occupied', viewModel.statistics['occupiedTables'] ?? 0, Colors.red),
             ],
           ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$count $label', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildTablesGrid(TableViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${viewModel.error}', style: GoogleFonts.inter()),
            TextButton(
              onPressed: _loadTables,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.tables.isEmpty) {
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
              child: const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'No Tables Yet',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Add your first table to get started',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddTableDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Table'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 tables per row
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: viewModel.tables.length,
      itemBuilder: (context, index) {
        final table = viewModel.tables[index];
        return _buildTableCard(table, viewModel);
      },
    );
  }

  Widget _buildTableCard(RestaurantTable table, TableViewModel viewModel) {
    Color statusColor;
    switch (table.status) {
      case 'available': statusColor = const Color(0xFF2E8B57); break;
      case 'reserved': statusColor = Colors.orange; break;
      case 'occupied': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return InkWell(
      onTap: () => _showTableOptions(table, viewModel),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${table.tableNumber}',
              style: GoogleFonts.poppins(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${table.capacity}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Icon(_getTableIcon(table.tableType), size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  IconData _getTableIcon(String tableType) {
    switch (tableType) {
      case 'outdoor': return Icons.deck;
      case 'private': return Icons.meeting_room;
      case 'bar': return Icons.local_bar;
      default: return Icons.table_restaurant;
    }
  }

  void _showTableOptions(RestaurantTable table, TableViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table ${table.tableNumber}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${table.capacity} Seats • ${table.tableType.toUpperCase()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                   decoration: BoxDecoration(
                     color: table.statusColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Text(table.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: table.statusColor)),
                 ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Status Updates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatusAction('Available', Colors.green, table.status == 'available', () {
                   Navigator.pop(context);
                   viewModel.updateTableStatus(restaurantId: widget.restaurantId, tableId: table.tableId, status: 'available');
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusAction('Reserved', Colors.orange, table.status == 'reserved', () {
                   Navigator.pop(context);
                   viewModel.updateTableStatus(restaurantId: widget.restaurantId, tableId: table.tableId, status: 'reserved');
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusAction('Occupied', Colors.red, table.status == 'occupied', () {
                   Navigator.pop(context);
                   viewModel.updateTableStatus(restaurantId: widget.restaurantId, tableId: table.tableId, status: 'occupied');
                })),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                 onPressed: () {
                    Navigator.pop(context);
                   _showEditTableDialog(table, viewModel);
                 },
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   side: BorderSide(color: Colors.grey[300]!)
                 ),
                 child: Text('Edit Table Details', style: GoogleFonts.inter(color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 8),
            if (!table.isOccupied)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                 onPressed: () async {
                    Navigator.pop(context);
                    await viewModel.deleteTable(restaurantId: widget.restaurantId, tableId: table.tableId);
                 },
                 child: Text('Delete Table', style: GoogleFonts.inter(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusAction(String label, Color color, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, RestaurantTable table, TableViewModel viewModel) async {
    // Replaced by _showTableOptions but keeping logic just in case
  }

  void _showAddTableDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: widget.restaurantId,
        onAdded: _loadTables,
      ),
    );
  }

  void _showEditTableDialog(RestaurantTable table, TableViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: widget.restaurantId,
        table: table,
        onAdded: _loadTables,
      ),
    );
  }
}

class _AddTableDialog extends StatefulWidget {
  final String restaurantId;
  final RestaurantTable? table;
  final VoidCallback onAdded;

  const _AddTableDialog({
    required this.restaurantId,
    this.table,
    required this.onAdded,
  });

  @override
  State<_AddTableDialog> createState() => __AddTableDialogState();
}

class __AddTableDialogState extends State<_AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();

  String _tableType = 'indoor';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _tableNumberController.text = widget.table!.tableNumber.toString();
      _capacityController.text = widget.table!.capacity.toString();
      _locationController.text = widget.table!.locationDescription ?? '';
      _tableType = widget.table!.tableType;
      _isActive = widget.table!.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableViewModel = Provider.of<TableViewModel>(context, listen: false);

    return AlertDialog(
      title: Text(
        widget.table != null ? 'Edit Table' : 'New Table',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Table Number
              TextFormField(
                controller: _tableNumberController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Table Number',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Capacity',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: const Icon(Icons.people_outline, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Table Type
              DropdownButtonFormField<String>(
                value: _tableType,
                style: GoogleFonts.inter(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'indoor', child: Text('Indoor Dining')),
                  DropdownMenuItem(value: 'outdoor', child: Text('Outdoor Patio')),
                  DropdownMenuItem(value: 'private', child: Text('Private Room')),
                  DropdownMenuItem(value: 'bar', child: Text('Bar Seating')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _tableType = value);
                },
              ),
              const SizedBox(height: 16),

              // Location Description
              TextFormField(
                controller: _locationController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Location Note (Optional)',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'e.g., Near window',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final success = widget.table != null
                ? false // Edit functionality would handle update here
                : await tableViewModel.addTable(
              restaurantId: widget.restaurantId,
              tableNumber: int.parse(_tableNumberController.text),
              capacity: int.parse(_capacityController.text),
              tableType: _tableType,
              locationDescription: _locationController.text.isNotEmpty ? _locationController.text : null,
            );

            if (success && context.mounted) {
              Navigator.pop(context);
              widget.onAdded();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B57),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(widget.table != null ? 'Update Table' : 'Add Table', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}