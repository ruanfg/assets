import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/eastmoney_fund_repository.dart';
import '../models/fund_models.dart';

class FundDetailPage extends StatefulWidget {
  const FundDetailPage({super.key, required this.code, this.name = ''});

  final String code;
  final String name;

  @override
  State<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends State<FundDetailPage> {
  final EastmoneyFundRepository _repository = EastmoneyFundRepository();

  FundQuote? _quote;
  FundPeriodReturns? _returns;
  FundHistoryResult? _history;
  RelatedSectorQuote? _sectorQuote;
  String _sectorLabel = '';

  List<FundNetValuePoint> _navRecords = const [];
  int _historyTabIndex = 0;

  bool _loading = true;
  String? _error;

  FundHistoryRange _selectedRange = FundHistoryRange.oneMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repository.fetchFundData(widget.code),
        _repository.fetchFundPeriodReturns(widget.code),
        _repository.fetchFundHistory(widget.code, range: _selectedRange),
      ]);

      if (!mounted) return;

      final quote = results[0] as FundQuote;
      final returns = results[1] as FundPeriodReturns;
      final history = results[2] as FundHistoryResult;

      RelatedSectorQuote? sectorQuote;
      String sectorLabel = '';

      try {
        final relatedSector = await _repository.fetchRelatedSectors(
          widget.code,
        );
        if (relatedSector.isNotEmpty) {
          sectorLabel = relatedSector;
          sectorQuote = await _repository.fetchRelatedSectorLiveQuote(
            relatedSector,
          );
        }
      } catch (_) {}

      if (!mounted) return;

      List<FundNetValuePoint> navRecords = const [];
      try {
        navRecords = await _repository.fetchRecentNavRecords(widget.code);
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _quote = quote;
        _returns = returns;
        _history = history;
        _sectorQuote = sectorQuote;
        _sectorLabel = sectorLabel;
        _navRecords = navRecords;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeRange(FundHistoryRange range) async {
    if (range == _selectedRange) return;
    setState(() => _selectedRange = range);

    try {
      final history = await _repository.fetchFundHistory(
        widget.code,
        range: range,
      );
      if (!mounted) return;
      setState(() => _history = history);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产详情'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('加载失败', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadData();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final quote = _quote!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildFundInfoCard(quote)),
        SliverToBoxAdapter(child: _buildChartSection()),
        SliverToBoxAdapter(child: _buildHistoryCard()),
        if (_sectorLabel.isNotEmpty)
          SliverToBoxAdapter(child: _buildRelatedSector()),
        if (quote.holdings.isNotEmpty)
          SliverToBoxAdapter(child: _buildHoldings(quote)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildFundInfoCard(FundQuote quote) {
    final growth = quote.gszzl ?? quote.zzl;
    final isPositive = (growth ?? 0) >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            quote.code,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                growth != null
                    ? '${isPositive ? '+' : ''}${growth.toStringAsFixed(2)}%'
                    : '--',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  quote.gszzl != null ? '估值涨幅' : '最新涨跌幅',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricsRow(quote),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(FundQuote quote) {
    return Row(
      children: [
        _metricItem('单位净值', quote.dwjz ?? '--'),
        _metricItem('估算净值', quote.gsz ?? '--'),
        _metricItem('昨日收益', _formatChange(quote.yesterdayZzl, suffix: '%')),
        _metricItem('净值日期', quote.jzrq ?? '--'),
      ],
    );
  }

  Widget _metricItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '业绩走势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: _buildChart()),
          const SizedBox(height: 4),
          _buildRangeSelector(),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    const ranges = [
      (FundHistoryRange.oneMonth, '近1月'),
      (FundHistoryRange.threeMonths, '近3月'),
      (FundHistoryRange.sixMonths, '近6月'),
      (FundHistoryRange.oneYear, '近1年'),
      (FundHistoryRange.threeYears, '近3年'),
      (FundHistoryRange.all, '成立来'),
    ];

    return Row(
      children: ranges.map((item) {
        final (range, label) = item;
        final selected = range == _selectedRange;
        return Expanded(
          child: GestureDetector(
            onTap: () => _changeRange(range),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF0F766E).withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF0F766E) : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    final points = _history?.points ?? const [];
    if (points.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      );
    }

    final baseValue = points.first.value;

    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final pct = (points[i].value - baseValue) / baseValue * 100;
      spots.add(FlSpot(i.toDouble(), pct));
    }

    final values = points.map((p) => (p.value - baseValue) / baseValue * 100).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    final (axisMin, axisMax, yStep) = _computeYAxisBounds(dataMin, dataMax);

    final lastValue = values.last;
    final isUp = lastValue >= 0;
    final lineColor = isUp ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    final labelIndices = _computeLabelIndices(points.length);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (!labelIndices.contains(idx)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].date,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: yStep,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: axisMin,
        maxY: axisMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.15),
                  lineColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final date = idx < points.length ? points[idx].date : '';
                return LineTooltipItem(
                  '$date\n${spot.y >= 0 ? '+' : ''}${spot.y.toStringAsFixed(2)}%',
                  const TextStyle(fontSize: 12, color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Set<int> _computeLabelIndices(int pointCount) {
    if (pointCount <= 3) {
      return List.generate(pointCount, (i) => i).toSet();
    }
    final mid = (pointCount - 1) / 2;
    return {
      0,
      mid.round(),
      pointCount - 1,
    };
  }

  (double, double, double) _computeYAxisBounds(double dataMin, double dataMax) {
    final dataRange = dataMax - dataMin;

    if (dataRange == 0) {
      final step = _niceStep((dataMin.abs() + 1) / 2);
      return (dataMin - step * 2, dataMin + step * 2, step);
    }

    // 10% padding above and below the data
    final lo = dataMin - dataRange * 0.10;
    final hi = dataMax + dataRange * 0.10;

    var step = _niceStep((hi - lo) / 4);

    for (var attempt = 0; attempt < 8; attempt++) {
      var niceLo = (lo / step).floorToDouble() * step;
      var niceHi = niceLo + 4 * step;

      // If high bound doesn't cover target, shift the 5-tick window up
      if (niceHi < hi) {
        niceLo = (hi / step).ceilToDouble() * step - 4 * step;
        niceHi = niceLo + 4 * step;
      }

      // Both bounds must cover the padded data range
      if (niceLo <= lo && niceHi >= hi) {
        return (niceLo, niceHi, step);
      }

      // Step too small to span the range with 5 ticks; try next nice step
      step = _niceStep(step * 1.6);
    }

    // Fallback
    final niceLo = (lo / step).floorToDouble() * step;
    return (niceLo, niceLo + 4 * step, step);
  }

  double _niceStep(double rough) {
    if (rough <= 0) return 1.0;

    double magnitude = 1.0;
    if (rough >= 1) {
      while (magnitude * 10 <= rough) {
        magnitude *= 10;
      }
    } else {
      while (magnitude > rough) {
        magnitude /= 10;
      }
    }

    final normalized = rough / magnitude;

    if (normalized <= 1.5) return magnitude;
    if (normalized <= 3.0) return 2 * magnitude;
    if (normalized <= 7.5) return 5 * magnitude;
    return 10 * magnitude;
  }

  Widget _buildPeriodReturnsTable() {
    final r = _returns;
    if (r == null) return const SizedBox.shrink();

    final rows = [
      ('近1周', r.week),
      ('近1月', r.month),
      ('近3月', r.month3),
      ('近6月', r.month6),
      ('近1年', r.year1),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _tableHeader('时间区间'),
              _tableHeader('涨跌幅'),
            ],
          ),
          ...rows.map((item) {
            final value = item.$2;
            return TableRow(
              children: [
                _tableCell(item.$1, const Color(0xFF333333)),
                _coloredCell(value),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoryTabs(),
          if (_historyTabIndex == 0)
            _buildPeriodReturnsTable()
          else
            _buildNavTable(),
        ],
      ),
    );
  }

  Widget _buildHistoryTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _historyTabIndex = 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '历史业绩',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _historyTabIndex == 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _historyTabIndex == 0
                        ? const Color(0xFF0F766E)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 20,
                  color: _historyTabIndex == 0
                      ? const Color(0xFF0F766E)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => setState(() => _historyTabIndex = 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '历史净值',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _historyTabIndex == 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _historyTabIndex == 1
                        ? const Color(0xFF0F766E)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 20,
                  color: _historyTabIndex == 1
                      ? const Color(0xFF0F766E)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTable() {
    final data = _navRecords;
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无数据', style: TextStyle(fontSize: 13, color: Colors.grey))),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _tableHeader('日期'),
              _tableHeader('单位净值'),
              _tableHeader('累计净值'),
              _tableHeader('日涨跌'),
            ],
          ),
          ...data.map((item) {
            return TableRow(
              children: [
                _tableCell(item.date.substring(5), const Color(0xFF333333)),
                _tableCell(item.nav.toStringAsFixed(4), const Color(0xFF333333)),
                _tableCell(
                  item.accumulatedNav != null
                      ? item.accumulatedNav!.toStringAsFixed(4)
                      : '--',
                  const Color(0xFF333333),
                ),
                _coloredCell(item.growth),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
    );
  }

  Widget _tableCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  Widget _coloredCell(double? value) {
    if (value == null) {
      return _tableCell('--', Colors.grey);
    }
    final isPositive = value >= 0;
    final text = '${isPositive ? '+' : ''}${value.toStringAsFixed(2)}%';
    final color = isPositive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return _tableCell(text, color);
  }

  Widget _buildRelatedSector() {
    final sector = _sectorQuote;
    final pct = sector?.pct;
    final isPositive = (pct ?? 0) >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '关联板块：${sector?.name ?? _sectorLabel}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          if (pct != null)
            Text(
              '${isPositive ? '+' : ''}${pct.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPositive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHoldings(FundQuote quote) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '上季度持仓${quote.holdingsReportDate != null ? ' (${quote.holdingsReportDate})' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '更多 >',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHoldingsHeader(),
          ...quote.holdings.map((h) => _buildHoldingRow(h)),
        ],
      ),
    );
  }

  Widget _buildHoldingsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              '股票名称',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '涨幅',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '持仓占比',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(FundHolding holding) {
    final change = holding.change;
    final isPositive = (change ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  holding.code,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                change != null
                    ? '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%'
                    : '--',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: change == null
                      ? Colors.grey
                      : isPositive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(holding.weight, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChange(double? value, {String suffix = ''}) {
    if (value == null) return '--';
    final isPositive = value >= 0;
    return '${isPositive ? '+' : ''}${value.toStringAsFixed(2)}$suffix';
  }
}
