class VehicleDto {
  final int id;
  final String registrationNumber;
  final String brand;
  final String model;
  final int year;
  final double maxVolumeM2;
  final double maxPayloadKg;
  final double currentLoadM2;
  final double currentLoadKg;
  final int? managerId;
  final bool active;

  const VehicleDto({
    required this.id,
    required this.registrationNumber,
    required this.brand,
    required this.model,
    required this.year,
    required this.maxVolumeM2,
    required this.maxPayloadKg,
    this.currentLoadM2 = 0.0,
    this.currentLoadKg = 0.0,
    this.managerId,
    this.active = true,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      id: json['id'] as int,
      registrationNumber: json['registrationNumber'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      maxVolumeM2: (json['maxVolumeM2'] as num?)?.toDouble() ?? 0.0,
      maxPayloadKg: (json['maxPayloadKg'] as num?)?.toDouble() ?? 0.0,
      currentLoadM2: (json['currentLoadM2'] as num?)?.toDouble() ?? 0.0,
      currentLoadKg: (json['currentLoadKg'] as num?)?.toDouble() ?? 0.0,
      managerId: json['managerId'] as int?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'brand': brand,
      'model': model,
      'year': year,
      'maxVolumeM2': maxVolumeM2,
      'maxPayloadKg': maxPayloadKg,
      'currentLoadM2': currentLoadM2,
      'currentLoadKg': currentLoadKg,
      if (managerId != null) 'managerId': managerId,
      'active': active,
    };
  }
}
