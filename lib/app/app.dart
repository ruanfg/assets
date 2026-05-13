import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AssetsApp extends StatelessWidget {
  const AssetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: DividerThemeData(
          space: 1,
          thickness: 1,
          color: Colors.grey[200],
        ),
      ),
      home: const _AppHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppHomePage extends StatefulWidget {
  const _AppHomePage();

  @override
  State<_AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<_AppHomePage> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assets',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            tooltip: 'Search',
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildHomePageBody(),
    );
  }

  Widget _buildHomePageBody() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              _buildGreetingSection(),
              const SizedBox(height: 24),

              // Total accounts summary card
              _buildAccountsSummaryCard(),
              const SizedBox(height: 20),

              // Quick actions section
              _buildQuickActionsSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '今日资产概览',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '我的总资产',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isVisible ? '¥ 1,234,567.89' : '****',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: 120, height: 100, child: _buildMiniChart()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildProfitItem(
                    label: '昨日收益',
                    value: '+¥ 1,234.56',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildProfitItem(
                    label: '本年收益',
                    value: '+¥ 56,789.12',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildProfitItem(
                    label: '收益率',
                    value: '+8.52%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 1000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 50),
              FlSpot(1, 60),
              FlSpot(2, -70),
              FlSpot(3, -65),
              FlSpot(4, -80),
              FlSpot(5, 90),
              FlSpot(6, 85),
              FlSpot(7, 70),
              FlSpot(8, 60),
              FlSpot(9, 75),
              FlSpot(10, 80),
            ],
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.2),
                  const Color(0xFF10B981).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildProfitItem({
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 4),
        Text(
          _isVisible ? value : '****',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isPositive
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildAddAccountCard(),
      ],
    );
  }

  Widget _buildAddAccountCard() {
    return InkWell(
      onTap: () {
        // TODO: Implement add account functionality
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  size: 28,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '新增账户',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '添加新的账户记录',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}
