import 'package:flutter/material.dart';

class AssetsApp extends StatelessWidget {
  const AssetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const _AppHomePage(),
    );
  }
}

class _AppHomePage extends StatelessWidget {
  const _AppHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fund API Migration')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Flutter-side fund, market and settings repositories are ready under lib/data and lib/domain.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
