import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

import 'response_template.dart';

class NetworkCall {
  const NetworkCall(this.json);

  final Map<String, dynamic> json;

  factory NetworkCall.fromJson(Map<String, dynamic> json) => NetworkCall(json);
}

/// Stac `networkRequest`, plus `{{response.formatted}}` in the matching result.
///
/// Stac 1.5 runs the result action without substituting the response body.
class SduiNetworkRequestActionParser implements StacActionParser<NetworkCall> {
  const SduiNetworkRequestActionParser();

  @override
  String get actionType => 'networkRequest';

  @override
  NetworkCall getModel(Map<String, dynamic> json) => NetworkCall.fromJson(json);

  @override
  Future<Object?> onCall(BuildContext context, NetworkCall model) async {
    final request = StacNetworkRequest.fromJson(model.json);
    Response<dynamic>? response;
    try {
      response = await StacNetworkService.request(context, request);
    } on DioException catch (error) {
      response = error.response;
    }

    final statusCode = response?.statusCode;
    if (statusCode == null || !context.mounted) {
      return null;
    }

    final action = _actionForStatus(model.json['results'], statusCode);
    if (action == null) {
      return null;
    }

    final resolved = applyResponseTemplate(action, _asObject(response?.data));
    if (resolved is! Map) {
      return null;
    }

    return Stac.onCallFromJson(Map<String, dynamic>.from(resolved), context);
  }
}

Map<String, dynamic>? _actionForStatus(Object? results, int statusCode) {
  if (results is! List) {
    return null;
  }
  for (final result in results) {
    if (result is! Map) {
      continue;
    }
    if (result['statusCode'] != statusCode) {
      continue;
    }
    final action = result['action'];
    if (action is Map<String, dynamic>) {
      return action;
    }
    if (action is Map) {
      return Map<String, dynamic>.from(action);
    }
  }
  return null;
}

Object? _asObject(Object? value) => value;
