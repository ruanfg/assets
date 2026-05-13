import '../models/fund_models.dart';

abstract class FundRepository {
  Future<String> fetchRelatedSectors(String code);

  Future<String> fetchFundSecidByRelatedSector(String relatedSector);

  Future<RelatedSectorQuote?> fetchEastmoneySectorQuote(String secid);

  Future<RelatedSectorQuote?> fetchRelatedSectorLiveQuote(
    String relatedSectorLabel,
  );

  Future<double?> fetchFundNetValue(String code, String date);

  Future<List<FundNetValuePoint>> fetchFundNetValueRange(
    String code,
    String startDate,
    String endDate,
  );

  Future<SmartFundNetValue?> fetchSmartFundNetValue(
    String code,
    String startDate,
  );

  Future<FundQuote> fetchFundDataFallback(String code);

  Future<FundQuote> fetchFundData(String code);

  Future<List<FundSearchResult>> searchFunds(String keyword);

  Future<PingzhongData> fetchFundPingzhongdata(String fundCode);

  Future<FundPeriodReturns> fetchFundPeriodReturns(String fundCode);

  Future<FundHistoryResult> fetchFundHistory(
    String fundCode, {
    FundHistoryRange range = FundHistoryRange.oneMonth,
  });

  Future<FundTextParseResult?> parseFundTextWithLlm(String text);

  Future<List<FundNetValuePoint>> fetchRecentNavRecords(
    String code, {
    int count = 6,
  });

  Future<List<FundAnnualReturn>> fetchAnnualReturns(String code);
}
