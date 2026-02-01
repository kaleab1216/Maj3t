import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_picker_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/image_upload_service.dart';
import '../../view_models/restaurant_view_model.dart';
import '../../view_models/auth_view_model.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  double? _latitude;
  double? _longitude;

  File? _restaurantImage;
  File? _licenseImage;
  File? _idImage;
  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _isUploadingImage = false;

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final restaurantViewModel = Provider.of<RestaurantViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Restaurant',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Restaurant Image Upload
                _buildImageUploadSection(),
                const SizedBox(height: 24),

                // Restaurant Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Restaurant Name',
                  icon: Icons.restaurant_outlined,
                  hint: 'Enter restaurant name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter restaurant name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  hint: 'Enter complete address',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Map Location Picker
                _buildLocationPickerSection(),
                const SizedBox(height: 16),

                // Contact Number
                _buildTextField(
                  controller: _contactController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  hint: '+251 XXX XXX XXX',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    if (value.length < 10) {
                      return 'Please enter valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                _buildDescriptionField(),
                const SizedBox(height: 24),

                // Verification Documents
                _buildVerificationDocumentsSection(),
                const SizedBox(height: 24),

                // Owner Info Card
                _buildOwnerInfoCard(authViewModel),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(restaurantViewModel, authViewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Text(
          'Restaurant Image',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _restaurantImage == null
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isUploadingImage
                ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
                : _restaurantImage == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to upload image',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Recommended: 1080x1080px',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _restaurantImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_restaurantImage != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _showImagePickerOptions,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(
                  'Change Image',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _restaurantImage = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: Text(
                  'Remove',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map Location',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLocationOnMap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _latitude != null ? const Color(0xFF2E8B57) : Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _latitude != null ? Icons.location_on : Icons.map_outlined,
                  color: _latitude != null ? const Color(0xFF2E8B57) : AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _latitude != null
                        ? 'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                        : 'Select restaurant location on map',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _latitude != null ? const Color(0xFF2E8B57) : AppTheme.textSecondary,
                      fontWeight: _latitude != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (_latitude == null)
                  const Icon(Icons.chevron_right, color: AppTheme.textLight)
                else
                  const Icon(Icons.check_circle, color: Color(0xFF2E8B57), size: 20),
              ],
            ),
          ),
        ),
        if (_latitude == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '* Required for customers to find you on the map',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.errorColor),
            ),
          ),
      ],
    );
  }

  Future<void> _pickLocationOnMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _latitude != null ? LatLng(_latitude!, _longitude!) : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tell customers about your restaurant...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfoCard(AuthViewModel authViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant Owner',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  authViewModel.currentUser?.name ?? 'Not available',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  authViewModel.currentUser?.email ?? 'Not available',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(RestaurantViewModel restaurantViewModel, AuthViewModel authViewModel) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: restaurantViewModel.isLoading || _isUploadingImage
            ? null
            : () => _submitForm(restaurantViewModel, authViewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: restaurantViewModel.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_business, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Add Restaurant',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _imageUploadService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _restaurantImage = image;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final image = await _imageUploadService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        _restaurantImage = image;
      });
    }
  }

  Future<void> _submitForm(RestaurantViewModel restaurantViewModel, AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate verification documents
    if (_licenseImage == null || _idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload both business license and ID document'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select restaurant location on the map'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = authViewModel.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to add a restaurant'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      String? imageUrl;
      String? licenseBase64;
      String? idBase64;

      // Upload restaurant image if selected
      if (_restaurantImage != null) {
        imageUrl = await _imageUploadService.uploadRestaurantImage(
          _restaurantImage!,
          'temp_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Convert license to Base64
      licenseBase64 = await _imageUploadService.uploadRestaurantImage(
        _licenseImage!,
        'temp_license',
      );

      // Convert ID to Base64
      idBase64 = await _imageUploadService.uploadRestaurantImage(
        _idImage!,
        'temp_id',
      );

      setState(() => _isUploadingImage = false);

      final success = await restaurantViewModel.createRestaurant(
        ownerId: user.userId,
        name: _nameController.text,
        address: _addressController.text,
        contact: _contactController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        imageUrl: imageUrl,
        licenseImageBase64: licenseBase64,
        idImageBase64: idBase64,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Restaurant submitted for verification! You will be notified once approved.'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildVerificationDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Documents',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upload your business license and ID for verification. Your restaurant will be reviewed by admin before activation.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF856404),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Business License Upload
        _buildDocumentUpload(
          title: 'Business License *',
          image: _licenseImage,
          onTap: () => _showDocumentPickerOptions('license'),
          onRemove: () => setState(() => _licenseImage = null),
        ),
        const SizedBox(height: 16),
        
        // Owner ID Upload
        _buildDocumentUpload(
          title: 'Owner ID Document *',
          image: _idImage,
          onTap: () => _showDocumentPickerOptions('id'),
          onRemove: () => setState(() => _idImage = null),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image == null
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 40,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload document',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    'Change',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text(
                    'Remove',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showDocumentPickerOptions(String documentType) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocumentFromGallery(documentType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocumentFromCamera(documentType);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDocumentFromGallery(String documentType) async {
    final image = await _imageUploadService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        if (documentType == 'license') {
          _licenseImage = image;
        } else {
          _idImage = image;
        }
      });
    }
  }

  Future<void> _pickDocumentFromCamera(String documentType) async {
    final image = await _imageUploadService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        if (documentType == 'license') {
          _licenseImage = image;
        } else {
          _idImage = image;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}