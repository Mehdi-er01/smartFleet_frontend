enum OrderPriority {
  low('LOW'),
  normal('NORMAL'),
  high('HIGH');

  final String value;
  const OrderPriority(this.value);

  factory OrderPriority.fromJson(String? json) {
    if (json == null) return OrderPriority.normal;
    return OrderPriority.values.firstWhere(
      (e) => e.value == json.toUpperCase(),
      orElse: () => OrderPriority.normal,
    );
  }
}
