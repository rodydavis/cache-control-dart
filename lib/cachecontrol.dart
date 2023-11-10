library cachecontrol;

typedef CacheControl = ({
  int? maxAge,
  int? sharedMaxAge,
  bool? maxStale,
  int? maxStaleDuration,
  int? minFresh,
  bool? immutable,
  bool? mustRevalidate,
  bool? noCache,
  bool? noStore,
  bool? noTransform,
  bool? onlyIfCached,
  bool? private,
  bool? proxyRevalidate,
  bool? public,
  int? staleWhileRevalidate,
  int? staleIfError,
});

const _maxAge = 'max-age';
const _sharedMaxAge = 's-maxage';
const _maxStale = 'max-stale';
const _minFresh = 'min-fresh';
const _immutable = 'immutable';
const _mustRevalidate = 'must-revalidate';
const _noCache = 'no-cache';
const _noStore = 'no-store';
const _noTransform = 'no-transform';
const _onlyIfCached = 'only-if-cached';
const _private = 'private';
const _proxyRevalidate = 'proxy-revalidate';
const _public = 'public';
const _staleWhileRevalidate = 'stale-while-revalidate';
const _staleIfError = 'stale-if-error';

const _regex = r'([a-zA-Z][a-zA-Z_-]*)\s*(?:=(?:"([^"]*)"|([^ \t",;]*)))?';

bool parseBooleanOnly(Map<String, String?> values, String key) {
  if (!values.containsKey(key)) {
    return false;
  }
  return values[key] == null;
}

int? parseDuration(Map<String, String?> values, String key) {
  if (!values.containsKey(key)) {
    return null;
  }

  final value = values[key];
  if (value == null) {
    return null;
  }

  final duration = int.tryParse(value, radix: 10);

  if (duration == null || duration < 0) {
    return null;
  }

  return duration;
}

CacheControl parse(String? header) {
  if (header == null || header.trim().isEmpty) {
    return (
      maxAge: null,
      sharedMaxAge: null,
      maxStale: null,
      maxStaleDuration: null,
      minFresh: null,
      immutable: null,
      mustRevalidate: null,
      noCache: null,
      noStore: null,
      noTransform: null,
      onlyIfCached: null,
      private: null,
      proxyRevalidate: null,
      public: null,
      staleWhileRevalidate: null,
      staleIfError: null,
    );
  }

  final values = <String, String?>{};
  final headerRegex = RegExp(_regex);
  final matches = headerRegex.allMatches(header);
  for (final match in matches) {
    final tokens = match.group(0)!.split('=');
    final key = tokens[0];
    values[key.toLowerCase()] = tokens.length > 1 ? tokens[1].trim() : null;
  }

  final maxAge = parseDuration(values, _maxAge);
  final sharedMaxAge = parseDuration(values, _sharedMaxAge);

  var maxStale = parseBooleanOnly(values, _maxStale);
  final maxStaleDuration = parseDuration(values, _maxStale);
  if (maxStaleDuration != null && maxStaleDuration != 0) maxStale = true;

  final minFresh = parseDuration(values, _minFresh);

  final immutable = parseBooleanOnly(values, _immutable);
  final mustRevalidate = parseBooleanOnly(values, _mustRevalidate);
  final noCache = parseBooleanOnly(values, _noCache);
  final noStore = parseBooleanOnly(values, _noStore);
  final noTransform = parseBooleanOnly(values, _noTransform);
  final onlyIfCached = parseBooleanOnly(values, _onlyIfCached);
  final private = parseBooleanOnly(values, _private);
  final proxyRevalidate = parseBooleanOnly(values, _proxyRevalidate);
  final public = parseBooleanOnly(values, _public);
  final staleWhileRevalidate = parseDuration(values, _staleWhileRevalidate);
  final staleIfError = parseDuration(values, _staleIfError);

  return (
    maxAge: maxAge,
    sharedMaxAge: sharedMaxAge,
    maxStale: maxStale,
    maxStaleDuration: maxStaleDuration,
    minFresh: minFresh,
    immutable: immutable,
    mustRevalidate: mustRevalidate,
    noCache: noCache,
    noStore: noStore,
    noTransform: noTransform,
    onlyIfCached: onlyIfCached,
    private: private,
    proxyRevalidate: proxyRevalidate,
    public: public,
    staleWhileRevalidate: staleWhileRevalidate,
    staleIfError: staleIfError,
  );
}

extension CacheControlUtils on CacheControl {
  String format() {
    final tokens = <String>[];

    if (this.maxAge != null) {
      tokens.add('$_maxAge=${this.maxAge}');
    }

    if (this.sharedMaxAge != null) {
      tokens.add('$_sharedMaxAge=${this.sharedMaxAge}');
    }

    if (this.maxStale == true) {
      if (this.maxStaleDuration != null) {
        tokens.add('$_maxStale=${this.maxStaleDuration}');
      } else {
        tokens.add('$_maxStale');
      }
    }

    if (this.minFresh != null) {
      tokens.add('$_minFresh=${this.minFresh}');
    }

    if (this.immutable == true) {
      tokens.add('$_immutable');
    }

    if (this.mustRevalidate == true) {
      tokens.add('$_mustRevalidate');
    }

    if (this.noCache == true) {
      tokens.add('$_noCache');
    }

    if (this.noStore == true) {
      tokens.add('$_noStore');
    }

    if (this.noTransform == true) {
      tokens.add('$_noTransform');
    }

    if (this.onlyIfCached == true) {
      tokens.add('$_onlyIfCached');
    }

    if (this.private == true) {
      tokens.add('$_private');
    }

    if (this.proxyRevalidate == true) {
      tokens.add('$_proxyRevalidate');
    }

    if (this.public == true) {
      tokens.add('$_public');
    }

    if (this.staleWhileRevalidate != null) {
      tokens.add('$_staleWhileRevalidate=${this.staleWhileRevalidate}');
    }

    if (this.staleIfError != null) {
      tokens.add('$_staleIfError=${this.staleIfError}');
    }

    return tokens.join(', ');
  }

  CacheControl copyWith({
    int? maxAge,
    int? sharedMaxAge,
    bool? maxStale,
    int? maxStaleDuration,
    int? minFresh,
    bool? immutable,
    bool? mustRevalidate,
    bool? noCache,
    bool? noStore,
    bool? noTransform,
    bool? onlyIfCached,
    bool? private,
    bool? proxyRevalidate,
    bool? public,
    int? staleWhileRevalidate,
    int? staleIfError,
  }) {
    return (
      maxAge: maxAge ?? this.maxAge,
      sharedMaxAge: sharedMaxAge ?? this.sharedMaxAge,
      maxStale: maxStale ?? this.maxStale,
      maxStaleDuration: maxStaleDuration ?? this.maxStaleDuration,
      minFresh: minFresh ?? this.minFresh,
      immutable: immutable ?? this.immutable,
      mustRevalidate: mustRevalidate ?? this.mustRevalidate,
      noCache: noCache ?? this.noCache,
      noStore: noStore ?? this.noStore,
      noTransform: noTransform ?? this.noTransform,
      onlyIfCached: onlyIfCached ?? this.onlyIfCached,
      private: private ?? this.private,
      proxyRevalidate: proxyRevalidate ?? this.proxyRevalidate,
      public: public ?? this.public,
      staleWhileRevalidate: staleWhileRevalidate ?? this.staleWhileRevalidate,
      staleIfError: staleIfError ?? this.staleIfError,
    );
  }
}
