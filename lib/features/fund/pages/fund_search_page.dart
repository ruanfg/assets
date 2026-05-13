import 'package:flutter/material.dart';

import 'fund_detail_page.dart';

import '../api/eastmoney_fund_repository.dart';
import '../models/fund_models.dart';
import '../view/fund_search_bar.dart';

class FundSearchPage extends StatefulWidget {
  const FundSearchPage({super.key});

  @override
  State<FundSearchPage> createState() => _FundSearchPageState();
}

class _FundSearchPageState extends State<FundSearchPage> {
  final EastmoneyFundRepository _repository = EastmoneyFundRepository();

  List<FundSearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _keyword = '';

  Future<void> _onSearch(String keyword) async {
    final trimmed = keyword.trim();
    setState(() {
      _keyword = trimmed;
      _loading = trimmed.isNotEmpty;
      _searched = false;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    try {
      final results = await _repository.searchFunds(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索基金'), centerTitle: false),
      body: Column(
        children: [
          FundSearchBar(onSearch: _onSearch),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_searched) {
      return Center(
        child: Text(
          '输入基金名称或代码搜索',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          '未找到与 "$_keyword" 相关的基金',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _FundSearchResultItem(result: _results[index]);
      },
    );
  }
}

class _FundSearchResultItem extends StatelessWidget {
  const _FundSearchResultItem({required this.result});

  final FundSearchResult result;

  @override
  Widget build(BuildContext context) {
    final type = result.type;
    final nav = result.baseInfo?.nav;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FundDetailPage(
              code: result.code,
              name: result.name,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        result.code,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (nav != null)
              Text(
                nav.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
