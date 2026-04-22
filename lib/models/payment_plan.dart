class PaymentPlan {
  const PaymentPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
  });

  final String id;
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id']?.toString() ?? 'plan',
      name: json['name']?.toString() ?? 'Plan',
      monthlyPrice: (json['price_monthly'] as num?)?.toDouble() ?? 0,
      yearlyPrice: (json['price_yearly'] as num?)?.toDouble() ?? 0,
      features: (json['features'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }
}
