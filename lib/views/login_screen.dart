import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'driver/driver_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _obscurePassword = true;
  String _selectedRole = 'customer';

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Name field for registration
                if (!_isLogin) _buildNameField(),
                if (!_isLogin) const SizedBox(height: 16),

                // Role selection for registration
                if (!_isLogin) _buildRoleSelector(),
                if (!_isLogin) const SizedBox(height: 16),

                // Email field
                _buildEmailField(),
                const SizedBox(height: 16),

                // Password field
                _buildPasswordField(),
                const SizedBox(height: 16),

                // Confirm password for registration
                if (!_isLogin && !authViewModel.isLinkSent) _buildConfirmPasswordField(),
                if (!_isLogin && !authViewModel.isLinkSent) const SizedBox(height: 16),
 
                // Link Status Info
                if (!_isLogin && authViewModel.isLinkSent) _buildLinkStatusInfo(),
                if (!_isLogin && authViewModel.isLinkSent) const SizedBox(height: 16),

                // Error message
                if (authViewModel.error != null) _buildError(authViewModel),
                if (authViewModel.error != null) const SizedBox(height: 16),

                // Login/Register button
                _buildAuthButton(authViewModel),
                const SizedBox(height: 24),

                // Toggle between login/register
                _buildToggleText(),

                // Forgot password
                if (_isLogin) const SizedBox(height: 16),
                if (_isLogin) _buildForgotPassword(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? 'Welcome Back!' : 'Create Account',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue to your restaurant dashboard'
              : 'Join us to discover amazing restaurants',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2E8B57)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.work_outline, color: Color(0xFF2E8B57)),
        ),
        items: const [
          DropdownMenuItem(value: 'customer', child: Text('Customer')),
          DropdownMenuItem(value: 'restaurant_owner', child: Text('Restaurant Owner')),
          DropdownMenuItem(value: 'delivery_driver', child: Text('Delivery Driver')),
          DropdownMenuItem(value: 'admin', child: Text('Admin')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedRole = value!;
          });
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E8B57)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E8B57)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFBDC3C7),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E8B57)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildError(AuthViewModel authViewModel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              authViewModel.error!,
              style: GoogleFonts.inter(
                color: const Color(0xFFE74C3C),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton(AuthViewModel authViewModel) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authViewModel.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E8B57),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: authViewModel.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          _isLogin ? 'Sign In' : 'Create Account',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : "Already have an account?",
          style: GoogleFonts.inter(
            color: const Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
              // Clear state if crossing back to login
              Provider.of<AuthViewModel>(context, listen: false).resetOtpState();
            });
          },
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E8B57),
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _buildLinkStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B57).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2E8B57), size: 48),
          const SizedBox(height: 12),
          Text(
            'Check Your Email',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a verification link to your email. Click the link to complete your registration.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF7F8C8D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Provider.of<AuthViewModel>(context, listen: false).requestSignInLink(_emailController.text);
            },
            child: const Text('Resend Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Center(
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password
        },
        child: Text(
          'Forgot Password?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E8B57),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (_isLogin) {
      await authViewModel.signIn(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      if (_selectedRole == 'delivery_driver') {
        // Navigate to dedicated driver registration screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverRegistrationScreen(
              email: _emailController.text,
              password: _passwordController.text,
              name: _nameController.text,
            ),
          ),
        );
        return;
      }

      if (!authViewModel.isLinkSent) {
        // Step 1: Request Link
        final success = await authViewModel.requestSignInLink(_emailController.text);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification link sent to your email!')),
          );
        }
      } else {
        // Inform user to check email instead of manual registration submit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check your email for the verification link.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}