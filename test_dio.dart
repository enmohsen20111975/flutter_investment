import 'package:dio/dio.dart';

void main() {
  final dio = Dio(BaseOptions(baseUrl: 'https://invist.m2y.net/api'));
  final uri = dio.options.baseUrl + '/market/overview';
  print('Manual concat: \$uri');
  
  // Dio uses uri.resolve:
  final resolved = Uri.parse('https://invist.m2y.net/api').resolve('/market/overview');
  print('Dio resolved: \$resolved');
}
