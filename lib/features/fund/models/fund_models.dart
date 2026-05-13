import 'dart:convert';

class RelatedSectorQuote {
  const RelatedSectorQuote({
    required this.name,
    required this.code,
    required this.pct,
  });

  final String name;
  final String code;
  final double? pct;
}

class FundNetValuePoint {
  const FundNetValuePoint({
    required this.date,
    required this.nav,
    required this.growth,
    this.accumulatedNav,
  });

  final String date;
  final double nav;
  final double? growth;
  final double? accumulatedNav;
}

class SmartFundNetValue {
  const SmartFundNetValue({required this.date, required this.value});

  final String date;
  final double value;
}

class FundHolding {
  const FundHolding({
    required this.code,
    required this.name,
    required this.weight,
    required this.change,
  });

  final String code;
  final String name;
  final String weight;
  final double? change;

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'weight': weight, 'change': change};
  }
}

class FundYesterdayMetrics {
  const FundYesterdayMetrics({this.yesterdayZzl, this.yesterdayNavDelta});

  final double? yesterdayZzl;
  final double? yesterdayNavDelta;
}

class FundQuote {
  const FundQuote({
    required this.code,
    required this.name,
    required this.dwjz,
    required this.gsz,
    required this.gztime,
    required this.jzrq,
    required this.gszzl,
    required this.zzl,
    required this.lastNav,
    required this.yesterdayZzl,
    required this.yesterdayNavDelta,
    required this.noValuation,
    required this.holdings,
    required this.holdingsReportDate,
    required this.holdingsIsLastQuarter,
  });

  final String code;
  final String name;
  final String? dwjz;
  final String? gsz;
  final String? gztime;
  final String? jzrq;
  final double? gszzl;
  final double? zzl;
  final String? lastNav;
  final double? yesterdayZzl;
  final double? yesterdayNavDelta;
  final bool noValuation;
  final List<FundHolding> holdings;
  final String? holdingsReportDate;
  final bool holdingsIsLastQuarter;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'dwjz': dwjz,
      'gsz': gsz,
      'gztime': gztime,
      'jzrq': jzrq,
      'gszzl': gszzl,
      'zzl': zzl,
      'lastNav': lastNav,
      'yesterdayZzl': yesterdayZzl,
      'yesterdayNavDelta': yesterdayNavDelta,
      'noValuation': noValuation,
      'holdings': holdings.map((e) => e.toJson()).toList(),
      'holdingsReportDate': holdingsReportDate,
      'holdingsIsLastQuarter': holdingsIsLastQuarter,
    };
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class FundBaseInfo {
  const FundBaseInfo({
    required this.shortName,
    required this.company,
    required this.manager,
    required this.fundType,
    required this.minPurchase,
    required this.navDate,
    required this.nav,
  });

  final String shortName;
  final String company;
  final String manager;
  final String fundType;
  final double? minPurchase;
  final String? navDate;
  final double? nav;

  factory FundBaseInfo.fromMap(Map<String, dynamic>? map) {
    return FundBaseInfo(
      shortName: map?['SHORTNAME']?.toString() ?? '',
      company: map?['JJGS']?.toString() ?? '',
      manager: map?['JJJL']?.toString() ?? '',
      fundType: map?['FTYPE']?.toString() ?? '',
      minPurchase: _toDouble(map?['MINSG']),
      navDate: map?['FSRQ']?.toString(),
      nav: _toDouble(map?['DWJZ']),
    );
  }
}

class FundSearchResult {
  const FundSearchResult({
    required this.code,
    required this.name,
    required this.jp,
    required this.category,
    required this.categoryDesc,
    required this.highlight,
    required this.baseInfo,
    required this.raw,
  });

  final String code;
  final String name;
  final String jp;
  final int? category;
  final String categoryDesc;
  final String highlight;
  final FundBaseInfo? baseInfo;
  final Map<String, dynamic> raw;

  String get type => baseInfo?.fundType ?? raw['TYPE']?.toString() ?? '';

  factory FundSearchResult.fromMap(Map<String, dynamic> map) {
    return FundSearchResult(
      code: map['CODE']?.toString() ?? '',
      name: map['NAME']?.toString() ?? '',
      jp: map['JP']?.toString() ?? '',
      category: map['CATEGORY'] is num
          ? (map['CATEGORY'] as num).toInt()
          : int.tryParse('${map['CATEGORY']}'),
      categoryDesc: map['CATEGORYDESC']?.toString() ?? '',
      highlight: map['HIGHTLIGHT']?.toString() ?? '',
      baseInfo: map['FundBaseInfo'] is Map<String, dynamic>
          ? FundBaseInfo.fromMap(map['FundBaseInfo'] as Map<String, dynamic>)
          : null,
      raw: map,
    );
  }
}

class FundPeriodReturns {
  const FundPeriodReturns({
    required this.week,
    required this.month,
    required this.month3,
    required this.month6,
    required this.year1,
  });

  final double? week;
  final double? month;
  final double? month3;
  final double? month6;
  final double? year1;
}

class PingzhongData {
  const PingzhongData(this.raw);

  final Map<String, dynamic> raw;

  String get fundCode => raw['fundCode']?.toString() ?? '';
  String get fundName => raw['fundName']?.toString() ?? '';
  List<dynamic>? get netWorthTrend =>
      raw['Data_netWorthTrend'] as List<dynamic>?;
}

enum FundHistoryRange {
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  threeYears,
  all,
}

extension FundHistoryRangeValue on FundHistoryRange {
  String get wireValue {
    switch (this) {
      case FundHistoryRange.oneMonth:
        return '1m';
      case FundHistoryRange.threeMonths:
        return '3m';
      case FundHistoryRange.sixMonths:
        return '6m';
      case FundHistoryRange.oneYear:
        return '1y';
      case FundHistoryRange.threeYears:
        return '3y';
      case FundHistoryRange.all:
        return 'all';
    }
  }
}

class FundAnnualReturn {
  const FundAnnualReturn({
    required this.year,
    required this.fundReturn,
    required this.categoryAvg,
    required this.hs300,
  });

  final int year;
  final double? fundReturn;
  final double? categoryAvg;
  final double? hs300;
}

class FundHistoryPoint {
  const FundHistoryPoint({required this.date, required this.value});

  final String date;
  final double value;
}

class FundGrandTotalPoint {
  const FundGrandTotalPoint({
    required this.timestamp,
    required this.date,
    required this.value,
  });

  final int timestamp;
  final String date;
  final double value;
}

class FundGrandTotalSeries {
  const FundGrandTotalSeries({required this.name, required this.points});

  final String name;
  final List<FundGrandTotalPoint> points;
}

class FundHistoryResult {
  const FundHistoryResult({
    required this.points,
    required this.grandTotalSeries,
  });

  final List<FundHistoryPoint> points;
  final List<FundGrandTotalSeries> grandTotalSeries;
}

class FundTextParseResult {
  const FundTextParseResult({required this.rawJson, required this.items});

  final String rawJson;
  final List<Map<String, dynamic>> items;

  factory FundTextParseResult.fromItems(List<Map<String, dynamic>> items) {
    return FundTextParseResult(rawJson: jsonEncode(items), items: items);
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
