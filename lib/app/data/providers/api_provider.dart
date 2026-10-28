import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/api_exception.dart';
import '../models/visitor_model.dart';

class ApiProvider {
  ApiProvider({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
          connectTimeout: AppConfig.apiTimeout,
          receiveTimeout: AppConfig.apiTimeout,
          sendTimeout: AppConfig.apiTimeout,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-Playground-Identity': AppConfig.playgroundIdentity,
          },
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (Object object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _guard(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _guard(() => _dio.post<dynamic>(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _guard(() => _dio.put<dynamic>(path, data: data));
  }

  Future<dynamic> delete(String path) {
    return _guard(() => _dio.delete<dynamic>(path));
  }

  Future<dynamic> _guard(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    } on ApiException {
      rethrow;
    } catch (exception) {
      throw ApiException(
        'An unexpected error occurred. Please try again.',
        cause: exception,
      );
    }
  }

  void close() => _dio.close(force: true);

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

abstract class VisitorApi {
  Future<List<Visitor>> fetchAll();

  Future<Visitor> fetchById(String id);

  Future<Visitor> create(Visitor visitor);

  Future<Visitor> update(Visitor visitor);

  Future<void> delete(String id);
}

class RemoteVisitorApi implements VisitorApi {
  const RemoteVisitorApi(this._provider);

  final ApiProvider _provider;

  @override
  Future<List<Visitor>> fetchAll() async {
    final data = await _provider.get(
      AppConfig.visitorsResource,
      queryParameters: const <String, dynamic>{'limit': 200},
    );
    final list = _extractList(data);

    return list
        .whereType<Map>()
        .map((item) => Visitor.fromJson(Map<String, dynamic>.from(item)))
        .where((visitor) => (visitor.id ?? '').isNotEmpty)
        .toList();
  }

  @override
  Future<Visitor> fetchById(String id) async {
    final data = await _provider.get(_visitorPath(id));
    return Visitor.fromJson(_extractObject(data));
  }

  @override
  Future<Visitor> create(Visitor visitor) async {
    final data = await _provider.post(
      AppConfig.visitorsResource,
      data: visitor.toJson(),
    );
    final created = Visitor.fromJson(_extractObject(data));
    if ((created.id ?? '').isEmpty) {
      throw const ApiException(
        'The server did not return a saved visitor record.',
      );
    }
    return created;
  }

  @override
  Future<Visitor> update(Visitor visitor) async {
    final id = visitor.id;
    if (id == null || id.isEmpty) {
      throw const ApiException('A visitor id is required to update a record.');
    }

    final data = await _provider.put(_visitorPath(id), data: visitor.toJson());
    if (data == null) return visitor;
    return Visitor.fromJson(_extractObject(data));
  }

  @override
  Future<void> delete(String id) async {
    await _provider.delete(_visitorPath(id));
  }

  String _visitorPath(String id) =>
      '${AppConfig.visitorsResource}/${Uri.encodeComponent(id)}';

  List<dynamic> _extractList(Object? data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in <String>['data', 'visitors', 'items', 'records']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    throw const ApiException('The server returned an unexpected response.');
  }

  Map<String, dynamic> _extractObject(Object? data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    throw const ApiException('The server returned an unexpected response.');
  }
}
