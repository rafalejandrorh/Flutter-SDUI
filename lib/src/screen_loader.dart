import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'config.dart';

abstract class ScreenLoader {
  Future<Map<String, dynamic>> load(String name);
}

class AssetScreenLoader implements ScreenLoader {
  AssetScreenLoader(this.config);

  final SduiConfig config;

  @override
  Future<Map<String, dynamic>> load(String name) async {
    final path = config.resolveAssetPath(name);
    final raw = await rootBundle.loadString(path);
    return _asJsonObject(jsonDecode(raw), source: path);
  }
}

class NetworkScreenLoader implements ScreenLoader {
  NetworkScreenLoader({
    required this.config,
    required this.dio,
  });

  final SduiConfig config;
  final Dio dio;

  @override
  Future<Map<String, dynamic>> load(String name) async {
    final url = config.resolveScreenUrl(name);
    final response = await dio.get<dynamic>(url);
    return _asJsonObject(response.data, source: url);
  }
}

Map<String, dynamic> _asJsonObject(Object? data, {required String source}) {
  if (data is String) {
    data = jsonDecode(data);
  }
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw FormatException('Screen JSON must be an object ($source).');
}
