import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/reservation_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/table_grid_customer.dart';
import '../../models/table_model.dart';
import 'join_waitlist_screen.dart';

class MakeReservationScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MakeReservationScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MakeReservationScreen> createState() => _MakeReservationScreenState();
}

class _MakeReservationScreenState extends State<MakeReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _partySize = 2;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  String? _availabilityMessage;
  String? _selectedTableId;
  int? _selectedTableNumber;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = null;
    });

    final reservationViewModel = Provider.of<ReservationViewModel>(context, listen: false);

    try {
      final isAvailable = await reservationViewModel.checkAvailability(
        restaurantId: widget.restaurantId,
        date: _selectedDate,
        time: _selectedTime,
        partySize: _partySize,
      );

      setState(() {
        _isAvailable = isAvailable;
        _availabilityMessage = isAvailable
            ? 'Table available!'
            : 'No tables available for this time.';
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _availabilityMessage = 'Error checking availability';
      });
    } finally {
      setState(() {
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time')),
      );
      return;
    }

    final reservationViewModel = Provider.of<ReservationViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    final reservation = await reservationViewModel.createReservation(
      customerId: user.userId,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      reservationDate: _selectedDate,
      reservationTime: _selectedTime,
      partySize: _partySize,
      specialRequests: _specialRequestsController.text.isNotEmpty
          ? _specialRequestsController.text
          : null,
      tableId: _selectedTableId,
    );

    if (reservation != null && context.mounted) {
      // Show success dialog or snackbar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Reservation Confirmed!',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We look forward to hosting you.',
                style: GoogleFonts.inter(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2E8B57)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Book a Table',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.restaurantName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E8B57),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details below to reserve your spot.',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Date',
                      value: DateFormat('MMM d, yyyy').format(_selectedDate),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _isAvailable = true; // Reset status on change
                            _availabilityMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Time',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                            _isAvailable = true;
                            _availabilityMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Party Size
              Text(
                'Party Size',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _partySize,
                    isExpanded: true,
                    items: List.generate(20, (i) => i + 1).map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(
                          '$size People',
                          style: GoogleFonts.inter(),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _partySize = val;
                          _isAvailable = true;
                          _availabilityMessage = null;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Info
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _specialRequestsController,
                label: 'Special Requests (Optional)',
                icon: Icons.note_alt_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Table Selection
              TableGridCustomer(
                restaurantId: widget.restaurantId,
                partySize: _partySize,
                selectedTableId: _selectedTableId,
                onTableSelected: (table) {
                  setState(() {
                    _selectedTableId = table.tableId;
                    _selectedTableNumber = table.tableNumber;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Status Message
              if (_availabilityMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isAvailable ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAvailable ? Icons.check_circle : Icons.error_outline,
                        color: _isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _availabilityMessage!,
                          style: GoogleFonts.inter(
                            color: _isAvailable ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Buttons
              if (!_isCheckingAvailability && _availabilityMessage == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _checkAvailability,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF2E8B57)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Check Availability',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E8B57),
                      ),
                    ),
                  ),
                ),
              
              if (_isCheckingAvailability)
                const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57))),

              if (_isAvailable && _availabilityMessage != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (reservationViewModel.isLoading || _selectedTableId == null) ? null : _submitReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: reservationViewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _selectedTableId == null ? 'Select a Table to Continue' : 'Confirm Reservation (Table $_selectedTableNumber)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              if (!_isAvailable && _availabilityMessage != null && !_isCheckingAvailability)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JoinWaitlistScreen(
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_outlined, color: Colors.white),
                    label: const Text('Join Waitlist Instead'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF2E8B57)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2),
        ),
      ),
    );
  }
}