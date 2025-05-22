import 'package:http/http.dart';

import '../cache_control.dart';

const String cacheControlHeader = 'Cache-Control';

extension CacheControlRequest on Request {
  CacheControl get cacheControl {
    final raw = headers[cacheControlHeader] ?? '';
    return CacheControl.parse(raw);
  }

  set cacheControl(CacheControl value) {
    headers[cacheControlHeader] = value.toString();
  }
}

extension CacheControlResponse on Response {
  CacheControl get cacheControl {
    final raw = headers[cacheControlHeader] ?? '';
    return CacheControl.parse(raw);
  }

  set cacheControl(CacheControl value) {
    headers[cacheControlHeader] = value.toString();
  }
}

extension CacheControlBaseResponse on BaseResponse {
  CacheControl get cacheControl {
    final raw = headers[cacheControlHeader] ?? '';
    return CacheControl.parse(raw);
  }

  set cacheControl(CacheControl value) {
    headers[cacheControlHeader] = value.toString();
  }
}
