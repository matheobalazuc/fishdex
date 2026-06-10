import 'dart:convert';
import 'package:http/http.dart' as http;

class WikiService {
  static final Map<String, String?> _cache = {};

  /// Retourne l'URL de la photo Wikipedia pour une espèce latine
  static Future<String?> getFishImageUrl(String latinName) async {
    if (_cache.containsKey(latinName)) return _cache[latinName];
    try {
      final slug = Uri.encodeComponent(latinName.replaceAll(' ', '_'));
      final response = await http.get(
        Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$slug'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Préfère originalimage si dispo, sinon thumbnail
        final url = (data['originalimage']?['source'] ??
                     data['thumbnail']?['source']) as String?;
        _cache[latinName] = url;
        return url;
      }
    } catch (_) {}
    _cache[latinName] = null;
    return null;
  }
}
