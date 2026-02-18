import 'package:t_client/src/types/method.dart';
import 'package:t_client/t_client.dart';

extension ClientRequestExtensions on TClient {
  ///
  /// ### GET request
  ///
  Future<TClientResponse> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.get,
      path,
      query: query,
      headers: headers,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### POST request
  ///
  Future<TClientResponse> post(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.post,
      path,
      body: data,
      headers: headers,
      query: query,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### PUT request
  ///
  Future<TClientResponse> put(
    String path, {
    Map<String, String>? query,
    Object? data,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.put,
      path,
      body: data,
      headers: headers,
      query: query,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### DELETE request
  ///
  Future<TClientResponse> delete(
    String path, {
    Object? data,
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.delete,
      path,
      body: data,
      headers: headers,
      query: query,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### Method[HEAD]
  ///
  Future<TClientResponse> head(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.head,
      path,
      query: query,
      headers: headers,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### Method[options]
  ///
  Future<TClientResponse> options(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.options,
      path,
      query: query,
      headers: headers,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  ///
  /// ### Method[patch]
  ///
  Future<TClientResponse> patch(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return sendRequest(
      Method.patch,
      path,
      query: query,
      headers: headers,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }
}
