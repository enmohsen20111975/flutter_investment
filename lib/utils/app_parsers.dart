Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, dynamicValue) => MapEntry(key.toString(), dynamicValue),
    );
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  if (value is Iterable) return value.toList();
  return const <dynamic>[];
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  return asList(value)
      .map((item) => asMap(item))
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> extractMapList(
  dynamic value, {
  List<String> preferredKeys = const <String>[],
}) {
  if (value is List || value is Iterable) {
    return asMapList(value);
  }

  final data = asMap(value);
  for (final key in preferredKeys) {
    final nestedValue = data[key];
    if (nestedValue is List || nestedValue is Iterable) {
      return asMapList(nestedValue);
    }
  }

  final nestedData = data['data'];
  if (nestedData is List || nestedData is Iterable) {
    return asMapList(nestedData);
  }

  return const <Map<String, dynamic>>[];
}

double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
