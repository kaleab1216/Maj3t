import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/waitlist_model.dart';
import '../../view_models/waitlist_view_model.dart';
import '../../view_models/auth_view_model.dart';

class JoinWaitlistScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const JoinWaitlistScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<JoinWaitlistScreen> createState() => _JoinWaitlistScreenState();
}

class _JoinWaitlistScreenState extends State<JoinWaitlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  int _partySize = 2;
  int _estimatedWaitTime = 0;
  bool _isCheckingWaitTime = false;
  bool _alreadyOnWaitlist = false;
  WaitlistEntry? _currentWaitlistEntry;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _checkIfOnWaitlist();
    }

    _getEstimatedWaitTime();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _checkIfOnWaitlist() async {
    final waitlistViewModel = Provider.of<WaitlistViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user == null) return;

    try {
      final entry = await waitlistViewModel.getCustomerWaitlistPosition(
        restaurantId: widget.restaurantId,
        customerId: user.userId,
      );

      if (entry != null && context.mounted) {
        setState(() {
          _alreadyOnWaitlist = true;
          _currentWaitlistEntry = entry;
        });
      }
    } catch (e) {
      debugPrint('Error checking waitlist: $e');
    }
  }

  Future<void> _getEstimatedWaitTime() async {
    setState(() => _isCheckingWaitTime = true);
    final waitlistViewModel = Provider.of<WaitlistViewModel>(context, listen: false);

    try {
      final waitTime = await waitlistViewModel.getEstimatedWaitTime(
        restaurantId: widget.restaurantId,
        partySize: _partySize,
      );

      if (context.mounted) {
        setState(() {
          _estimatedWaitTime = waitTime;
          _isCheckingWaitTime = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _estimatedWaitTime = 30; // Default fallback
          _isCheckingWaitTime = false;
        });
      }
    }
  }

  Future<void> _joinWaitlist() async {
    if (!_formKey.currentState!.validate()) return;

    final waitlistViewModel = Provider.of<WaitlistViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to join waitlist')),
      );
      return;
    }

    final entry = await waitlistViewModel.joinWaitlist(
      customerId: user.userId,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      partySize: _partySize,
      specialRequests: _specialRequestsController.text.isNotEmpty
          ? _specialRequestsController.text
          : null,
    );

    if (entry != null && context.mounted) {
      _showSuccessDialog(entry.queuePosition ?? 1);
    }
  }

  void _showSuccessDialog(int position) {
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
              child: const Icon(Icons.timer_outlined, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Added to Waitlist!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            Text(
              'You are #${position} in line.',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E8B57),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will notify you when your table is ready.',
              style: GoogleFonts.inter(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Got it',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2E8B57)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waitlistViewModel = Provider.of<WaitlistViewModel>(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Join Waitlist',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
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
              // Restaurant Header
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                         ),
                       ],
                     ),
                     child: const Icon(Icons.store, color: Color(0xFF2E8B57), size: 30),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           widget.restaurantName,
                           style: GoogleFonts.poppins(
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                             color: const Color(0xFF2C3E50),
                           ),
                         ),
                         Text(
                           'Current Wait Status',
                           style: GoogleFonts.inter(color: Colors.grey),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),

              // Existing Waitlist Warning
              if (_alreadyOnWaitlist && _currentWaitlistEntry != null)
                _buildExistingWaitlistCard(),
              
              if (_alreadyOnWaitlist) const SizedBox(height: 24),

              // Wait Time Visualization
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B57),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E8B57).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Expected Wait Time',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isCheckingWaitTime)
                      const SizedBox(
                        height: 40, 
                        width: 40, 
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      Text(
                        '$_estimatedWaitTime min',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'For $_partySize people',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              Text(
                'YOUR DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person_outline,
                validator: (v) => v?.isNotEmpty == true ? null : 'Name is required',
              ),
              const SizedBox(height: 16),
               _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isNotEmpty == true && v!.length >= 10 ? null : 'Valid phone required',
              ),
              const SizedBox(height: 16),
              
              // Party Size Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _partySize,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: List.generate(20, (i) => i + 1).map((size) {
                            return DropdownMenuItem(
                              value: size,
                              child: Text(
                                '$size People',
                                style: GoogleFonts.inter(color: Colors.black87),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _partySize = val);
                              _getEstimatedWaitTime();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _specialRequestsController,
                label: 'Special Requests (Optional)',
                icon: Icons.note_alt_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              if (waitlistViewModel.isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _alreadyOnWaitlist ? null : _joinWaitlist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _alreadyOnWaitlist ? Colors.grey : const Color(0xFF2E8B57),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _alreadyOnWaitlist ? 'Already on List' : 'Join Waitlist',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingWaitlistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Already on Waitlist',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF856404),
                  ),
                ),
                Text(
                  'Position: #${_currentWaitlistEntry!.queuePosition} • Wait: ${_currentWaitlistEntry!.waitTimeText}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF856404),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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