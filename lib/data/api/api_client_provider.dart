/// Shared HTTP client for BYOK endpoints and the worker feed client.
library;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client_provider.g.dart';

@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
}
