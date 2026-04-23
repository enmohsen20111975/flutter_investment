import 'dart:convert';
import 'dart:io';
import 'lib/models/market_data.dart';
import 'lib/models/stock.dart';

void main() async {
  try {
    final overviewFile = File('C:/Users/DELL/.gemini/antigravity/brain/966026aa-ef66-4160-8b37-65653a306bdc/.system_generated/steps/120/content.md');
    final overviewContent = overviewFile.readAsStringSync().split('\n---\n\n').last;
    final overviewJson = jsonDecode(overviewContent);
    final summary = MarketSummary.fromJson(overviewJson);
    print('MarketSummary parsed successfully. Gainers: ${summary.gainers}');
  } catch (e, stack) {
    print('Error parsing MarketSummary: $e\n$stack');
  }

  try {
    final stocksFile = File('C:/Users/DELL/.gemini/antigravity/brain/966026aa-ef66-4160-8b37-65653a306bdc/.system_generated/steps/131/content.md');
    final stocksContent = stocksFile.readAsStringSync().split('\n---\n\n').last;
    final stocksJson = jsonDecode(stocksContent);
    final stocks = (stocksJson['stocks'] as List).map((e) => Stock.fromJson(e)).toList();
    print('Stocks parsed successfully. Count: ${stocks.length}');
  } catch (e, stack) {
    print('Error parsing Stocks: $e\n$stack');
  }
}
