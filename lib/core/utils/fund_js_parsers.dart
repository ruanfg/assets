import 'dart:convert';

import '../../features/fund/models/fund_models.dart';
import '../../features/market/models/market_models.dart';
import 'shanghai_clock.dart';

class FundJsParsers {
  const FundJsParsers._();

  static final RegExp _dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _tbodyRowRegExp = RegExp(
    r'<tr[\s\S]*?<\/tr>',
    caseSensitive: false,
  );
  static final RegExp _tdRegExp = RegExp(
    r'<td[^>]*>(.*?)<\/td>',
    caseSensitive: false,
  );
  static final RegExp _thRegExp = RegExp(
    r'<th[\s\S]*?>([\s\S]*?)<\/th>',
    caseSensitive: false,
  );

  static Map<String, dynamic>? parseJsonpBody(String body) {
    final start = body.indexOf('(');
    final end = body.lastIndexOf(')');
    if (start == -1 || end == -1 || end <= start) return null;
    final payload = body.substring(start + 1, end).trim();
    if (payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? extractApidataContent(String source) {
    final doubleQuoteMatch = RegExp(
      r'content\s*:\s*"([\s\S]*?)"\s*(?:,\s*[A-Za-z_]+\s*:|\})',
      caseSensitive: false,
    ).firstMatch(source);
    if (doubleQuoteMatch != null) {
      return _decodeJsString(doubleQuoteMatch.group(1)!);
    }

    final singleQuoteMatch = RegExp(
      r"content\s*:\s*'([\s\S]*?)'\s*(?:,\s*[A-Za-z_]+\s*:|\})",
      caseSensitive: false,
    ).firstMatch(source);
    if (singleQuoteMatch != null) {
      return _decodeJsString(singleQuoteMatch.group(1)!);
    }
    return null;
  }

  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  static List<FundNetValuePoint> parseNetValuesFromLsjzContent(
    String? content,
  ) {
    if (content == null || content.isEmpty || content.contains('暂无数据')) {
      return const [];
    }

    final rows = _tbodyRowRegExp
        .allMatches(content)
        .map((match) => match.group(0)!)
        .toList();
    final results = <FundNetValuePoint>[];

    for (final row in rows) {
      final cells = _tdRegExp
          .allMatches(row)
          .map((match) => stripHtml(match.group(1) ?? ''))
          .toList(growable: false);
      if (cells.length < 2) continue;
      final date = cells[0];
      if (!_dateRegExp.hasMatch(date)) continue;
      final nav = double.tryParse(cells[1]);
      if (nav == null) continue;
      double? growth;
      for (final cell in cells) {
        final match = RegExp(r'([-+]?\d+(?:\.\d+)?)\s*%').firstMatch(cell);
        if (match != null) {
          growth = double.tryParse(match.group(1)!);
          break;
        }
      }
      results.add(FundNetValuePoint(date: date, nav: nav, growth: growth));
    }

    return results.reversed.toList(growable: false);
  }

  static FundYesterdayMetrics computeYesterdayNavMetrics(
    List<FundNetValuePoint> navList,
  ) {
    if (navList.length < 2) {
      return const FundYesterdayMetrics();
    }

    final prev = navList[navList.length - 2];
    double? delta;
    if (navList.length >= 3) {
      delta = prev.nav - navList[navList.length - 3].nav;
    } else if (prev.growth != null) {
      delta = prev.nav - prev.nav / (1 + (prev.growth! / 100));
    }

    return FundYesterdayMetrics(
      yesterdayZzl: prev.growth,
      yesterdayNavDelta: delta,
    );
  }

  static String? extractHoldingsReportDate(String html) {
    final primary = RegExp(
      r'(报告期|截止日期)[^0-9]{0,20}(\d{4}-\d{2}-\d{2})',
    ).firstMatch(html);
    if (primary != null) return primary.group(2);
    final fallback = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(html);
    return fallback?.group(1);
  }

  static bool isLastQuarterReport(String? reportDateStr) {
    if (reportDateStr == null || reportDateStr.isEmpty) return false;
    final report = DateTime.tryParse(reportDateStr);
    if (report == null) return false;
    final now = ShanghaiClock.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    final plusSevenDays = now.add(const Duration(days: 7));
    return report.isAfter(sixMonthsAgo) && report.isBefore(plusSevenDays);
  }

  static List<FundHolding> parseFundHoldings(
    String html, {
    Map<String, double?> quoteChanges = const {},
  }) {
    final headerRow = RegExp(
      r'<thead[\s\S]*?<tr[\s\S]*?<\/tr>[\s\S]*?<\/thead>',
      caseSensitive: false,
    ).firstMatch(html)?.group(0);
    final headerCells = headerRow == null
        ? const <String>[]
        : _thRegExp
              .allMatches(headerRow)
              .map((match) {
                return stripHtml(
                  match.group(1) ?? '',
                ).replaceAll(RegExp(r'\s+'), '');
              })
              .toList(growable: false);

    var codeIndex = -1;
    var nameIndex = -1;
    var weightIndex = -1;
    for (var index = 0; index < headerCells.length; index++) {
      final cell = headerCells[index];
      if (codeIndex < 0 && (cell.contains('股票代码') || cell.contains('证券代码'))) {
        codeIndex = index;
      }
      if (nameIndex < 0 && (cell.contains('股票名称') || cell.contains('证券名称'))) {
        nameIndex = index;
      }
      if (weightIndex < 0 && (cell.contains('占净值比例') || cell.contains('占比'))) {
        weightIndex = index;
      }
    }

    final tbody = RegExp(
      r'<tbody[\s\S]*?<\/tbody>',
      caseSensitive: false,
    ).firstMatch(html)?.group(0);
    final rows =
        (tbody == null
                ? _tbodyRowRegExp.allMatches(html)
                : _tbodyRowRegExp.allMatches(tbody))
            .map((match) => match.group(0)!)
            .toList(growable: false);

    final holdings = <FundHolding>[];
    for (final row in rows) {
      final tds = _tdRegExp
          .allMatches(row)
          .map((match) => stripHtml(match.group(1) ?? ''))
          .toList();
      if (tds.isEmpty) continue;

      var code = '';
      var name = '';
      var weight = '';

      if (codeIndex >= 0 && codeIndex < tds.length) {
        final raw = tds[codeIndex].trim();
        final ashare = RegExp(r'(\d{6})').firstMatch(raw);
        final hk = RegExp(r'(\d{5})').firstMatch(raw);
        final alpha = RegExp(r'\b([A-Za-z]{1,10})\b').firstMatch(raw);
        code =
            ashare?.group(1) ??
            hk?.group(1) ??
            alpha?.group(1)?.toUpperCase() ??
            raw;
      } else {
        code = tds.firstWhere(
          (cell) => RegExp(r'^\d{6}$').hasMatch(cell),
          orElse: () => '',
        );
      }

      if (nameIndex >= 0 && nameIndex < tds.length) {
        name = tds[nameIndex];
      } else if (code.isNotEmpty) {
        name = tds.firstWhere(
          (cell) => cell.isNotEmpty && cell != code && !cell.endsWith('%'),
          orElse: () => '',
        );
      }

      if (weightIndex >= 0 && weightIndex < tds.length) {
        final match = RegExp(r'([\d.]+)\s*%').firstMatch(tds[weightIndex]);
        weight = match == null ? tds[weightIndex] : '${match.group(1)}%';
      } else {
        final cell = tds.firstWhere(
          (value) => RegExp(r'\d+(?:\.\d+)?\s*%').hasMatch(value),
          orElse: () => '',
        );
        final match = RegExp(r'([\d.]+)\s*%').firstMatch(cell);
        weight = match == null ? '' : '${match.group(1)}%';
      }

      if (code.isEmpty && name.isEmpty && weight.isEmpty) continue;
      holdings.add(
        FundHolding(
          code: code,
          name: name,
          weight: weight,
          change: quoteChanges[code],
        ),
      );
      if (holdings.length >= 10) break;
    }

    return holdings;
  }

  static String? normalizeTencentCode(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty) return null;

    final prefixed = RegExp(
      r'^(us|hk|sh|sz|bj)(.+)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (prefixed != null) {
      final prefix = prefixed.group(1)!.toLowerCase();
      final rest = prefixed.group(2)!.trim();
      return '$prefix${RegExp(r'^\d+$').hasMatch(rest) ? rest : rest.toUpperCase()}';
    }

    final sPrefixed = RegExp(
      r'^s_(sh|sz|bj|hk)(.+)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (sPrefixed != null) {
      final prefix = sPrefixed.group(1)!.toLowerCase();
      final rest = sPrefixed.group(2)!.trim();
      return 's_$prefix${RegExp(r'^\d+$').hasMatch(rest) ? rest : rest.toUpperCase()}';
    }

    if (RegExp(r'^\d{6}$').hasMatch(raw)) {
      final prefix = raw.startsWith('6') || raw.startsWith('9')
          ? 'sh'
          : raw.startsWith('4') || raw.startsWith('8')
          ? 'bj'
          : 'sz';
      return 's_$prefix$raw';
    }

    if (RegExp(r'^\d{5}$').hasMatch(raw)) {
      return 's_hk$raw';
    }

    final hkDot = RegExp(
      r'^(\d{4,5})\.(?:HK)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (hkDot != null) {
      return 's_hk${hkDot.group(1)!.padLeft(5, '0')}';
    }

    final usDot = RegExp(
      r'^([A-Za-z]{1,10})(?:\.[A-Za-z]{1,6})$',
    ).firstMatch(raw);
    if (usDot != null) {
      return 'us${usDot.group(1)!.toUpperCase()}';
    }

    if (RegExp(r'^[A-Za-z]{1,10}$').hasMatch(raw)) {
      return 'us${raw.toUpperCase()}';
    }

    return null;
  }

  static Map<String, String> parseTencentQuoteAssignments(String source) {
    final matches = RegExp(
      r'(v_[A-Za-z0-9_]+)\s*=\s*"([\s\S]*?)";',
    ).allMatches(source);
    final result = <String, String>{};
    for (final match in matches) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  static double? parseTencentHoldingChange(
    String? tencentCode,
    String? rawData,
  ) {
    if (tencentCode == null || rawData == null || rawData.isEmpty) return null;
    final parts = rawData.split('~');
    final index = tencentCode.toLowerCase().startsWith('us') ? 32 : 5;
    if (parts.length <= index) return null;
    return double.tryParse(parts[index]);
  }

  static String tencentVarName(String tencentCode) {
    return 'v_$tencentCode';
  }

  static MarketIndexQuote? parseTencentIndexQuote({
    required String code,
    required String fallbackName,
    required String rawData,
  }) {
    final parts = rawData.split('~');
    if (code.startsWith('gz')) {
      if (parts.length < 6) return null;
      final price = double.tryParse(parts[3]);
      if (price == null) return null;
      return MarketIndexQuote(
        code: code,
        name: fallbackName,
        price: price,
        change: double.tryParse(parts[4]) ?? 0,
        changePercent: double.tryParse(parts[5]) ?? 0,
      );
    }

    if (parts.length < 33) return null;
    final price = double.tryParse(parts[3]);
    if (price == null) return null;
    return MarketIndexQuote(
      code: code,
      name: fallbackName,
      price: price,
      change: double.tryParse(parts[31]) ?? 0,
      changePercent: double.tryParse(parts[32]) ?? 0,
    );
  }

  static Map<String, dynamic> parsePingzhongdataScript(
    String source,
    List<String> keys,
    String fundCode,
  ) {
    final output = <String, dynamic>{};
    for (final key in keys) {
      final expression = _extractAssignedExpression(source, key);
      if (expression == null) continue;
      output[key] = _parseLooseJsLiteral(expression);
    }
    output['fundCode'] = (output['fS_code'] as String?) ?? fundCode;
    output['fundName'] = (output['fS_name'] as String?) ?? '';
    return output;
  }

  static double? parsePingzhongSylNumber(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().replaceAll('%', '').trim();
    return double.tryParse(value);
  }

  static double? computeWeekReturnFromNetWorthTrend(List<dynamic>? trend) {
    if (trend == null || trend.length < 2) return null;
    final valid =
        trend
            .whereType<Map>()
            .map(
              (item) => (
                x: item['x'] is num
                    ? (item['x'] as num).toDouble()
                    : double.nan,
                y: item['y'] is num
                    ? (item['y'] as num).toDouble()
                    : double.nan,
              ),
            )
            .where((point) => point.x.isFinite && point.y.isFinite)
            .toList()
          ..sort((left, right) => left.x.compareTo(right.x));

    if (valid.length < 2) return null;
    final latest = valid.last;
    if (latest.y == 0) return null;
    final cutoff = latest.x - const Duration(days: 7).inMilliseconds;

    var before = valid.first;
    for (final point in valid) {
      if (point.x <= cutoff) {
        before = point;
      } else {
        break;
      }
    }
    if (before.y == 0) return null;
    return ((latest.y - before.y) / before.y) * 100;
  }

  static List<FundHistoryPoint> parseFundHistory({
    required Map<String, dynamic> pingzhongdata,
    required FundHistoryRange range,
  }) {
    final trend = (pingzhongdata['Data_netWorthTrend'] as List?) ?? const [];
    if (trend.isEmpty) return const [];

    final now = ShanghaiClock.now();
    DateTime start = now;
    switch (range) {
      case FundHistoryRange.oneMonth:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case FundHistoryRange.threeMonths:
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case FundHistoryRange.sixMonths:
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case FundHistoryRange.oneYear:
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      case FundHistoryRange.threeYears:
        start = DateTime(now.year - 3, now.month, now.day);
        break;
      case FundHistoryRange.all:
        start = DateTime.fromMillisecondsSinceEpoch(0);
        break;
    }

    final startMs = DateTime(
      start.year,
      start.month,
      start.day,
    ).millisecondsSinceEpoch;
    final endMs = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    final valid =
        trend
            .whereType<Map>()
            .map(
              (item) => (
                x: item['x'] is num ? (item['x'] as num).toInt() : null,
                y: item['y'] is num ? (item['y'] as num).toDouble() : null,
              ),
            )
            .where(
              (item) => item.x != null && item.y != null && item.x! <= endMs,
            )
            .toList()
          ..sort((left, right) => left.x!.compareTo(right.x!));

    if (valid.isEmpty) return const [];

    final startDayEndMs = startMs + const Duration(days: 1).inMilliseconds - 1;
    final hasPointOnStartDay = valid.any(
      (item) => item.x! >= startMs && item.x! <= startDayEndMs,
    );
    var effectiveStartMs = startMs;
    if (!hasPointOnStartDay) {
      final previous = valid.where((item) => item.x! < startMs);
      if (previous.isNotEmpty) {
        effectiveStartMs = previous.last.x!;
      }
    }

    return valid
        .where((item) => item.x! >= effectiveStartMs && item.x! <= endMs)
        .map((item) {
          final date = DateTime.fromMillisecondsSinceEpoch(item.x!);
          return FundHistoryPoint(
            date: ShanghaiClock.formatDate(date),
            value: item.y!,
          );
        })
        .toList(growable: false);
  }

  static List<FundGrandTotalSeries> parseGrandTotalSeries({
    required Map<String, dynamic> pingzhongdata,
    required FundHistoryRange range,
  }) {
    final source = pingzhongdata['Data_grandTotal'];
    if (source is! List) return const [];

    final now = ShanghaiClock.now();
    DateTime start = now;
    switch (range) {
      case FundHistoryRange.oneMonth:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case FundHistoryRange.threeMonths:
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case FundHistoryRange.sixMonths:
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case FundHistoryRange.oneYear:
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      case FundHistoryRange.threeYears:
        start = DateTime(now.year - 3, now.month, now.day);
        break;
      case FundHistoryRange.all:
        start = DateTime.fromMillisecondsSinceEpoch(0);
        break;
    }

    final startMs = DateTime(
      start.year,
      start.month,
      start.day,
    ).millisecondsSinceEpoch;
    final endMs = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    final result = <FundGrandTotalSeries>[];
    for (final item in source.whereType<Map>()) {
      final name = item['name']?.toString() ?? '';
      final rawPoints = item['data'];
      if (rawPoints is! List) continue;
      final points = <FundGrandTotalPoint>[];
      for (final row in rawPoints.whereType<List>()) {
        if (row.length < 2) continue;
        final ts = row[0] is num ? (row[0] as num).toInt() : null;
        final value = row[1] is num ? (row[1] as num).toDouble() : null;
        if (ts == null || value == null) continue;
        if (ts < startMs || ts > endMs) continue;
        points.add(
          FundGrandTotalPoint(
            timestamp: ts,
            date: ShanghaiClock.formatDate(
              DateTime.fromMillisecondsSinceEpoch(ts),
            ),
            value: value,
          ),
        );
      }
      if (points.isEmpty) continue;
      result.add(FundGrandTotalSeries(name: name, points: points));
    }
    return result;
  }

  static String _decodeJsString(String raw) {
    return raw
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\/', '/')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');
  }

  static String? _extractAssignedExpression(
    String source,
    String variableName,
  ) {
    final match = RegExp(
      '(?:var\\s+)?$variableName\\s*=\\s*([\\s\\S]*?);',
      caseSensitive: false,
    ).firstMatch(source);
    return match?.group(1)?.trim();
  }

  static dynamic _parseLooseJsLiteral(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == 'null') return null;
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return jsonDecode(trimmed);
    }
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    final number = double.tryParse(trimmed);
    if (number != null) {
      return trimmed.contains('.') ? number : number.toInt();
    }
    return trimmed;
  }
}
