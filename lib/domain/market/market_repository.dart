import '../../features/market/models/market_models.dart';

abstract class MarketRepository {
  Future<String?> fetchShanghaiIndexDate();

  Future<List<MarketIndexQuote>> fetchMarketIndices();
}
