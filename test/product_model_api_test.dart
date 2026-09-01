import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:khorder/models/product_model.dart';

void main() {
  test('ProductModel.fromJson parses the real /api/products payload', () async {
    final response = await http
        .get(Uri.parse('http://127.0.0.1:8000/api/products'))
        .timeout(const Duration(seconds: 10));
    expect(response.statusCode, 200);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    expect(data, isNotEmpty, reason: 'API returned no products to parse');

    final products = data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(products, isNotEmpty);
    for (final p in products) {
      expect(p.name, isNotNull, reason: 'name should parse');
      expect(p.price, isNotNull, reason: 'price should parse from string');
      expect(p.quantity, isNotNull, reason: 'quantity should map from stock');
      expect(p.categoryId, isNotNull, reason: 'category_id should parse');
      expect(p.category, isNotNull, reason: 'category name should parse from object');
    }
  });
}