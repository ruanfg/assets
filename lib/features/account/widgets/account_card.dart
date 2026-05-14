import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.isVisible = true});

  final Account account;
  final bool isVisible;

  Color get _iconColor => account.preset?.color ?? const Color(0xFF0F766E);
  String get _iconLetter =>
      account.preset?.iconLetter ?? account.name.characters.first;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAssetRow(),
            const SizedBox(height: 16),
            _buildProfitRow(
              label: '持有收益',
              value: '0.00',
              percent: '0.00%',
              isPositive: true,
            ),
            const SizedBox(height: 8),
            _buildProfitRow(
              label: '当日收益',
              value: '+0.00',
              percent: '+0.00%',
              isPositive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _iconColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            _iconLetter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            account.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        _buildArrowCount(Icons.arrow_upward, '0',
            const Color(0xFFEF4444)),
        const SizedBox(width: 6),
        _buildArrowCount(Icons.arrow_downward, '0',
            const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildArrowCount(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        Text(
          count,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAssetRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '账户资产',
              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 4),
            Text(
              isVisible ? '0.00' : '****',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(
          width: 100,
          height: 40,
          child: _buildMiniChart(),
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 4,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 5),
              FlSpot(1, 5),
              FlSpot(2, 5),
              FlSpot(3, 5),
              FlSpot(4, 5),
            ],
            isCurved: true,
            color: Colors.grey[300],
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildProfitRow({
    required String label,
    required String value,
    required String percent,
    required bool isPositive,
  }) {
    final color = isPositive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        const Spacer(),
        Text(
          isVisible ? value : '****',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isVisible ? color : const Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isVisible ? percent : '****',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isVisible ? color : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ],
    );
  }
}
