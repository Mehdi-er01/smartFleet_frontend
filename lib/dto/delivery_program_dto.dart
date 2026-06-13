import 'package:smartfleet_frontend/dto/order_dto.dart';
import 'package:smartfleet_frontend/dto/sub_program_dto.dart';

class DeliveryProgramDto {
  final int id;
  final String programNumber;
  final int? managerId;
  final String status;
  final List<OrderDto> orders;
  final List<SubProgramDto> subPrograms;
  final String? plannedDate;
  final String? executionDate;
  final String? completionDate;
  final String? notes;

  const DeliveryProgramDto({
    required this.id,
    required this.programNumber,
    this.managerId,
    required this.status,
    this.orders = const [],
    this.subPrograms = const [],
    this.plannedDate,
    this.executionDate,
    this.completionDate,
    this.notes,
  });

  factory DeliveryProgramDto.fromJson(Map<String, dynamic> json) {
    return DeliveryProgramDto(
      id: (json['id'] as num).toInt(),
      programNumber: json['programNumber'] as String? ?? '',
      managerId: (json['managerId'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'PENDING',
      orders:
          (json['orders'] as List?)
              ?.map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subPrograms:
          (json['subPrograms'] as List?)
              ?.map((e) => SubProgramDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      plannedDate: json['plannedDate'] as String?,
      executionDate: json['executionDate'] as String?,
      completionDate: json['completionDate'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programNumber': programNumber,
      if (managerId != null) 'managerId': managerId,
      'status': status,
      'orders': orders.map((e) => e.toJson()).toList(),
      'subPrograms': subPrograms.map((e) => e.toJson()).toList(),
      if (plannedDate != null) 'plannedDate': plannedDate,
      if (executionDate != null) 'executionDate': executionDate,
      if (completionDate != null) 'completionDate': completionDate,
      if (notes != null) 'notes': notes,
    };
  }
}
