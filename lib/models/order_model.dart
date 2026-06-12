// class OrderModel {
//   final int id;
//   final String orderNumber;
//   final int clientId;
//   final double weightKg;
//   final double volumeM2;
//   final double deliveryLatitude;
//   final double deliveryLongitude;
//   final String deliveryAddress;
//   final String? deliveryDescription;
//   final String status;
//   final bool clientApproved;
//   final String createdAt;

//   OrderModel({
//     required this.id,
//     required this.orderNumber,
//     required this.clientId,
//     required this.weightKg,
//     required this.volumeM2,
//     required this.deliveryLatitude,
//     required this.deliveryLongitude,
//     required this.deliveryAddress,
//     this.deliveryDescription,
//     required this.status,
//     required this.clientApproved,
//     required this.createdAt,
//   });

//   factory OrderModel.fromJson(Map<String, dynamic> json) {
//     return OrderModel(
//       id: json['id'],
//       orderNumber: json['orderNumber'],
//       clientId: json['clientId'],
//       weightKg: (json['weightKg'] ?? 0).toDouble(),
//       volumeM2: (json['volumeM2'] ?? 0).toDouble(),
//       deliveryLatitude: (json['deliveryLatitude'] ?? 0).toDouble(),
//       deliveryLongitude: (json['deliveryLongitude'] ?? 0).toDouble(),
//       deliveryAddress: json['deliveryAddress'],
//       deliveryDescription: json['deliveryDescription'],
//       status: json['status'],
//       clientApproved: json['clientApproved'],
//       createdAt: json['createdAt'] ?? "",
//     );
//   }
// }