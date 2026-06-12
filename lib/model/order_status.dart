enum OrderStatus {
  pending('PENDING'),
  assigned('ASSIGNED'),
  inTransit('IN_TRANSIT'),
  arrivingSoon('ARRIVING_SOON'),
  delivered('DELIVERED'),
  rejected('REJECTED'),
  cancelled('CANCELLED');

  final String value;
  const OrderStatus(this.value);

  /// Helper to safely parse the enum from a JSON string.
  factory OrderStatus.fromJson(String? json) {
    if (json == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (e) => e.value == json.toUpperCase(),
      orElse: () => OrderStatus.pending, // Fallback to pending if unknown
    );
  }
}