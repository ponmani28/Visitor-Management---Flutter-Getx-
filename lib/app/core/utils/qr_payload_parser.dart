import 'dart:convert';

String extractVisitorId(String rawValue) {
  var value = rawValue.trim();
  if (value.isEmpty) return value;

  final decoded = _decodeJson(value);
  if (decoded != null) return decoded;

  if (value.toLowerCase().startsWith('vms:')) {
    value = value.substring(4).trim();
    if (value.startsWith('//')) {
      value = value.substring(2);
    }
  } else if (value.toLowerCase().startsWith('visitor:')) {
    value = value.substring(8).trim();
  }

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) {
      return queryId.trim();
    }
    value = uri.pathSegments.last;
  }

  if (value.contains('?') || value.contains('&')) {
    final queryId = Uri.tryParse(
      'https://local/?$value',
    )?.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) {
      return queryId.trim();
    }
  }

  return _clean(value);
}

String? _decodeJson(String value) {
  if (!value.startsWith('{')) return null;

  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map) return null;
    final id = decoded['id'] ?? decoded['visitor_id'] ?? decoded['visitorId'];
    if (id == null) return null;
    return _clean(id.toString());
  } catch (_) {
    return null;
  }
}

String _clean(String value) {
  var result = value.trim();
  if (result.length >= 2) {
    final first = result[0];
    final last = result[result.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      result = result.substring(1, result.length - 1).trim();
    }
  }
  return Uri.decodeComponent(result);
}
