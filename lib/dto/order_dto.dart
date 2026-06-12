class OrderDto {
  final int id;
  final String orderNumber;
  final int? clientId;
  final double weightKg;
  final double volumeM2;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryAddress;
  final String? deliveryDescription;
  final String status;
  final String? estimatedDeliveryTime;
  final String? actualDeliveryTime;
  final bool clientApproved;

  const OrderDto({
    required this.id,
    required this.orderNumber,
    this.clientId,
    required this.weightKg,
    required this.volumeM2,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryAddress,
    this.deliveryDescription,
    required this.status,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.clientApproved = false,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as int,
      orderNumber: json['orderNumber'] as String? ?? '',
      clientId: json['clientId'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      volumeM2: (json['volumeM2'] as num?)?.toDouble() ?? 0,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? 0,
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      deliveryDescription: json['deliveryDescription'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as String?,
      actualDeliveryTime: json['actualDeliveryTime'] as String?,
      clientApproved: json['clientApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      if (clientId != null) 'clientId': clientId,
      'weightKg': weightKg,
      'volumeM2': volumeM2,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryAddress': deliveryAddress,
      if (deliveryDescription != null)
        'deliveryDescription': deliveryDescription,
      'status': status,
      if (estimatedDeliveryTime != null)
        'estimatedDeliveryTime': estimatedDeliveryTime,
      if (actualDeliveryTime != null) 'actualDeliveryTime': actualDeliveryTime,
      'clientApproved': clientApproved,
    };
  }

  /// Creates a copy with optional field overrides
  OrderDto copyWith({int? id, String? orderNumber}) {
    return OrderDto(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      clientId: clientId,
      weightKg: weightKg,
      volumeM2: volumeM2,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryAddress: deliveryAddress,
      deliveryDescription: deliveryDescription,
      status: status,
      estimatedDeliveryTime: estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime,
      clientApproved: clientApproved,
    );
  }
}
