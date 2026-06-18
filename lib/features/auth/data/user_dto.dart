enum UserRole {
  ADMIN,
  MANAGER,
  DRIVER,
  CLIENT,
}

class UserDto {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final bool active;

  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.active,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.CLIENT, 
      ),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone, 
      'role': role.name,
      'active': active,
    };
  }
}