import 'package:smartfleet_frontend/features/auth/data/user_dto.dart';

class RegisterRequestDto {
  // Base User Info
  final String email;
  final String password;
  final String name;
  final String phone;
  final UserRole role;

  // Specific Fields for CLIENT
  final String? companyName;
  final String? businessAddress;
  final String? businessPhone;

  // Specific Fields for MANAGER
  final String? department;
  final String? officeLocation;

  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.role,
    this.companyName,
    this.businessAddress,
    this.businessPhone,
    this.department,
    this.officeLocation,
  });

  // Since this is a Request DTO, you usually only need a toJson method
  // to send it to your backend (you rarely parse a registration request from JSON)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'role': role.name, // Converts the Enum back to a String (e.g., "MANAGER")
      // Dart Magic: "Collection if"
      // These keys will ONLY be added to the JSON if the value is not null.
      // This prevents you from sending {"department": null} for a Client.
      if (companyName != null) 'companyName': companyName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (businessPhone != null) 'businessPhone': businessPhone,
      if (department != null) 'department': department,
      if (officeLocation != null) 'officeLocation': officeLocation,
    };
  }
}
