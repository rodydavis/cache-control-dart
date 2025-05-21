import 'store/base.dart';

/// A class for building and parsing `Cache-Control` HTTP headers.
///
/// This class allows you to:
/// 1. **Construct `Cache-Control` header strings** using a fluent builder pattern.
///    Set the desired directives (e.g., `maxAge`, `noCache`, `public`)
///    and then call `build()` (or use the `value` getter / `toString()`)
///    to get the formatted header string.
///
///    Example (Building a header):
///    ```dart
///    final ccBuilder = CacheControl()
///      ..public = true
///      ..maxAge = const Duration(hours: 1) // Cache for 1 hour
///      ..sharedMaxAge = const Duration(hours: 2) // Shared caches (proxies) for 2 hours
///      ..immutable = true; // Indicate the resource will not change
///    final headerString = ccBuilder.build();
///    print(headerString);
///    // Output: max-age=3600,s-maxage=7200,public,immutable (order may vary)
///    ```
///
/// 2. **Parse existing `Cache-Control` header strings** into a `CacheControl` object.
///    This allows you to easily access and inspect the directives present in the header.
///
///    Example (Parsing a header):
///    ```dart
///    final headerValue = 'max-age=600, no-cache, private';
///    final cc = CacheControl.fromString(headerValue); // or CacheControl.parse()
///
///    print(cc.maxAge);        // Output: 0:10:00.000000 (Duration object)
///    print(cc.noCache);       // Output: true
///    print(cc.private);       // Output: true
///    print(cc.mustRevalidate); // Output: null (or false if not set)
///    ```
///
/// 3. **Determine cache behavior** using helper methods like `isFresh()`, `isStale()`,
///    `needsRevalidation()`, `canServeStaleWhileRevalidate()`, and `canServeStaleIfError()`.
///    These methods help you implement caching logic based on the parsed directives.
///
///    Example (Checking freshness):
///    ```dart
///    final cc = CacheControl.fromString('max-age=3600');
///    final cachedDate = DateTime.now().subtract(const Duration(minutes: 30));
///    final now = DateTime.now();
///
///    if (cc.isFresh(cachedDate, now)) {
///      print('The cached item is still fresh!');
///    } else {
///      print('The cached item is stale.');
///    }
///    ```
///
/// The class supports common directives like `max-age`, `no-cache`, `no-store`,
/// request-specific directives like `max-stale`, `min-fresh`, `only-if-cached`,
/// and response-specific directives like `s-maxage`, `public`, `private`,
/// `must-revalidate`, `immutable`, `stale-while-revalidate`, and `stale-if-error`.
class CacheControl {
  Duration? _maxAgeDuration;
  bool? _noCacheValue;
  bool? _noStoreValue;
  bool? _noTransformValue;
  Duration? _staleIfErrorDuration;

  // Request-specific
  Duration? _maxStaleDuration;
  Duration? _minFreshDuration;
  bool? _onlyIfCachedValue;

  // Response-specific
  Duration? _sharedMaxAgeDuration;
  bool? _immutableValue;
  bool? _mustRevalidateValue;
  bool? _privateValue;
  bool? _proxyRevalidateValue;
  bool? _mustUnderstandValue;
  bool? _publicValue;
  Duration? _staleWhileRevalidateDuration;

  /// Creates a [CacheControl] from a cache-control header string.
  ///
  /// Parses the header string and sets the appropriate directives on the builder.
  static CacheControl parse(String headerValue) {
    return fromString(headerValue);
  }

  /// Creates a [CacheControl] from a cache-control header string.
  ///
  /// Parses the header string and sets the appropriate directives on the builder.
  static CacheControl fromString(String headerValue) {
    final builder = CacheControl();
    if (headerValue.isEmpty) {
      return builder;
    }

    final parts = headerValue.split(',').map((e) {
      final p = e
          .split('=')
          .map((e) => e.trim())
          .map((e) => e.toLowerCase())
          .toList();
      return (p.first, p.length > 1 ? p.last : null);
    });

    for (final part in parts) {
      final key = part.$1;
      final value = part.$2;

      switch (key) {
        case 'max-age':
          if (value != null) {
            builder.maxAge = Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 's-maxage':
          if (value != null) {
            builder.sharedMaxAge = Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 'min-fresh':
          if (value != null) {
            builder.minFresh = Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 'max-stale':
          if (value != null) {
            builder.maxStale = Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 'stale-if-error':
          if (value != null) {
            builder.staleIfError = Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 'stale-while-revalidate':
          if (value != null) {
            builder.staleWhileRevalidate =
                Duration(seconds: int.tryParse(value) ?? 0);
          }
          break;
        case 'no-cache':
          builder.noCache = true;
          break;
        case 'no-store':
          builder.noStore = true;
          break;
        case 'no-transform':
          builder.noTransform = true;
          break;
        case 'only-if-cached':
          builder.onlyIfCached = true;
          break;
        case 'immutable':
          builder.immutable = true;
          break;
        case 'must-revalidate':
          builder.mustRevalidate = true;
          break;
        case 'private':
          builder.private = true;
          break;
        case 'proxy-revalidate':
          builder.proxyRevalidate = true;
          break;
        case 'must-understand':
          builder.mustUnderstand = true;
          break;
        case 'public':
          builder.public = true;
          break;
      }
    }
    return builder;
  }

  /// Sets the `max-age` directive.
  ///
  /// Indicates that the response remains fresh until N seconds after the response is generated.
  /// Pass `null` to omit this directive.
  set maxAge(Duration? duration) {
    _maxAgeDuration = duration;
  }

  /// Gets the `max-age` value in seconds, if set.
  /// The `max-age=N` response directive indicates that the response remains fresh
  /// until N seconds after the response is generated.
  int? get maxAgeSeconds => _maxAgeDuration?.inSeconds;

  /// Gets the `max-age` value as a [Duration], if set.
  /// The `max-age=N` response directive indicates that the response remains fresh
  /// until N seconds after the response is generated.
  Duration? get maxAge => _maxAgeDuration;

  /// Sets the `no-cache` directive.
  ///
  /// If `true`, the `no-cache` directive is added.
  /// Indicates that the response can be stored in caches, but the response
  /// must be validated with the origin server before each reuse.
  /// If `false` or `null`, the directive is omitted.
  set noCache(bool? value) => _noCacheValue = value;

  /// Gets the `no-cache` value, if set.
  /// The `no-cache` response directive indicates that the response can be stored in caches,
  /// but the response must be validated with the origin server before each reuse.
  bool? get noCache => _noCacheValue;

  /// Sets the `no-store` directive.
  ///
  /// If `true`, the `no-store` directive is added.
  /// Indicates that any caches of any kind (private or shared) should not store this response.
  /// If `false` or `null`, the directive is omitted.
  set noStore(bool? value) => _noStoreValue = value;

  /// Gets the `no-store` value, if set.
  /// The `no-store` response directive indicates that any caches of any kind
  /// (private or shared) should not store this response.
  bool? get noStore => _noStoreValue;

  /// Sets the `no-transform` directive.
  ///
  /// If `true`, the `no-transform` directive is added.
  /// Indicates that any intermediary (regardless of whether it implements a cache)
  /// shouldn't transform the response contents.
  /// If `false` or `null`, the directive is omitted.
  set noTransform(bool? value) => _noTransformValue = value;

  /// Gets the `no-transform` value, if set.
  /// Indicates that any intermediary (regardless of whether it implements a cache)
  /// shouldn't transform the response contents.
  bool? get noTransform => _noTransformValue;

  /// Sets the `stale-if-error` directive.
  ///
  /// Indicates that the cache can reuse a stale response when an upstream server
  /// generates an error, or when the error is generated locally (500, 502, 503, or 504).
  /// Pass `null` to omit this directive.
  set staleIfError(Duration? duration) {
    _staleIfErrorDuration = duration;
  }

  /// Gets the `stale-if-error` value in seconds, if set.
  /// Indicates that the cache can reuse a stale response when an upstream server
  /// generates an error, or when the error is generated locally.
  int? get staleIfErrorSeconds => _staleIfErrorDuration?.inSeconds;

  /// Gets the `stale-if-error` value as a [Duration], if set.
  /// Indicates that the cache can reuse a stale response when an upstream server
  /// generates an error, or when the error is generated locally.
  Duration? get staleIfError => _staleIfErrorDuration;

  /// Sets the `no-cache` directive (for requests).
  /// This seems to be a duplicate or misnamed getter, it returns _maxAgeDuration.
  /// The `no-cache` request directive asks caches to validate the response
  /// with the origin server before reuse.
  Duration? get noCacheDuration => _maxAgeDuration;

  // Request-specific setters and methods

  /// Sets the `max-stale` directive (for requests).
  ///
  /// Indicates that the client allows a stored response that is stale within N seconds.
  /// If no N value is specified, the client will accept a stale response of any age.
  /// Pass `null` to omit this directive.
  set maxStale(Duration? duration) {
    _maxStaleDuration = duration;
  }

  /// Gets the `max-stale` value in seconds, if set.
  /// Indicates that the client allows a stored response that is stale within N seconds.
  int? get maxStaleSeconds => _maxStaleDuration?.inSeconds;

  /// Sets the `max-stale` value as a [Duration], if set.
  /// Indicates that the client allows a stored response that is stale within N seconds.
  Duration? get maxStale => _maxStaleDuration;

  /// Sets the `min-fresh` directive (for requests).
  ///
  /// Indicates that the client allows a stored response that is fresh for at least N seconds.
  /// Pass `null` to omit this directive.
  set minFresh(Duration? duration) {
    _minFreshDuration = duration;
  }

  /// Gets the `min-fresh` value in seconds, if set.
  /// Indicates that the client allows a stored response that is fresh for at least N seconds.
  int? get minFreshSeconds => _minFreshDuration?.inSeconds;

  /// Sets the `min-fresh` value as a [Duration], if set.
  /// Indicates that the client allows a stored response that is fresh for at least N seconds.
  Duration? get minFresh => _minFreshDuration;

  /// Sets the `only-if-cached` directive (for requests).
  ///
  /// If `true`, the `only-if-cached` directive is added.
  /// Indicates that an already-cached response should be returned.
  /// If a cache has a stored response, even a stale one, it will be returned.
  /// If no cached response is available, a 504 Gateway Timeout response will be returned.
  /// If `false` or `null`, the directive is omitted.
  set onlyIfCached(bool? value) => _onlyIfCachedValue = value;

  /// Gets the `only-if-cached` value, if set.
  /// Indicates that an already-cached response should be returned.
  bool? get onlyIfCached => _onlyIfCachedValue;

  // Response-specific setters and methods

  /// Sets the `s-maxage` (shared max-age) directive (for responses).
  ///
  /// Indicates how long the response remains fresh in a shared cache.
  /// Overrides `max-age` or the `Expires` header for shared caches.
  /// Pass `null` to omit this directive.
  set sharedMaxAge(Duration? duration) {
    _sharedMaxAgeDuration = duration;
  }

  /// Gets the `s-maxage` (shared max-age) value in seconds, if set.
  /// Indicates how long the response remains fresh in a shared cache.
  int? get sharedMaxAgeSeconds => _sharedMaxAgeDuration?.inSeconds;

  /// Gets the `s-maxage` (shared max-age) value as a [Duration], if set.
  /// Indicates how long the response remains fresh in a shared cache.
  Duration? get sharedMaxAge => _sharedMaxAgeDuration;

  /// Sets the `immutable` directive (for responses).
  ///
  /// If `true`, indicates the response body will not be updated while it's fresh.
  /// If `false` or `null`, the directive is omitted.
  set immutable(bool? value) => _immutableValue = value;

  /// Gets the `immutable` value, if set.
  /// Indicates that the response will not be updated while it's fresh.
  bool? get immutable => _immutableValue;

  /// Sets the `must-revalidate` directive (for responses).
  ///
  /// If `true`, indicates that the response can be stored in caches and can be reused while fresh.
  /// If the response becomes stale, it must be validated with the origin server before reuse.
  /// If `false` or `null`, the directive is omitted.
  set mustRevalidate(bool? value) => _mustRevalidateValue = value;

  /// Gets the `must-revalidate` value, if set.
  /// Indicates that the response can be stored in caches and can be reused while fresh.
  /// If the response becomes stale, it must be validated with the origin server before reuse.
  bool? get mustRevalidate => _mustRevalidateValue;

  /// Sets the `private` directive (for responses).
  ///
  /// If `true`, indicates the response can be stored only in a private cache (e.g., local caches in browsers).
  /// If `false` or `null`, the directive is omitted.
  set private(bool? value) => _privateValue = value;

  /// Gets the `private` value, if set.
  /// Indicates that the response can be stored only in a private cache.
  bool? get private => _privateValue;

  /// Sets the `proxy-revalidate` directive (for responses).
  ///
  /// Equivalent of `must-revalidate`, but specifically for shared caches only.
  /// If `true`, the `proxy-revalidate` directive is added.
  /// If `false` or `null`, the directive is omitted.
  set proxyRevalidate(bool? value) => _proxyRevalidateValue = value;

  /// Gets the `proxy-revalidate` value, if set.
  /// Equivalent of `must-revalidate`, but specifically for shared caches only.
  bool? get proxyRevalidate => _proxyRevalidateValue;

  /// Sets the `must-understand` directive (for responses).
  ///
  /// If `true`, indicates that a cache should store the response only if it
  /// understands the requirements for caching based on status code.
  /// Should be coupled with `no-store` for fallback behavior.
  /// If `false` or `null`, the directive is omitted.
  set mustUnderstand(bool? value) => _mustUnderstandValue = value;

  /// Gets the `must-understand` value, if set.
  /// Indicates that a cache should store the response only if it
  /// understands the requirements for caching based on status code.
  bool? get mustUnderstand => _mustUnderstandValue;

  /// Sets the `public` directive (for responses).
  ///
  /// If `true`, indicates the response may be cached by any cache, even if
  /// the request had an `Authorization` header or the response would normally
  /// be non-cacheable or cacheable only within a private cache.
  /// If `false` or `null`, the directive is omitted.
  set public(bool? value) => _publicValue = value;

  /// Gets the `public` value, if set.
  /// Indicates that the response can be stored in a shared cache.
  bool? get public => _publicValue;

  /// Sets the `stale-while-revalidate` directive (for responses).
  ///
  /// Indicates that the cache could reuse a stale response while it revalidates it in the background.
  /// Pass `null` to omit this directive.
  set staleWhileRevalidate(Duration? duration) {
    _staleWhileRevalidateDuration = duration;
  }

  /// Gets the `stale-while-revalidate` value in seconds, if set.
  /// Indicates that the cache could reuse a stale response while it revalidates it to a cache.
  int? get staleWhileRevalidateSeconds =>
      _staleWhileRevalidateDuration?.inSeconds;

  /// Gets the `stale-while-revalidate` value as a [Duration], if set.
  /// Indicates that the cache could reuse a stale response while it revalidates it to a cache.
  Duration? get staleWhileRevalidate => _staleWhileRevalidateDuration;

  /// Builds the Cache-Control header string from all configured directives.
  /// This method includes all common, request-specific, and response-specific
  /// directives that have been set on the builder.
  String build() {
    final parts = <String>[];
    // Common directives
    if (_maxAgeDuration != null) {
      parts.add('max-age=${_maxAgeDuration!.inSeconds}');
    }
    if (_noCacheValue == true) parts.add('no-cache');
    if (_noStoreValue == true) parts.add('no-store');
    if (_noTransformValue == true) parts.add('no-transform');
    if (_staleIfErrorDuration != null) {
      parts.add('stale-if-error=${_staleIfErrorDuration!.inSeconds}');
    }

    // Request-specific directives
    if (_maxStaleDuration != null) {
      parts.add('max-stale=${_maxStaleDuration!.inSeconds}');
    }
    if (_minFreshDuration != null) {
      parts.add('min-fresh=${_minFreshDuration!.inSeconds}');
    }
    if (_onlyIfCachedValue == true) parts.add('only-if-cached');

    // Response-specific directives
    if (_sharedMaxAgeDuration != null) {
      parts.add('s-maxage=${_sharedMaxAgeDuration!.inSeconds}');
    }
    if (_immutableValue == true) parts.add('immutable');
    if (_mustRevalidateValue == true) parts.add('must-revalidate');
    if (_privateValue == true) parts.add('private');
    if (_proxyRevalidateValue == true) parts.add('proxy-revalidate');
    if (_mustUnderstandValue == true) parts.add('must-understand');
    if (_publicValue == true) parts.add('public');
    if (_staleWhileRevalidateDuration != null) {
      parts.add(
          'stale-while-revalidate=${_staleWhileRevalidateDuration!.inSeconds}');
    }

    return parts.join(',');
  }

  String get value => build();

  @override
  String toString() {
    return build();
  }

  // Freshness and Revalidation Helpers

  Duration? _getFreshnessLifetime() {
    if (_sharedMaxAgeDuration != null) return _sharedMaxAgeDuration;
    if (_maxAgeDuration != null) return _maxAgeDuration;
    return null;
  }

  DateTime? _getExpirationTime(DateTime cachedDate) {
    final lifetime = _getFreshnessLifetime();
    if (lifetime != null) {
      return cachedDate.add(lifetime);
    }
    return null;
  }

  /// Checks if the cached item is considered fresh based on the current directives.
  ///
  /// An item is fresh if its freshness lifetime (`max-age` or `s-maxage`) has not passed,
  /// and it's not explicitly marked as `no-cache`.
  /// If `immutable` is set, it's considered fresh unless `max-age=0` (or `s-maxage=0`)
  /// or an explicit freshness lifetime has passed.
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool isFresh(DateTime cachedDate, DateTime now) {
    if (_noCacheValue == true) return false;
    if (_noStoreValue == true) return false; // Should not be in cache

    final lifetime = _getFreshnessLifetime();

    if (_immutableValue == true) {
      if (lifetime != null) {
        // e.g., max-age=0, immutable means revalidate but then it's immutable
        if (lifetime.inSeconds == 0) return false;
        return now.isBefore(cachedDate.add(lifetime));
      }
      return true; // Immutable and no explicit max-age/s-maxage
    }

    if (lifetime != null) {
      if (lifetime.inSeconds == 0) {
        return false; // max-age=0 means stale immediately
      }
      return now.isBefore(cachedDate.add(lifetime));
    }

    // No explicit freshness information (no max-age/s-maxage, not immutable)
    return false;
  }

  /// Checks if the cached item is considered stale.
  ///
  /// An item is stale if its freshness lifetime (`max-age` or `s-maxage`) has passed.
  /// If no freshness lifetime is defined and the item is not `immutable`, it's considered stale.
  /// Items with `no-store` are effectively always stale for caching purposes as they shouldn't be used.
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool isStale(DateTime cachedDate, DateTime now) {
    if (_noStoreValue == true) return true; // Not usable from cache

    final expirationTime = _getExpirationTime(cachedDate);

    if (expirationTime == null) {
      // No max-age or s-maxage.
      // If immutable, it's considered fresh indefinitely by cache-control rules.
      // Otherwise, it's stale (or relies on heuristic freshness not covered here).
      return _immutableValue != true;
    }
    // Has an expiration time, check if 'now' is at or after it.
    // DateTime.isBefore is exclusive, so !isBefore covers same moment and after.
    return !now.isBefore(expirationTime);
  }

  /// Alias for [isStale]. Checks if the cached item has expired based on its
  /// freshness lifetime.
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool isExpired(DateTime cachedDate, DateTime now) {
    return isStale(cachedDate, now);
  }

  /// Checks if a stale cached item can be served while revalidation occurs in the background.
  ///
  /// This is true if `stale-while-revalidate` is set with a positive duration,
  /// the item is currently stale, and `now` is within the `stale-while-revalidate` window
  /// (calculated from the end of its freshness lifetime, or `cachedDate` if no freshness lifetime).
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool canServeStaleWhileRevalidate(DateTime cachedDate, DateTime now) {
    if (!isStale(cachedDate, now)) return false;
    if (_staleWhileRevalidateDuration == null ||
        _staleWhileRevalidateDuration!.inSeconds <= 0) {
      return false;
    }

    final expirationTime = _getExpirationTime(cachedDate);
    // The SWR window starts after the primary freshness period ends.
    // If no primary freshness (expirationTime is null), item is stale from cachedDate.
    final baseTimeForSwr = expirationTime ?? cachedDate;
    final swrWindowEnd = baseTimeForSwr.add(_staleWhileRevalidateDuration!);

    return now.isBefore(swrWindowEnd);
  }

  /// Checks if a stale cached item can be served if an error occurs during revalidation.
  ///
  /// This is true if `stale-if-error` is set with a positive duration,
  /// the item is currently stale, and `now` is within the `stale-if-error` window
  /// (calculated from the end of its freshness lifetime, or `cachedDate` if no freshness lifetime).
  /// Note: This method only checks the time window; the actual occurrence of an error
  /// during revalidation is an external factor.
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool canServeStaleIfError(DateTime cachedDate, DateTime now) {
    if (!isStale(cachedDate, now)) return false;
    if (_staleIfErrorDuration == null ||
        _staleIfErrorDuration!.inSeconds <= 0) {
      return false;
    }

    final expirationTime = _getExpirationTime(cachedDate);
    final baseTimeForSie = expirationTime ?? cachedDate;
    final sieWindowEnd = baseTimeForSie.add(_staleIfErrorDuration!);

    return now.isBefore(sieWindowEnd);
  }

  /// Checks if the cached item needs revalidation with the origin server.
  ///
  /// Revalidation is needed if:
  /// - `no-cache` is set.
  /// - The item is stale AND (`must-revalidate` or `proxy-revalidate` is set).
  /// - The item is stale AND not `immutable` (as immutable stale items might not need revalidation
  ///   if the content is guaranteed not to change).
  ///
  /// [cachedDate]: The date and time when the item was cached or last validated.
  /// [now]: The current date and time.
  bool needsRevalidation(DateTime cachedDate, DateTime now) {
    if (_noCacheValue == true) return true;
    // If no-store is true, it shouldn't be cached, so revalidating a cached copy is moot.
    if (_noStoreValue == true) return false;

    if (isStale(cachedDate, now)) {
      if (_mustRevalidateValue == true) return true;
      // proxy-revalidate applies to shared caches. If set, it implies a need for revalidation
      // in those contexts. For a general check, consider it.
      if (_proxyRevalidateValue == true) return true;

      // According to RFC 8246 (Immutable), caches can use the 'immutable' hint
      // to avoid revalidating the response, even if it is stale.
      if (_immutableValue == true) return false;

      // If stale, and not covered by a specific rule like immutable that negates
      // the need for revalidation, then it needs revalidation.
      return true;
    }

    // If not stale, and no-cache is not set, it's considered fresh enough.
    return false;
  }

  // Static methods for CacheStore interaction

  /// Writes an item to the provided [CacheStore] using this [CacheControl] policy.
  ///
  /// - [store]: The cache store to write to.
  /// - [key]: The key for the item.
  /// - [value]: The value of the item.
  /// - [policy]: The CacheControl policy to associate with this item.
  /// - [cachedDate]: The date and time when this item is being cached or validated.
  static void writeToStore<K, V>(
    CacheStore<K, V> store,
    K key,
    V value,
    CacheControl policy,
    DateTime cachedDate,
  ) {
    if (policy.noStore == true) {
      // Do not store if no-store directive is present.
      return;
    }
    store.set(key, value, policy, cachedDate);
  }

  /// Reads an item from the [CacheStore] if it's considered usable according to its policy.
  ///
  /// Returns the value if:
  /// - The item is fresh and does not require revalidation (e.g., not `no-cache`).
  /// - The item is stale but can be served via `stale-while-revalidate`.
  /// - The item is stale, `isErrorCondition` is true, and it can be served via `stale-if-error`.
  /// Otherwise, returns `null`.
  ///
  /// - [store]: The cache store to read from.
  /// - [key]: The key of the item to retrieve.
  /// - [now]: The current date and time for freshness calculations.
  /// - [isErrorCondition]: Flag to indicate if an error condition exists (for `stale-if-error`).
  static V? readFromStore<K, V>(
    CacheStore<K, V> store,
    K key,
    DateTime now,
    {bool isErrorCondition = false,}
  ) {
    final cachedItem = store.get(key);

    if (cachedItem == null) {
      return null;
    }

    final itemPolicy = cachedItem.cacheControl;
    final itemCachedDate = cachedItem.cachedDate;

    if (itemPolicy.noStore == true) {
      // Should not have been stored, or used if it was.
      return null;
    }

    // Check for freshness first
    if (itemPolicy.isFresh(itemCachedDate, now)) {
      if (itemPolicy.noCache == true) {
        // Fresh but requires revalidation (e.g., no-cache directive).
        // HTTP spec implies it shouldn't be used without revalidation.
        return null;
      }
      // Fresh and usable.
      return cachedItem.value;
    } else {
      // Item is stale, check if it can be served stale
      if (itemPolicy.canServeStaleWhileRevalidate(itemCachedDate, now)) {
        // Caller should ideally trigger revalidation in the background.
        return cachedItem.value;
      }
      if (isErrorCondition && itemPolicy.canServeStaleIfError(itemCachedDate, now)) {
        return cachedItem.value;
      }
      // Stale and cannot be served.
      return null;
    }
  }

  /// Checks if an item in the [CacheStore] is stale.
  ///
  /// - [store]: The cache store to check.
  /// - [key]: The key of the item.
  /// - [now]: The current date and time for freshness calculations.
  /// Returns `true` if stale, `false` if fresh, `null` if not found or `no-store`.
  static bool? isItemStaleInStore<K, V>(
    CacheStore<K, V> store,
    K key,
    DateTime now,
  ) {
    final cachedItem = store.get(key);
    if (cachedItem == null || cachedItem.cacheControl.noStore == true) {
      return null;
    }
    return cachedItem.cacheControl.isStale(cachedItem.cachedDate, now);
  }

  /// Checks if an item in the [CacheStore] needs to be updated (revalidated).
  ///
  /// - [store]: The cache store to check.
  /// - [key]: The key of the item.
  /// - [now]: The current date and time for freshness calculations.
  /// Returns `true` if revalidation is needed, `false` otherwise, `null` if not found or `no-store`.
  static bool? needsItemUpdateInStore<K, V>(
    CacheStore<K, V> store,
    K key,
    DateTime now,
  ) {
    final cachedItem = store.get(key);
    if (cachedItem == null || cachedItem.cacheControl.noStore == true) {
      return null;
    }
    return cachedItem.cacheControl.needsRevalidation(cachedItem.cachedDate, now);
  }
}
