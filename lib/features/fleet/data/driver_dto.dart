/// Matches backend UserDTO returned by /drivers/my-drivers and /drivers/unassigned.
/// Backend returns: id, email, name, phone, role, active.
/// Fields not in UserDTO (licenseNumber, licenseExpiry, available, managerId)
/// are nullable/optional and populated only when using /drivers/my-drivers/locations.
class DriverDto {
  final int id;
  final String email;
  final String name;
  final String phone;
  final String? role;
  final bool active;
  final String? licenseNumber;
  final String? licenseExpiry;
  final bool? available;
  final int? managerId;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? lastLocationUpdate;

  const DriverDto({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.role,
    this.active = true,
    this.licenseNumber,
    this.licenseExpiry,
    this.available,
    this.managerId,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
  });

  /// Parses from backend UserDTO JSON (driver listing endpoints).
  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String?,
      active: json['active'] as bool? ?? true,
      licenseNumber: json['licenseNumber'] as String?,
      licenseExpiry: json['licenseExpiry'] as String?,
      available: json['available'] as bool?,
      managerId: (json['managerId'] as num?)?.toInt(),
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      lastLocationUpdate: json['lastLocationUpdate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      if (role != null) 'role': role,
      'active': active,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (licenseExpiry != null) 'licenseExpiry': licenseExpiry,
      if (available != null) 'available': available,
      if (managerId != null) 'managerId': managerId,
      if (currentLatitude != null) 'currentLatitude': currentLatitude,
      if (currentLongitude != null) 'currentLongitude': currentLongitude,
      if (lastLocationUpdate != null) 'lastLocationUpdate': lastLocationUpdate,
    };
  }

  /// A driver is assigned to a manager when managerId is not null
  bool get isAssigned => managerId != null;
  bool get hasLocation => currentLatitude != null && currentLongitude != null;
}
