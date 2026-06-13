class SubProgramDto {
  final int id;
  final String subProgramNumber;
  final int deliveryProgramId;
  final int? driverId;
  final int? vehicleId;
  final List<int> orderIds;
  final String status;
  final String? polyline;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final double? actualDistanceKm;
  final int? actualDurationMinutes;
  final String? startTime;
  final String? endTime;
  final int totalOrdersCount;
  final int approvedOrdersCount;

  // Denormalized fields for UI display (populated by frontend)
  final String? driverName;
  final String? vehicleRegistration;

  const SubProgramDto({
    required this.id,
    required this.subProgramNumber,
    required this.deliveryProgramId,
    this.driverId,
    this.vehicleId,
    this.orderIds = const [],
    required this.status,
    this.polyline,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    this.actualDistanceKm,
    this.actualDurationMinutes,
    this.startTime,
    this.endTime,
    this.totalOrdersCount = 0,
    this.approvedOrdersCount = 0,
    this.driverName,
    this.vehicleRegistration,
  });

  factory SubProgramDto.fromJson(Map<String, dynamic> json) {
    return SubProgramDto(
      id: (json['id'] as num).toInt(),
      subProgramNumber: json['subProgramNumber'] as String? ?? '',
      deliveryProgramId: (json['deliveryProgramId'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt(),
      vehicleId: (json['vehicleId'] as num?)?.toInt(),
      orderIds:
          (json['orderIds'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'PENDING',
      polyline: json['polyline'] as String?,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)
          ?.toInt(),
      actualDistanceKm: (json['actualDistanceKm'] as num?)?.toDouble(),
      actualDurationMinutes: (json['actualDurationMinutes'] as num?)?.toInt(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      totalOrdersCount: (json['totalOrdersCount'] as num?)?.toInt() ?? 0,
      approvedOrdersCount: (json['approvedOrdersCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subProgramNumber': subProgramNumber,
      'deliveryProgramId': deliveryProgramId,
      if (driverId != null) 'driverId': driverId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      'orderIds': orderIds,
      'status': status,
      if (polyline != null) 'polyline': polyline,
      if (estimatedDistanceKm != null)
        'estimatedDistanceKm': estimatedDistanceKm,
      if (estimatedDurationMinutes != null)
        'estimatedDurationMinutes': estimatedDurationMinutes,
      if (actualDistanceKm != null) 'actualDistanceKm': actualDistanceKm,
      if (actualDurationMinutes != null)
        'actualDurationMinutes': actualDurationMinutes,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'totalOrdersCount': totalOrdersCount,
      'approvedOrdersCount': approvedOrdersCount,
    };
  }
}
