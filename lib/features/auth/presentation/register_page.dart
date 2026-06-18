import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/features/auth/data/register_request_dto.dart';
import 'package:smartfleet_frontend/features/auth/data/user_dto.dart';
import 'package:smartfleet_frontend/features/auth/data/auth_repository.dart';
import 'package:smartfleet_frontend/core/snackbar_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final String _selectedRole = 'Client';
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _businessPhoneController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _officeLocationController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _departmentController.dispose();
    _officeLocationController.dispose();
    super.dispose();
  }

  UserRole _getRoleEnum() {
    switch (_selectedRole.toLowerCase()) {
      case 'admin':
        return UserRole.ADMIN;
      case 'manager':
        return UserRole.MANAGER;
      case 'driver':
        return UserRole.DRIVER;
      case 'client':
        return UserRole.CLIENT;
      default:
        return UserRole.CLIENT;
    }
  }

  String? _getNullableText(TextEditingController controller) {
    return controller.text.trim().isEmpty ? null : controller.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isClient = _selectedRole.toLowerCase() == 'client';
    final isManager = _selectedRole.toLowerCase() == 'manager';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Details
                _buildSectionHeader('Personal Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Full Name',
                  hintText: 'John Doe',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email address',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Phone Number',
                  hintText: '+212 600-000000',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Password',
                  hintText: '••••••••',
                  obscureText: _isPasswordObscured,
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                ),

                // Client Fields
                if (isClient) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader('Company Details'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Company Name',
                    hintText: 'Acme Logistics Corp',
                    controller: _companyNameController,
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Business Address',
                    hintText: '123 Fleet Street, Suite 100',
                    controller: _businessAddressController,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Business Phone',
                    hintText: '+212 500-000000',
                    keyboardType: TextInputType.phone,
                    controller: _businessPhoneController,
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                ],

                // Manager Fields
                if (isManager) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader('Internal Assignment'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Department',
                    hintText: 'Operations',
                    controller: _departmentController,
                    prefixIcon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Office Location',
                    hintText: 'Casablanca',
                    controller: _officeLocationController,
                    prefixIcon: Icons.map_outlined,
                  ),
                ],

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final isClient = _selectedRole.toLowerCase() == 'client';
    final isManager = _selectedRole.toLowerCase() == 'manager';

    try {
      final requestDto = RegisterRequestDto(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _getRoleEnum(),
        companyName: isClient ? _getNullableText(_companyNameController) : null,
        businessAddress: isClient
            ? _getNullableText(_businessAddressController)
            : null,
        businessPhone: isClient
            ? _getNullableText(_businessPhoneController)
            : null,
        department: isManager ? _getNullableText(_departmentController) : null,
        officeLocation: isManager
            ? _getNullableText(_officeLocationController)
            : null,
      );

      await ref.read(authServiceProvider).register(requestDto);

      if (!context.mounted) return;
      SnackbarService.showSuccess('Registration successful! Please sign in.');
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      if (e is DioException && e.response?.statusCode == 401) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          obscuringCharacter: '•',
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black, fontSize: 15),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: Colors.grey.shade500, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
