import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../config/theme.dart';
import '../providers/stock_provider.dart';
import '../models/market_insights.dart';
import '../utils/helpers.dart';
import '../widgets/market_insights_card.dart';
import '../widgets/stock_status_list.dart';

class MarketAnalysisScreen extends StatefulWidget {
  const MarketAnalysisScreen({super.key});

  @override
  State<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends State<MarketAnalysisScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMarketInsights();
  }

  Future<void> _loadMarketInsights() async {
    final provider = context.read<StockProvider>();
    await provider.loadMarketInsights();
  }

  Future<void> _refreshMarketInsights() async {
    setState(() => _isRefreshing = true);
    final provider = context.read<StockProvider>();
    await provider.loadMarketInsights();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final marketInsights = provider.marketInsights;
    final isLoading = provider.isLoadingInsights;
    final error = provider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('رؤى السوق الذكية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: !isLoading ? _refreshMarketInsights : null,
          ),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshMarketInsights,
              child: _buildBody(context, marketInsights, isLoading, error),
            ),
    );
  }

  Widget _buildBody(BuildContext context, MarketInsights? insights, bool isLoading, String? error) {
    if (isLoading) {
      return const ShimmerMarketAnalysis();
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMarketInsights,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (insights == null) {
      return const Center(child: Text('لا توجد بيانات متاحة'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MarketInsightsCard(insights: insights),
        const SizedBox(height: 24),
        const Text(
          'حالة الأسهم',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StockStatusList(stockStatuses: insights.stockStatuses),
      ],
    );
  }
}

class ShimmerMarketAnalysis extends StatelessWidget {
  const ShimmerMarketAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.background.withOpacity(0.3),
          highlightColor: Theme.of(context).colorScheme.background.withOpacity(0.4),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.background.withOpacity(0.3),
          highlightColor: Theme.of(context).colorScheme.background.withOpacity(0.4),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.background.withOpacity(0.3),
          highlightColor: Theme.of(context).colorScheme.background.withOpacity(0.4),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}