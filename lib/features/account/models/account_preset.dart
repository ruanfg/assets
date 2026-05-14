import 'package:flutter/material.dart';

class AccountPreset {
  const AccountPreset({
    required this.name,
    required this.color,
    required this.iconLetter,
  });

  final String name;
  final Color color;
  final String iconLetter;

  static const alipay = AccountPreset(
    name: '支付宝',
    color: Color(0xFF1677FF),
    iconLetter: '支',
  );
  static const tianTianFund = AccountPreset(
    name: '天天基金',
    color: Color(0xFFE53935),
    iconLetter: '天',
  );
  static const eggRollFund = AccountPreset(
    name: '蛋卷基金',
    color: Color(0xFFF9A825),
    iconLetter: '蛋',
  );
  static const tencentWealth = AccountPreset(
    name: '腾讯理财通',
    color: Color(0xFF1976D2),
    iconLetter: '理',
  );

  static const all = [alipay, tianTianFund, eggRollFund, tencentWealth];
}
