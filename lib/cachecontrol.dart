library cachecontrol;

sealed class CacheControl {
  final String _value;
  const CacheControl(this._value);

  String get value {
    return parts.map((e) => e.$2 == null ? e.$1 : '${e.$1}=${e.$2!}').join(',');
  }

  Iterable<(String, String?)> get parts {
    return _value.split(',').map((e) {
      final p = e
          .split('=')
          .map((e) => e.trim())
          .map((e) => e.toLowerCase())
          .toList();
      return (p.first, p.length > 1 ? p.last : null);
    });
  }

  int _getSeconds(String key, [bool allowBool = false]) {
    final part = parts.firstWhere(
      (e) => e.$1.toLowerCase() == key.toLowerCase(),
      orElse: () => (key, null),
    );
    final val = int.tryParse(part.$2 ?? '');
    if (val != null) return val;
    if (allowBool && _getBool(key)) return double.minPositive.toInt();
    return 0;
  }

  bool _getBool(String key) {
    return parts.any((e) => e.$1.toLowerCase() == key.toLowerCase());
  }
}

class RequestCacheControl extends CacheControl {
  RequestCacheControl copyWith({
    int? maxAge,
    int? maxStale,
    int? minFresh,
    bool? noCache,
    bool? noStore,
    bool? noTransform,
    bool? onlyIfCached,
    int? staleIfError,
  }) {
    List<(String, String?)> parts = super.parts.toList();

    void setPart((String, String?) part, {bool remove = false}) {
      if (remove) {
        parts.removeWhere((e) => e.$1 == part.$1);
      } else {
        final idx = parts.indexWhere((e) => e.$1 == part.$1);
        if (idx != -1) {
          parts[idx] = part;
        } else {
          parts.add(part);
        }
      }
    }

    if (maxAge != null) {
      setPart(('max-age', '$maxAge'));
    }
    if (maxStale != null) {
      setPart(('max-stale', '$maxStale'));
    }
    if (minFresh != null) {
      setPart(('min-fresh', '$minFresh'));
    }
    if (noCache != null) {
      setPart(('no-cache', null), remove: noCache == false);
    }
    if (noStore != null) {
      setPart(('no-store', null), remove: noStore == false);
    }
    if (noTransform != null) {
      setPart(('no-transform', null), remove: noTransform == false);
    }
    if (onlyIfCached != null) {
      setPart(('only-if-cached', null), remove: onlyIfCached == false);
    }
    if (staleIfError != null) {
      setPart(('stale-if-error', '$staleIfError'));
    }

    final result = parts
        .map((e) => e.$2 == null ? e.$1 : '${e.$1.trim()}=${e.$2!.trim()}')
        .map((e) => e.trim().toLowerCase())
        .join(',');

    return RequestCacheControl.parse(result);
  }

  const RequestCacheControl.parse(super.value);

  int get maxAge => _getSeconds('max-age');
  int get maxStale => _getSeconds('max-stale');
  int get minFresh => _getSeconds('min-fresh');
  bool get noCache => _getBool('no-cache');
  bool get noStore => _getBool('no-store');
  bool get noTransform => _getBool('no-transform');
  bool get onlyIfCached => _getBool('only-if-cached');
  int get staleIfError => _getSeconds('stale-if-error');
}

class ResponseCacheControl extends CacheControl {
  ResponseCacheControl copyWith({
    int? maxAge,
    int? sharedMaxAge,
    bool? immutable,
    bool? mustRevalidate,
    bool? noCache,
    bool? noStore,
    bool? noTransform,
    bool? private,
    bool? proxyRevalidate,
    bool? mustUnderstand,
    bool? public,
    int? staleIfError,
    int? staleWhileRevalidate,
  }) {
    List<(String, String?)> parts = super.parts.toList();

    void setPart((String, String?) part, {bool remove = false}) {
      if (remove) {
        parts.removeWhere((e) => e.$1 == part.$1);
      } else {
        final idx = parts.indexWhere((e) => e.$1 == part.$1);
        if (idx != -1) {
          parts[idx] = part;
        } else {
          parts.add(part);
        }
      }
    }

    if (maxAge != null) {
      setPart(('max-age', '$maxAge'));
    }
    if (sharedMaxAge != null) {
      setPart(('s-maxage', '$sharedMaxAge'));
    }
    if (immutable != null) {
      setPart(('immutable', null), remove: immutable == false);
    }
    if (mustRevalidate != null) {
      setPart(('must-revalidate', null), remove: mustRevalidate == false);
    }
    if (noCache != null) {
      setPart(('no-cache', null), remove: noCache == false);
    }
    if (noStore != null) {
      setPart(('no-store', null), remove: noStore == false);
    }
    if (noTransform != null) {
      setPart(('no-transform', null), remove: noTransform == false);
    }
    if (private != null) {
      setPart(('private', null), remove: private == false);
    }
    if (proxyRevalidate != null) {
      setPart(('proxy-revalidate', null), remove: proxyRevalidate == false);
    }
    if (mustUnderstand != null) {
      setPart(('must-understand', null), remove: mustUnderstand == false);
    }
    if (public != null) {
      setPart(('public', null), remove: public == false);
    }
    if (staleIfError != null) {
      setPart(('stale-if-error', '$staleIfError'));
    }
    if (staleWhileRevalidate != null) {
      setPart(('stale-while-revalidate', '$staleWhileRevalidate'));
    }

    final result = parts
        .map((e) => e.$2 == null ? e.$1 : '${e.$1.trim()}=${e.$2!.trim()}')
        .map((e) => e.trim().toLowerCase())
        .join(',');

    return ResponseCacheControl.parse(result);
  }

  const ResponseCacheControl.parse(super.value);

  int get maxAge => _getSeconds('max-age');
  int get sharedMaxAge => _getSeconds('s-maxage');
  bool get noCache => _getBool('no-cache');
  bool get noStore => _getBool('no-store');
  bool get noTransform => _getBool('no-transform');
  bool get mustRevalidate => _getBool('must-revalidate');
  bool get proxyRevalidate => _getBool('proxy-revalidate');
  bool get mustUnderstand => _getBool('must-understand');
  bool get private => _getBool('private');
  bool get public => _getBool('public');
  bool get immutable => _getBool('immutable');
  int get staleWhileRevalidate => _getSeconds('stale-while-revalidate');
  int get staleIfError => _getSeconds('stale-if-error');
}
