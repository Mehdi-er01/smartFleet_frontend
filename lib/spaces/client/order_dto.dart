class OrderDTO {
  final int id;
  final String orderNumber;
  final int clientId;
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
  final String? createdAt; // Ajouté depuis le Swagger

  OrderDTO({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.weightKg,
    required this.volumeM2,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryAddress,
    this.deliveryDescription,
    required this.status,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.clientApproved,
    this.createdAt,
  });

  factory OrderDTO.fromJson(Map<String, dynamic> json) {
    return OrderDTO(
      id: json['id'],
      orderNumber: json['orderNumber'],
      clientId: json['clientId'],
      weightKg: (json['weightKg'] as num).toDouble(),
      volumeM2: (json['volumeM2'] as num).toDouble(),
      deliveryLatitude: (json['deliveryLatitude'] as num).toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'],
      deliveryDescription: json['deliveryDescription'],
      status: json['status'],
      estimatedDeliveryTime: json['estimatedDeliveryTime'],
      actualDeliveryTime: json['actualDeliveryTime'],
      clientApproved: json['clientApproved'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}