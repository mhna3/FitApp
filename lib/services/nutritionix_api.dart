// lib/services/nutritionix_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;


class NutritionixApi {
  static const _baseUrl = 'trackapi.nutritionix.com';
  final String appId;
  final String appKey;
  final http.Client _client;

  NutritionixApi({
    required this.appId,
    required this.appKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-app-id': appId,
    'x-app-key': appKey,
    // optional but recommended
    'x-remote-user-id': '0',
  };

  /// 1. Natural Language for Nutrients
  /// POST /v2/natural/nutrients
  Future<Map<String, dynamic>> naturalNutrients(String query) async {
    final uri = Uri.https(_baseUrl, '/v2/natural/nutrients');
    final resp = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({ 'query': query }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch nutrients: ${resp.body}');
    }
    return jsonDecode(resp.body);
  }

  /// 2. Instant Endpoint (autocomplete)
  /// GET /v2/search/instant?query=<text>
  Future<Map<String, dynamic>> searchInstant(String query) async {
    final uri = Uri.https(_baseUrl, '/v2/search/instant', {
      'query': query,
    });
    final resp = await _client.get(uri, headers: _headers);
    if (resp.statusCode != 200) {
      throw Exception('Instant search failed: ${resp.body}');
    }
    return jsonDecode(resp.body);
  }

  /// 3. Search‐Item Endpoint (by UPC or nix_item_id)
  /// GET /v2/search/item?upc=<barcode>  or  ?nix_item_id=<id>
  Future<Map<String, dynamic>> searchItem({
    String? upc,
    String? nixItemId,
  }) async {
    assert(
    (upc != null) ^ (nixItemId != null),
    'Either upc or nixItemId must be provided, not both.',
    );
    final params = <String, String>{};
    if (upc != null) params['upc'] = upc;
    if (nixItemId != null) params['nix_item_id'] = nixItemId;

    final uri = Uri.https(_baseUrl, '/v2/search/item', params);
    final resp = await _client.get(uri, headers: _headers);
    if (resp.statusCode != 200) {
      throw Exception('Item search failed: ${resp.body}');
    }
    return jsonDecode(resp.body);
  }

  /// 4. Natural Language for Exercise
  /// POST /v2/natural/exercise
  Future<Map<String, dynamic>> naturalExercise(
      String query, {
        required String gender,
        required double weightKg,
        required double heightCm,
        required int age,
      }) async {
    final uri = Uri.https(_baseUrl, '/v2/natural/exercise');
    final body = {
      'query': query,
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age': age,
    };
    final resp = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Exercise parse failed: ${resp.body}');
    }
    return jsonDecode(resp.body);
  }
}

