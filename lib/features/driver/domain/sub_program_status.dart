enum SubProgramStatus {
  pending('PENDING'),
  assigned('ASSIGNED'),
  inTransit('IN_TRANSIT'),
  completed('COMPLETED'),
  failed('FAILED'),
  cancelled('CANCELLED');

  final String value;
  const SubProgramStatus(this.value);

  factory SubProgramStatus.fromJson(String? json) {
    if (json == null) return SubProgramStatus.pending;
    return SubProgramStatus.values.firstWhere(
      (e) => e.value == json.toUpperCase(),
      orElse: () => SubProgramStatus.pending,
    );
  }
}
