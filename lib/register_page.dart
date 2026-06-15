import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final isClient = _selectedRole.toLowerCase() == 'client';
    final isManager = _selectedRole.toLowerCase() == 'manager';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep Space Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070913),
                  Color(0xFF0F1123),
                  Color(0xFF070913),
                ],
              ),
            ),
          ),
          
          // 2. Premium Mesh Gradient Glowing Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14B8A6).withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 3. Central Form Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.035),
                        borderRadius: BorderRadius.circular(28.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32.0, 40.0, 32.0, 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Glowing Icon Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF6366F1).withOpacity(0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping_rounded,
                                        size: 26,
                                        color: Color(0xFF818CF8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'SmartFleet',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Create an account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fill in your information to join our premium logistics platform.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.55),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // --- Personal Details ---
                                _buildSectionHeader('Personal Details'),
                                const SizedBox(height: 16),

                                _buildLabeledTextField(
                                  label: 'Full Name',
                                  hintText: 'John Doe',
                                  controller: _nameController, 
                                  prefixIcon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),

                                _buildLabeledTextField(
                                  label: 'Email address',
                                  hintText: 'name@smartfleet.com',
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailController, 
                                  prefixIcon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 16),

                                _buildLabeledTextField(
                                  label: 'Phone Number',
                                  hintText: '+212 600-000000',
                                  keyboardType: TextInputType.phone,
                                  controller: _phoneController, 
                                  prefixIcon: Icons.phone_outlined,
                                ),
                                const SizedBox(height: 16),

                                _buildLabeledTextField(
                                  label: 'Password',
                                  hintText: '••••••••',
                                  obscureText: _isPasswordObscured,
                                  controller: _passwordController, 
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white.withOpacity(0.4),
                                      size: 20,
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
                                    prefixIcon: Icons.business_outlined,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildLabeledTextField(
                                    label: 'Business Address',
                                    hintText: '123 Fleet Street, Suite 100',
                                    controller: _businessAddressController, 
                                    prefixIcon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildLabeledTextField(
                                    label: 'Business Phone',
                                    hintText: '+212 500-000000',
                                    keyboardType: TextInputType.phone,
                                    controller: _businessPhoneController, 
                                    prefixIcon: Icons.phone_android_outlined,
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
                                          prefixIcon: Icons.work_outline,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildLabeledTextField(
                                          label: 'Office Location',
                                          hintText: 'Casablanca',
                                          controller: _officeLocationController, 
                                          prefixIcon: Icons.map_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                // Sign Up Button with premium glow
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () async {
                                      setState(() => _isLoading = true);

                                      try {
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
                                        
                                        SnackbarService.showSuccess('Registration successful! Please sign in.');
                                        Navigator.pop(context);

                                      } catch (e) {
                                        if (!context.mounted) return;
                                        if (e is DioException && e.response?.statusCode == 401) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) setState(() => _isLoading = false);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.0),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.disabled)) {
                                          return Colors.white.withOpacity(0.04);
                                        }
                                        return null;
                                      }),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF4F46E5),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14.0),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
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
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
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
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28.0)),
                              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: Color(0xFF818CF8),
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
            ),
          ),
        ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.white.withOpacity(0.08)),
      ],
    );
  }

  Widget _buildLabeledTextField({
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          obscuringCharacter: '•',
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: const Color(0xFF818CF8),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.4), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}