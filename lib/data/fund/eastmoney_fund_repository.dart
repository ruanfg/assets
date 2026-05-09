import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio_factory.dart';
import '../../core/utils/fund_js_parsers.dart';
import '../../core/utils/shanghai_clock.dart';
import '../../domain/fund/fund_cloud_store.dart';
import '../../domain/fund/fund_repository.dart';
import '../../features/fund/models/fund_models.dart';

class EastmoneyFundRepository implements FundRepository {
  EastmoneyFundRepository({Dio? dio, FundCloudStore? cloudStore})
    : _dio = dio ?? AppDioFactory.create(),
      _cloudStore = cloudStore;

  final Dio _dio;
  final FundCloudStore? _cloudStore;

  static const List<String> _pingzhongdataKeys = [
    'ishb',
    'fS_name',
    'fS_code',
    'fund_sourceRate',
    'fund_Rate',
    'fund_minsg',
    'stockCodes',
    'zqCodes',
    'stockCodesNew',
    'zqCodesNew',
    'syl_1n',
    'syl_6y',
    'syl_3y',
    'syl_1y',
    'Data_fundSharesPositions',
    'Data_netWorthTrend',
    'Data_ACWorthTrend',
    'Data_grandTotal',
    'Data_rateInSimilarType',
    'Data_rateInSimilarPersent',
    'Data_fluctuationScale',
    'Data_holderStructure',
    'Data_assetAllocation',
    'Data_performanceEvaluation',
    'Data_currentFundManager',
    'Data_buySedemption',
    'swithSameType',
  ];

  @override
  Future<String> fetchRelatedSectors(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty || _cloudStore == null) return '';
    return (await _cloudStore!.fetchRelatedSector(normalized))?.trim() ?? '';
  }

  @override
  Future<String> fetchFundSecidByRelatedSector(String relatedSector) async {
    final normalized = relatedSector.trim();
    if (normalized.isEmpty || _cloudStore == null) return '';
    return (await _cloudStore!.fetchSecidByRelatedSector(normalized))?.trim() ??
        '';
  }

  @override
  Future<RelatedSectorQuote?> fetchEastmoneySectorQuote(String secid) async {
    final normalized = secid.trim();
    if (normalized.isEmpty) return null;
    final response = await _dio.get<Map<String, dynamic>>(
      'https://push2delay.eastmoney.com/api/qt/stock/get',
      queryParameters: {
        'secid': normalized,
        'fields': 'f58,f57,f43,f170,f169,f124,f86',
      },
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    final pctRaw = data['f170'];
    final pct = pctRaw == null ? null : (double.tryParse('$pctRaw') ?? 0) / 100;
    return RelatedSectorQuote(
      name: data['f58']?.toString() ?? '',
      code: data['f57']?.toString() ?? '',
      pct: pctRaw == null ? null : pct,
    );
  }

  @override
  Future<RelatedSectorQuote?> fetchRelatedSectorLiveQuote(
    String relatedSectorLabel,
  ) async {
    final secid = await fetchFundSecidByRelatedSector(relatedSectorLabel);
    if (secid.isEmpty) return null;
    return fetchEastmoneySectorQuote(secid);
  }

  @override
  Future<double?> fetchFundNetValue(String code, String date) async {
    final content = await _fetchLsjzContent(
      code: code,
      page: 1,
      per: 1,
      startDate: date,
      endDate: date,
    );
    final list = FundJsParsers.parseNetValuesFromLsjzContent(content);
    for (final row in list) {
      if (row.date == date) return row.nav;
    }
    return null;
  }

  @override
  Future<List<FundNetValuePoint>> fetchFundNetValueRange(
    String code,
    String startDate,
    String endDate,
  ) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return const [];
    if (startDate.compareTo(endDate) > 0) return const [];

    final merged = <String, FundNetValuePoint>{};
    var page = 1;
    const per = 500;
    while (true) {
      final content = await _fetchLsjzContent(
        code: normalized,
        page: page,
        per: per,
        startDate: startDate,
        endDate: endDate,
      );
      final batch = FundJsParsers.parseNetValuesFromLsjzContent(content);
      if (batch.isEmpty) break;
      for (final item in batch) {
        merged[item.date] = item;
      }
      if (batch.length < per) break;
      page += 1;
    }
    final result = merged.values.toList()
      ..sort((left, right) => left.date.compareTo(right.date));
    return result;
  }

  @override
  Future<SmartFundNetValue?> fetchSmartFundNetValue(
    String code,
    String startDate,
  ) async {
    final start = DateTime.tryParse(startDate);
    if (start == null) return null;
    final today = ShanghaiClock.now();
    var cursor = DateTime(start.year, start.month, start.day);
    for (var i = 0; i < 30; i++) {
      if (cursor.isAfter(today)) break;
      final date = ShanghaiClock.formatDate(cursor);
      final value = await fetchFundNetValue(code, date);
      if (value != null) {
        return SmartFundNetValue(date: date, value: value);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return null;
  }

  @override
  Future<FundQuote> fetchFundDataFallback(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      throw Exception('fund code is empty');
    }

    var fundName = '';
    try {
      final searchResults = await searchFunds(normalized);
      final exact = searchResults.where((item) => item.code == normalized);
      if (exact.isNotEmpty) {
        fundName = exact.first.name;
      }
    } catch (_) {}

    final content = await _fetchLsjzContent(
      code: normalized,
      page: 1,
      per: 3,
      startDate: '',
      endDate: '',
    );
    final navList = FundJsParsers.parseNetValuesFromLsjzContent(content);
    if (navList.isEmpty) {
      throw Exception('failed to load fund data');
    }

    final latest = navList.last;
    final previous = navList.length > 1 ? navList[navList.length - 2] : null;
    final metrics = FundJsParsers.computeYesterdayNavMetrics(navList);
    return FundQuote(
      code: normalized,
      name: fundName.isEmpty ? '未知基金($normalized)' : fundName,
      dwjz: latest.nav.toString(),
      gsz: null,
      gztime: null,
      jzrq: latest.date,
      gszzl: null,
      zzl: latest.growth,
      lastNav: previous?.nav.toString(),
      yesterdayZzl: metrics.yesterdayZzl,
      yesterdayNavDelta: metrics.yesterdayNavDelta,
      noValuation: true,
      holdings: const [],
      holdingsReportDate: null,
      holdingsIsLastQuarter: false,
    );
  }

  @override
  Future<FundQuote> fetchFundData(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return fetchFundDataFallback(code);
    }

    final jsonpUrl =
        'https://fundgz.1234567.com.cn/js/$normalized.js?rt=${DateTime.now().millisecondsSinceEpoch}';
    try {
      final jsonpBody = await _getPlain(jsonpUrl);
      final json = FundJsParsers.parseJsonpBody(jsonpBody);
      if (json == null) {
        return fetchFundDataFallback(normalized);
      }

      final quote = Future.wait([
        _fetchLatestNavSummary(normalized),
        _fetchFundHoldings(normalized),
      ]);

      final resolved = await quote;
      final latestNavSummary = resolved[0] as _LatestNavSummary?;
      final holdingsSummary = resolved[1] as _HoldingsSummary;
      final gszzlValue = double.tryParse('${json['gszzl']}');

      return FundQuote(
        code: json['fundcode']?.toString() ?? normalized,
        name: json['name']?.toString() ?? '',
        dwjz: latestNavSummary?.dwjz ?? json['dwjz']?.toString(),
        gsz: json['gsz']?.toString(),
        gztime: json['gztime']?.toString(),
        jzrq: latestNavSummary?.jzrq ?? json['jzrq']?.toString(),
        gszzl: gszzlValue,
        zzl: latestNavSummary?.zzl,
        lastNav: latestNavSummary?.lastNav,
        yesterdayZzl: latestNavSummary?.yesterdayZzl,
        yesterdayNavDelta: latestNavSummary?.yesterdayNavDelta,
        noValuation: false,
        holdings: holdingsSummary.holdings,
        holdingsReportDate: holdingsSummary.reportDate,
        holdingsIsLastQuarter: holdingsSummary.isLastQuarter,
      );
    } catch (_) {
      return fetchFundDataFallback(normalized);
    }
  }

  @override
  Future<List<FundSearchResult>> searchFunds(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return const [];
    final callbackName = 'SuggestData_${DateTime.now().millisecondsSinceEpoch}';
    final url =
        'https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx'
        '?m=1&key=${Uri.encodeQueryComponent(normalized)}'
        '&callback=$callbackName&_=${DateTime.now().millisecondsSinceEpoch}';
    final body = await _getPlain(url);
    final json = FundJsParsers.parseJsonpBody(body);
    final source = json?['Datas'];
    if (source is! List) return const [];

    return source
        .whereType<Map<String, dynamic>>()
        .where(
          (item) =>
              item['CATEGORY'] == 700 ||
              item['CATEGORY'] == '700' ||
              item['CATEGORYDESC'] == '基金',
        )
        .map(FundSearchResult.fromMap)
        .toList(growable: false);
  }

  @override
  Future<PingzhongData> fetchFundPingzhongdata(String fundCode) async {
    final normalized = fundCode.trim();
    if (normalized.isEmpty) {
      throw Exception('fundCode is empty');
    }
    final url =
        'https://fund.eastmoney.com/pingzhongdata/$normalized.js?v=${DateTime.now().millisecondsSinceEpoch}';
    final body = await _getPlain(url);
    final parsed = FundJsParsers.parsePingzhongdataScript(
      body,
      _pingzhongdataKeys,
      normalized,
    );
    return PingzhongData(parsed);
  }

  @override
  Future<FundPeriodReturns> fetchFundPeriodReturns(String fundCode) async {
    try {
      final data = await fetchFundPingzhongdata(fundCode);
      return FundPeriodReturns(
        week: FundJsParsers.computeWeekReturnFromNetWorthTrend(
          data.raw['Data_netWorthTrend'] as List?,
        ),
        month: FundJsParsers.parsePingzhongSylNumber(data.raw['syl_1y']),
        month3: FundJsParsers.parsePingzhongSylNumber(data.raw['syl_3y']),
        month6: FundJsParsers.parsePingzhongSylNumber(data.raw['syl_6y']),
        year1: FundJsParsers.parsePingzhongSylNumber(data.raw['syl_1n']),
      );
    } catch (_) {
      return const FundPeriodReturns(
        week: null,
        month: null,
        month3: null,
        month6: null,
        year1: null,
      );
    }
  }

  @override
  Future<FundHistoryResult> fetchFundHistory(
    String fundCode, {
    FundHistoryRange range = FundHistoryRange.oneMonth,
  }) async {
    final pingzhongdata = await fetchFundPingzhongdata(fundCode);
    return FundHistoryResult(
      points: FundJsParsers.parseFundHistory(
        pingzhongdata: pingzhongdata.raw,
        range: range,
      ),
      grandTotalSeries: FundJsParsers.parseGrandTotalSeries(
        pingzhongdata: pingzhongdata.raw,
        range: range,
      ),
    );
  }

  @override
  Future<FundTextParseResult?> parseFundTextWithLlm(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty || _cloudStore == null) return null;
    final items = await _cloudStore!.analyzeFundText(normalized);
    if (items == null) return null;
    return FundTextParseResult.fromItems(items);
  }

  Future<String> _getPlain(String url) async {
    final response = await _dio.get<String>(url);
    if ((response.statusCode ?? 500) >= 400) {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 500,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    return response.data ?? '';
  }

  Future<String?> _fetchLsjzContent({
    required String code,
    required int page,
    required int per,
    required String startDate,
    required String endDate,
  }) async {
    final url =
        'https://fundf10.eastmoney.com/F10DataApi.aspx'
        '?type=lsjz&code=$code&page=$page&per=$per&sdate=$startDate&edate=$endDate';
    final source = await _getPlain(url);
    return FundJsParsers.extractApidataContent(source);
  }

  Future<_LatestNavSummary?> _fetchLatestNavSummary(String code) async {
    final content = await _fetchLsjzContent(
      code: code,
      page: 1,
      per: 3,
      startDate: '',
      endDate: '',
    );
    final navList = FundJsParsers.parseNetValuesFromLsjzContent(content);
    if (navList.isEmpty) return null;
    final latest = navList.last;
    final previous = navList.length > 1 ? navList[navList.length - 2] : null;
    final metrics = FundJsParsers.computeYesterdayNavMetrics(navList);
    return _LatestNavSummary(
      dwjz: latest.nav.toString(),
      zzl: latest.growth,
      jzrq: latest.date,
      lastNav: previous?.nav.toString(),
      yesterdayZzl: metrics.yesterdayZzl,
      yesterdayNavDelta: metrics.yesterdayNavDelta,
    );
  }

  Future<_HoldingsSummary> _fetchFundHoldings(String code) async {
    try {
      final url =
          'https://fundf10.eastmoney.com/FundArchivesDatas.aspx'
          '?type=jjcc&code=$code&topline=10&year=&month=&_=${DateTime.now().millisecondsSinceEpoch}';
      final body = await _getPlain(url);
      final html = FundJsParsers.extractApidataContent(body) ?? '';
      final reportDate = FundJsParsers.extractHoldingsReportDate(html);
      final isLastQuarter = FundJsParsers.isLastQuarterReport(reportDate);
      if (!isLastQuarter) {
        return _HoldingsSummary(
          holdings: const [],
          reportDate: reportDate,
          isLastQuarter: false,
        );
      }

      final baseHoldings = FundJsParsers.parseFundHoldings(html);
      final quoteCodes = <String, String>{};
      for (final item in baseHoldings) {
        final tencentCode = FundJsParsers.normalizeTencentCode(item.code);
        if (tencentCode != null) {
          quoteCodes[item.code] = tencentCode;
        }
      }

      final changes = <String, double?>{};
      if (quoteCodes.isNotEmpty) {
        final joined = quoteCodes.values.join(',');
        final quoteBody = await _getPlain('https://qt.gtimg.cn/q=$joined');
        final assignments = FundJsParsers.parseTencentQuoteAssignments(
          quoteBody,
        );
        for (final entry in quoteCodes.entries) {
          final variableName = FundJsParsers.tencentVarName(entry.value);
          changes[entry.key] = FundJsParsers.parseTencentHoldingChange(
            entry.value,
            assignments[variableName],
          );
        }
      }

      final holdings = baseHoldings
          .map(
            (item) => FundHolding(
              code: item.code,
              name: item.name,
              weight: item.weight,
              change: changes[item.code],
            ),
          )
          .toList(growable: false);

      return _HoldingsSummary(
        holdings: holdings,
        reportDate: reportDate,
        isLastQuarter: true,
      );
    } catch (_) {
      return const _HoldingsSummary(
        holdings: [],
        reportDate: null,
        isLastQuarter: false,
      );
    }
  }
}

class _LatestNavSummary {
  const _LatestNavSummary({
    required this.dwjz,
    required this.zzl,
    required this.jzrq,
    required this.lastNav,
    required this.yesterdayZzl,
    required this.yesterdayNavDelta,
  });

  final String dwjz;
  final double? zzl;
  final String jzrq;
  final String? lastNav;
  final double? yesterdayZzl;
  final double? yesterdayNavDelta;
}

class _HoldingsSummary {
  const _HoldingsSummary({
    required this.holdings,
    required this.reportDate,
    required this.isLastQuarter,
  });

  final List<FundHolding> holdings;
  final String? reportDate;
  final bool isLastQuarter;
}
