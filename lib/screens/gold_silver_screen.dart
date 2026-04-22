import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/gold_price.dart';
import '../services/gold_service.dart';
import '../utils/helpers.dart';

class GoldSilverScreen extends StatefulWidget {
  const GoldSilverScreen({super.key});

  @override
  State<GoldSilverScreen> createState() => _GoldSilverScreenState();
}

class _GoldSilverScreenState extends State<GoldSilverScreen> {
  final GoldService _goldService = GoldService();

  GoldPrice? _goldPrice;
  SilverPrice? _silverPrice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gold = await _goldService.getGoldPrice();
      final goldPerGram = await _goldService.getGoldPricePerGramEgp();
      final silver = await _goldService.getSilverPrice();
      final silverPerGram = await _goldService.getSilverPricePerGramEgp();

      setState(() {
        _goldPrice = GoldPrice(
          price: gold.price,
          priceEgp: goldPerGram,
          change: gold.change,
          changePercent: gold.changePercent,
          unit: 'oz',
          lastUpdated: DateTime.now(),
        );
        _silverPrice = SilverPrice(
          price: silver.price,
          priceEgp: silverPerGram,
          change: silver.change,
          changePercent: silver.changePercent,
          unit: 'oz',
          lastUpdated: DateTime.now(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل الأسعار. حاول مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('أسعار الذهب والفضة'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? _buildShimmerLoading()
            : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _fetchPrices,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildGoldCard(),
                        const SizedBox(height: 16),
                        _buildSilverCard(),
                        const SizedBox(height: 16),
                        _buildExchangeRateCard(),
                        const SizedBox(height: 16),
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _shimmerCard(height: 280),
        const SizedBox(height: 16),
        _shimmerCard(height: 220),
        const SizedBox(height: 16),
        _shimmerCard(height: 100),
      ],
    );
  }

  Widget _shimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPrices,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldCard() {
    final gold = _goldPrice!;
    final pricePerGram = gold.priceEgp;
    final pricePerOunce = gold.price;
    final changeColor = gold.change >= 0 ? AppTheme.gain : AppTheme.loss;
    final changeSign = gold.change >= 0 ? '+' : '';
    final k24 = pricePerGram;
    final k21 = pricePerGram * 21 / 24;
    final k18 = pricePerGram * 18 / 24;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFECB3),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFFD54F).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'الذهب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B6B00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price per ounce
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatNumber(pricePerOunce),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B6B00),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ج.م / أونصة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B6B00).withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Price per gram
          Text(
            '${Helpers.formatNumber(pricePerGram)} ج.م / جرام',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7B6B00).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),

          // Change row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  gold.change >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '$changeSign${Helpers.formatNumber(gold.change)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($changeSign${Helpers.formatPercentage(gold.changePercent)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Carat breakdown
          const Divider(color: Color(0xFFFFD54F), thickness: 1),
          const SizedBox(height: 12),
          const Text(
            'أسعار العيارات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B6B00),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCaratChip('24 عيار', k24, Colors.amber.shade700),
              const SizedBox(width: 10),
              _buildCaratChip('21 عيار', k21, Colors.amber.shade600),
              const SizedBox(width: 10),
              _buildCaratChip('18 عيار', k18, Colors.amber.shade500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaratChip(String label, double price, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Helpers.formatNumber(price)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'ج.م',
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverCard() {
    final silver = _silverPrice!;
    final changeColor = silver.change >= 0 ? AppTheme.gain : AppTheme.loss;
    final changeSign = silver.change >= 0 ? '+' : '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'الفضة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price per ounce
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatNumber(silver.price),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ج.م / أونصة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242).withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Price per gram
          Text(
            '${Helpers.formatNumber(silver.priceEgp)} ج.م / جرام',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),

          // Change row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  silver.change >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '$changeSign${Helpers.formatNumber(silver.change)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($changeSign${Helpers.formatPercentage(silver.changePercent)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_exchange,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'سعر صرف الدولار',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'USD / EGP',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '💵',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'دولار أمريكي',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'تم التحديث من السوق العالمي',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'يتم تحديث أسعار الذهب والفضة من السوق العالمي بشكل دوري. الأسعار المعروضة تقريبية وقد تختلف قليلاً عن أسعار السوق المحلي بسبب الفروق في الأتعاب والضرائب.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.85),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
