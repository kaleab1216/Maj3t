import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/delivery_driver_model.dart';
import '../../services/restaurant_service.dart';
import '../../services/delivery_driver_service.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/universal_image.dart';
import 'dart:convert';

class AdminVerificationDashboard extends StatefulWidget {
  const AdminVerificationDashboard({super.key});

  @override
  State<AdminVerificationDashboard> createState() => _AdminVerificationDashboardState();
}

class _AdminVerificationDashboardState extends State<AdminVerificationDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RestaurantService _restaurantService = RestaurantService();
  final DeliveryDriverService _driverService = DeliveryDriverService();
  String _verificationType = 'restaurants'; // 'restaurants' or 'drivers'
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E8B57),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _verificationType == 'restaurants' 
                                ? 'Restaurant Verification' 
                                : 'Driver Verification',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Type Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTypeButton('restaurants', Icons.restaurant),
                          _buildTypeButton('drivers', Icons.delivery_dining),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: const Color(0xFF2E8B57),
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Verified'),
                          Tab(text: 'Rejected'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _verificationType == 'restaurants' 
                    ? _buildRestaurantList('pending') 
                    : _buildDriverList('pending'),
                _verificationType == 'restaurants' 
                    ? _buildRestaurantList('verified') 
                    : _buildDriverList('verified'),
                _verificationType == 'restaurants' 
                    ? _buildRestaurantList('rejected') 
                    : _buildDriverList('rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _verificationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _verificationType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                type.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantList(String status) {
    return StreamBuilder<List<Restaurant>>(
      stream: _restaurantService.getAllRestaurants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          );
        }

        final allRestaurants = snapshot.data ?? [];
        final filteredRestaurants = allRestaurants
            .where((r) => r.verificationStatus == status)
            .toList();

        if (filteredRestaurants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.pending_actions : 
                  status == 'verified' ? Icons.verified : Icons.cancel,
                  size: 64,
                  color: const Color(0xFFBDC3C7),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status} restaurants',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredRestaurants.length,
          itemBuilder: (context, index) {
            return _buildRestaurantCard(filteredRestaurants[index]);
          },
        );
      },
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Restaurant Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                        ? UniversalImage(imageString: restaurant.imageUrl!)
                        : const Icon(Icons.restaurant, color: Color(0xFF7F8C8D), size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
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
                      if (restaurant.latitude != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFF2196F3)),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.latitude!.toStringAsFixed(4)}, ${restaurant.longitude!.toStringAsFixed(4)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDate(restaurant.createdAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF95A5A6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (restaurant.verificationStatus == 'rejected' && restaurant.rejectionReason != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFE74C3C), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${restaurant.rejectionReason}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFE74C3C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const Divider(height: 1),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewDocuments(restaurant),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text(
                    'View Docs',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (restaurant.verificationStatus == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveRestaurant(restaurant),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _rejectRestaurant(restaurant),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocuments(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E8B57),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Verification Documents',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Info
                      _buildInfoSection('Restaurant Information', [
                        _buildInfoRow('Name', restaurant.name),
                        _buildInfoRow('Address', restaurant.address),
                        _buildInfoRow('Contact', restaurant.contact),
                        if (restaurant.description != null)
                          _buildInfoRow('Description', restaurant.description!),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Business License
                      Text(
                        'Business License',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentImage(restaurant.licenseImageBase64),
                      
                      const SizedBox(height: 24),
                      
                      // Owner ID
                      Text(
                        'Owner ID Document',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentImage(restaurant.idImageBase64),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E8B57),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7F8C8D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Color(0xFFBDC3C7)),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: UniversalImage(
          imageString: base64Image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _approveRestaurant(Restaurant restaurant) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final adminId = authViewModel.currentUser?.userId;

    if (adminId == null) return;

    try {
      final updatedRestaurant = restaurant.copyWith(
        verificationStatus: 'verified',
        isActive: true,
        verifiedAt: DateTime.now(),
        verifiedBy: adminId,
        updatedAt: DateTime.now(),
      );

      await _restaurantService.updateRestaurant(updatedRestaurant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant.name} has been approved!'),
            backgroundColor: const Color(0xFF2E8B57),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRestaurant(Restaurant restaurant) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Restaurant',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid license, unclear documents...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: Text('Reject', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final adminId = authViewModel.currentUser?.userId;

      if (adminId == null) return;

      try {
        final updatedRestaurant = restaurant.copyWith(
          verificationStatus: 'rejected',
          isActive: false,
          rejectionReason: reasonController.text,
          verifiedBy: adminId,
          updatedAt: DateTime.now(),
        );

        await _restaurantService.updateRestaurant(updatedRestaurant);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${restaurant.name} has been rejected'),
              backgroundColor: const Color(0xFFE74C3C),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDriverList(String status) {
    return StreamBuilder<List<DeliveryDriver>>(
      stream: _driverService.getAllDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)));
        }

        final allDrivers = snapshot.data ?? [];
        final filteredDrivers = allDrivers
            .where((d) => d.verificationStatus == status)
            .toList();

        if (filteredDrivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.pending_actions : 
                  status == 'verified' ? Icons.verified : Icons.cancel,
                  size: 64,
                  color: const Color(0xFFBDC3C7),
                ),
                const SizedBox(height: 16),
                Text('No ${status} drivers', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF7F8C8D))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDrivers.length,
          itemBuilder: (context, index) => _buildDriverCard(filteredDrivers[index]),
        );
      },
    );
  }

  Widget _buildDriverCard(DeliveryDriver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: const Color(0xFFF1F2F6), borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: driver.profileImageBase64 != null && driver.profileImageBase64!.isNotEmpty
                        ? UniversalImage(imageString: driver.profileImageBase64!)
                        : const Icon(Icons.person, color: Color(0xFF7F8C8D), size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                      const SizedBox(height: 4),
                      Text('${driver.vehicleType.toUpperCase()} • ${driver.vehicleNumber}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7F8C8D))),
                      const SizedBox(height: 4),
                      Text('Submitted: ${_formatDate(driver.createdAt)}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF95A5A6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (driver.verificationStatus == 'rejected' && driver.rejectionReason != null)
             _buildRejectionReason(driver.rejectionReason!),

          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewDriverDocuments(driver),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text('View Docs', style: GoogleFonts.inter(fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
                if (driver.verificationStatus == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveDriver(driver),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text('Approve', style: GoogleFonts.inter(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57), foregroundColor: Colors.white, elevation: 0),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _rejectDriver(driver),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text('Reject', style: GoogleFonts.inter(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, elevation: 0),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason(String reason) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE74C3C), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Reason: $reason', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE74C3C)))),
        ],
      ),
    );
  }

  void _viewDriverDocuments(DeliveryDriver driver) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader('Driver Verification Documents'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('Driver Information', [
                        _buildInfoRow('Name', driver.name),
                        _buildInfoRow('Email', driver.email),
                        _buildInfoRow('Phone', driver.phone),
                        _buildInfoRow('Vehicle', '${driver.vehicleType.toUpperCase()} (${driver.vehicleNumber})'),
                      ]),
                      const SizedBox(height: 24),
                      Text('Driver License', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                      const SizedBox(height: 12),
                      _buildDocumentImage(driver.licenseImageBase64),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF2E8B57), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Row(
        children: [
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Future<void> _approveDriver(DeliveryDriver driver) async {
    final adminId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.userId;
    try {
      await _driverService.updateVerificationStatus(driver.userId, 'verified', adminId: adminId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${driver.name} has been approved!'), backgroundColor: const Color(0xFF2E8B57)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectDriver(DeliveryDriver driver) async {
    final reasonController = TextEditingController();
    final result = await _showRejectionDialog(reasonController);

    if (result == true && reasonController.text.isNotEmpty) {
      final adminId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.userId;
      try {
        await _driverService.updateVerificationStatus(driver.userId, 'rejected', rejectionReason: reasonController.text, adminId: adminId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${driver.name} has been rejected'), backgroundColor: const Color(0xFFE74C3C)));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool?> _showRejectionDialog(TextEditingController reasonController) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(controller: reasonController, maxLines: 3, decoration: InputDecoration(hintText: 'e.g., Invalid documents...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)), child: const Text('Reject', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
