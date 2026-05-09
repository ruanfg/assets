import 'package:dio/dio.dart';

import '../../core/network/app_dio_factory.dart';
import '../../core/utils/fund_js_parsers.dart';
import '../../domain/market/market_repository.dart';
import '../../features/market/models/market_models.dart';

class TencentMarketRepository implements MarketRepository {
  TencentMarketRepository({Dio? dio}) : _dio = dio ?? AppDioFactory.create();

  final Dio _dio;

  static const List<({String code, String name})> _marketIndexKeys = [
    (code: 'sh000001', name: '上证指数'),
    (code: 'sh000016', name: '上证50'),
    (code: 'sz399001', name: '深证成指'),
    (code: 'sz399330', name: '深证100'),
    (code: 'bj899050', name: '北证50'),
    (code: 'sh000300', name: '沪深300'),
    (code: 'sz399006', name: '创业板指'),
    (code: 'sz399102', name: '创业板综'),
    (code: 'sz399673', name: '创业板50'),
    (code: 'sh000688', name: '科创50'),
    (code: 'sz399005', name: '中小100'),
    (code: 'sh000905', name: '中证500'),
    (code: 'sh000906', name: '中证800'),
    (code: 'sh000852', name: '中证1000'),
    (code: 'sh000903', name: '中证A100'),
    (code: 'sh000932', name: '500等权'),
    (code: 'sz399303', name: '国证2000'),
    (code: 'usIXIC', name: '纳斯达克'),
    (code: 'usNDX', name: '纳斯达克100'),
    (code: 'usINX', name: '标普500'),
    (code: 'usDJI', name: '道琼斯'),
    (code: 'hkHSI', name: '恒生指数'),
    (code: 'hkHSTECH', name: '恒生科技指数'),
    (code: 'gzFTSE', name: '富时100'),
    (code: 'gzFCHI', name: 'CAC40'),
    (code: 'gzGDAXI', name: '德国DAX'),
    (code: 'gzN225', name: '日经225'),
    (code: 'gzTPX', name: '东证指数'),
    (code: 'gzKS11', name: '韩国综合'),
    (code: 'gzKOSDAQ', name: '韩国创业板'),
  ];

  @override
  Future<String?> fetchShanghaiIndexDate() async {
    final response = await _dio.get<String>(
      'https://qt.gtimg.cn/q=sh000001&_t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final body = response.data ?? '';
    final assignments = FundJsParsers.parseTencentQuoteAssignments(body);
    final raw = assignments['v_sh000001'];
    if (raw == null) return null;
    final parts = raw.split('~');
    if (parts.length <= 30) return null;
    final value = parts[30];
    if (value.length < 8) return null;
    return value.substring(0, 8);
  }

  @override
  Future<List<MarketIndexQuote>> fetchMarketIndices() async {
    final codes = _marketIndexKeys.map((item) => item.code).join(',');
    final response = await _dio.get<String>(
      'https://qt.gtimg.cn/q=$codes&_t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final assignments = FundJsParsers.parseTencentQuoteAssignments(response.data ?? '');
    final result = <MarketIndexQuote>[];
    for (final item in _marketIndexKeys) {
      final variableName = 'v_${item.code}';
      final raw = assignments[variableName];
      if (raw == null) {
        result.add(
          MarketIndexQuote(
            code: item.code,
            name: item.name,
            price: 0,
            change: 0,
            changePercent: 0,
          ),
        );
        continue;
      }
      final parsed = FundJsParsers.parseTencentIndexQuote(
        code: item.code,
        fallbackName: item.name,
        rawData: raw,
      );
      result.add(
        parsed ??
            MarketIndexQuote(
              code: item.code,
              name: item.name,
              price: 0,
              change: 0,
              changePercent: 0,
            ),
      );
    }
    return result;
  }
}
