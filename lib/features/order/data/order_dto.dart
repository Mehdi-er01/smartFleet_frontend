import 'package:smartfleet_frontend/features/order/domain/order_status.dart';

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
  final String? priority;
  final int? visitSequence;
  final String? createdAt;

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
    this.priority,
    this.visitSequence,
    this.createdAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber'] as String? ?? '',
      clientId: (json['clientId'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      volumeM2: (json['volumeM2'] as num?)?.toDouble() ?? 0,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? 0,
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      deliveryDescription: json['deliveryDescription'] as String?,
      status: json['status'] as String? ?? OrderStatus.pending.value,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as String?,
      actualDeliveryTime: json['actualDeliveryTime'] as String?,
      clientApproved: json['clientApproved'] as bool? ?? false,
      priority: json['priority'] as String?,
      visitSequence: (json['visitSequence'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      if (orderNumber.isNotEmpty) 'orderNumber': orderNumber,
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
      if (priority != null) 'priority': priority,
      if (visitSequence != null) 'visitSequence': visitSequence,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Creates a copy with optional field overrides
  OrderDto copyWith({
    int? id,
    String? orderNumber,
    int? clientId,
    double? weightKg,
    double? volumeM2,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryAddress,
    String? deliveryDescription,
    String? status,
    String? estimatedDeliveryTime,
    String? actualDeliveryTime,
    bool? clientApproved,
    String? priority,
    int? visitSequence,
    String? createdAt,
  }) {
    return OrderDto(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      clientId: clientId ?? this.clientId,
      weightKg: weightKg ?? this.weightKg,
      volumeM2: volumeM2 ?? this.volumeM2,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDescription: deliveryDescription ?? this.deliveryDescription,
      status: status ?? this.status,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      clientApproved: clientApproved ?? this.clientApproved,
      priority: priority ?? this.priority,
      visitSequence: visitSequence ?? this.visitSequence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
