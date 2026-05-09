class MarketIndexQuote {
  const MarketIndexQuote({
    required this.code,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
  });

  final String code;
  final String name;
  final double price;
  final double change;
  final double changePercent;
}
