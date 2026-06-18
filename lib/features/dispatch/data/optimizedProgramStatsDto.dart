// {
//   "deliveryProgramId": 0,
//   "totalOrders": 0,
//   "totalSubPrograms": 0,
//   "totalVehicles": 0,
//   "totalDistanceKm": 0,
//   "totalDurationMinutes": 0,
//   "optimizationDate": "string"
// }
class OptimizedProgramStatsDto {
  int deliveryProgramId;
  int totalOrders;
  int totalSubPrograms;
  int totalVehicles;
  double totalDistanceKm;
  int totalDurationMinutes;
  String optimizationDate;

  OptimizedProgramStatsDto({
    required this.deliveryProgramId,
    required this.totalOrders,
    required this.totalSubPrograms,
    required this.totalVehicles,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.optimizationDate,
  });
  //fromJsonMethode
  factory OptimizedProgramStatsDto.fromJson(Map<String, dynamic> json) =>
      OptimizedProgramStatsDto(
        deliveryProgramId: json['deliveryProgramId'],
        totalOrders: json['totalOrders'],
        totalSubPrograms: json['totalSubPrograms'],
        totalVehicles: json['totalVehicles'],
        totalDistanceKm: json['totalDistanceKm'].toDouble(),
        totalDurationMinutes: json['totalDurationMinutes'],
        optimizationDate: json['optimizationDate'],
      );
  //toJson
  Map<String, dynamic> toJson() => {
    'deliveryProgramId': deliveryProgramId,
    'totalOrders': totalOrders,
    'totalSubPrograms': totalSubPrograms,
    'totalVehicles': totalVehicles,
    'totalDistanceKm': totalDistanceKm,
    'totalDurationMinutes': totalDurationMinutes,
    'optimizationDate': optimizationDate,
  };
}
