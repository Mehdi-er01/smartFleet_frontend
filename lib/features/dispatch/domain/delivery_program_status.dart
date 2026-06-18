enum DeliveryProgramStatus {
  pending('PENDING'),
  optimized('OPTIMIZED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  failed('FAILED'),
  cancelled('CANCELLED');

  final String value;
  const DeliveryProgramStatus(this.value);

  factory DeliveryProgramStatus.fromJson(String? json) {
    if (json == null) return DeliveryProgramStatus.pending;
    return DeliveryProgramStatus.values.firstWhere(
      (e) => e.value == json.toUpperCase(),
      orElse: () => DeliveryProgramStatus.pending,
    );
  }
}
