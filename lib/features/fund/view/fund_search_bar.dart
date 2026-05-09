import 'dart:async';

import 'package:flutter/material.dart';

class FundSearchBar extends StatefulWidget {
  final Function(String keyword) onSearch;
  final String hintText;

  const FundSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = "搜索基金名称或代码",
  });

  @override
  State<StatefulWidget> createState() => _FundSearchBarState();
}

class _FundSearchBarState extends State<FundSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onSearch('');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),

          const SizedBox(width: 8),

          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
              ),
            ),
          ),

          // 清除按钮
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clear,
              child: const Icon(Icons.close, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
