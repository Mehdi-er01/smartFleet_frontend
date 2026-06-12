class DriverDto {
  final int id;
  final String email;
  final String name;
  final String phone;
  final String? licenseNumber;
  final String? licenseExpiry;
  final bool available;
  final bool active;
  final int? managerId;

  const DriverDto({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.licenseNumber,
    this.licenseExpiry,
    required this.available,
    required this.active,
    this.managerId,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      licenseExpiry: json['licenseExpiry'] as String?,
      available: json['available'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
      managerId: json['managerId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (licenseExpiry != null) 'licenseExpiry': licenseExpiry,
      'available': available,
      'active': active,
      if (managerId != null) 'managerId': managerId,
    };
  }

  /// A driver is assigned to a manager when managerId is not null
  bool get isAssigned => managerId != null;
}
