import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ensure these imports match your project paths!
import 'package:smartfleet_frontend/dto/register_request_dto.dart';
import 'package:smartfleet_frontend/service/auth_service.dart';
import 'package:smartfleet_frontend/service/snackbar_service.dart'; 

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final String _selectedRole = 'Client';
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  // Base Info Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Client Specific Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  
  // Manager Specific Controllers
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _officeLocationController = TextEditingController();

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
      case 'admin': return UserRole.ADMIN;
      case 'manager': return UserRole.MANAGER;
      case 'driver': return UserRole.DRIVER;
      case 'client': return UserRole.CLIENT;
      default: return UserRole.CLIENT;
    }
  }

  String? _getNullableText(TextEditingController controller) {
    return controller.text.trim().isEmpty ? null : controller.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    // Helper booleans for our conditional UI
    final isClient = _selectedRole.toLowerCase() == 'client';
    final isManager = _selectedRole.toLowerCase() == 'manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.local_shipping_outlined, size: 28, color: Color(0xFF0F172A)),
                            SizedBox(width: 8),
                            Text(
                              'SmartFleet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create an account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your details to register and manage your\nglobal logistics operations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),



                        // --- ALWAYS SHOW: Personal Details ---
                        _buildSectionHeader('Personal Details'),
                        const SizedBox(height: 16),

                        _buildLabeledTextField(
                          label: 'Full Name',
                          hintText: 'John Doe',
                          controller: _nameController, 
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledTextField(
                          label: 'Email address',
                          hintText: 'name@smartfleet.com',
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController, 
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledTextField(
                          label: 'Phone Number',
                          hintText: '+1 (555) 000-0000',
                          keyboardType: TextInputType.phone,
                          controller: _phoneController, 
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledTextField(
                          label: 'Password',
                          hintText: '••••••••',
                          obscureText: _isPasswordObscured,
                          controller: _passwordController, 
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- CONDITIONALLY SHOW: Client Fields ---
                        if (isClient) ...[
                          _buildSectionHeader('Company Details'),
                          const SizedBox(height: 16),

                          _buildLabeledTextField(
                            label: 'Company Name',
                            hintText: 'Acme Logistics Corp',
                            controller: _companyNameController, 
                          ),
                          const SizedBox(height: 16),

                          _buildLabeledTextField(
                            label: 'Business Address',
                            hintText: '123 Fleet Street, Suite 100',
                            controller: _businessAddressController, 
                          ),
                          const SizedBox(height: 16),

                          _buildLabeledTextField(
                            label: 'Business Phone',
                            hintText: '+1 (555) 111-1111',
                            keyboardType: TextInputType.phone,
                            controller: _businessPhoneController, 
                          ),
                          const SizedBox(height: 32),
                        ],

                        // --- CONDITIONALLY SHOW: Manager Fields ---
                        if (isManager) ...[
                          _buildSectionHeader('Internal Assignment'),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabeledTextField(
                                  label: 'Department',
                                  hintText: 'Operations',
                                  controller: _departmentController, 
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabeledTextField(
                                  label: 'Office Location',
                                  hintText: 'New York, NY',
                                  controller: _officeLocationController, 
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Sign Up Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            setState(() => _isLoading = true);

                            try {
                              // We only attach specific fields if the correct role is selected.
                              // This prevents dirty data if the user types in "Manager" 
                              // fields but then switches the tab to "Driver" before submitting.
                              final requestDto = RegisterRequestDto(
                                email: _emailController.text.trim(),
                                name: _nameController.text.trim(),
                                password: _passwordController.text,
                                phone: _phoneController.text.trim(),
                                role: _getRoleEnum(),
                                
                                companyName: isClient ? _getNullableText(_companyNameController) : null,
                                businessAddress: isClient ? _getNullableText(_businessAddressController) : null,
                                businessPhone: isClient ? _getNullableText(_businessPhoneController) : null,
                                
                                department: isManager ? _getNullableText(_departmentController) : null,
                                officeLocation: isManager ? _getNullableText(_officeLocationController) : null,
                              );

                              await ref.read(authServiceProvider).register(requestDto);
                              
                              if (!context.mounted) return;
                              
                              // Use the global success service!
                              SnackbarService.showSuccess('Registration successful! Please sign in.');
                              Navigator.pop(context);

                            } catch (e) {
                              if (!context.mounted) return;
                              
                              // Check for 401s handled by the interceptor
                              if (e is DioException && e.response?.statusCode == 401) {
                                return;
                              }
                              
                              // Use our global error handler!
                              // SnackbarService.showError(ApiErrorHandler.getMessage(e));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Footer Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12.0)),
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          obscuringCharacter: '•',
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF0F172A)),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }


}