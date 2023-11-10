import 'package:test/test.dart';

import 'package:cachecontrol/cachecontrol.dart';

// ignore: constant_identifier_names
const CacheControl DEFAULT_UNSET = (
  immutable: null,
  maxAge: null,
  maxStale: null,
  maxStaleDuration: null,
  minFresh: null,
  mustRevalidate: null,
  noCache: null,
  noStore: null,
  noTransform: null,
  onlyIfCached: null,
  private: null,
  proxyRevalidate: null,
  public: null,
  sharedMaxAge: null,
  staleIfError: null,
  staleWhileRevalidate: null,
);

// ignore: constant_identifier_names
const CacheControl DEFAULT_EMPTY = (
  immutable: false,
  maxAge: null,
  maxStale: false,
  maxStaleDuration: null,
  minFresh: null,
  mustRevalidate: false,
  noCache: false,
  noStore: false,
  noTransform: false,
  onlyIfCached: false,
  private: false,
  proxyRevalidate: false,
  public: false,
  sharedMaxAge: null,
  staleIfError: null,
  staleWhileRevalidate: null,
);

void main() {
  group('index', () {
    test('should return default properties by default', () {
      final cc = parse(null);
      expect(cc, DEFAULT_UNSET);
    });

    group('parse', () {
      test('should return a default instance for unset header value', () {
        final cc = parse(null);
        expect(cc, DEFAULT_UNSET);
      });

      test('should return a default instance for empty header value', () {
        final cc = parse('');
        expect(cc, DEFAULT_UNSET);
      });

      test('should not enable anything for invalid header value', () {
        final cc = parse('∂');
        expect(cc, DEFAULT_EMPTY);
      });

      test('should ignore unknown properties', () {
        final cc = parse('random-stuff=1244, hello');
        expect(cc, DEFAULT_EMPTY);
      });

      test('should parse durations', () {
        final cc = parse('max-age=4242');
        expect(cc, DEFAULT_EMPTY.copyWith(maxAge: 4242));
      });

      test('should ignore booleans with values', () {
        final cc = parse('immutable=true');
        expect(cc, DEFAULT_EMPTY);
      });

      test('should parse booleans without values', () {
        final cc = parse('immutable');
        expect(cc, DEFAULT_EMPTY.copyWith(immutable: true));
      });

      test('should support max-stale without a duration', () {
        final cc = parse('max-stale');
        expect(cc, DEFAULT_EMPTY.copyWith(maxStale: true));
      });

      test('should support max-stale with a duration', () {
        final cc = parse('max-stale=24');
        expect(
          cc,
          DEFAULT_EMPTY.copyWith(maxStale: true, maxStaleDuration: 24),
        );
      });

      test('should ignore max-stale invalid values', () {
        final cc = parse('max-stale=what');
        expect(cc, DEFAULT_EMPTY);
      });

      test('should include 0 duration values', () {
        final cc = parse(
          'max-age=0, s-maxage=0, max-stale=0, min-fresh=0, stale-while-revalidate=0, stale-if-error=0',
        );
        expect(
            cc,
            DEFAULT_EMPTY.copyWith(
              maxAge: 0,
              sharedMaxAge: 0,
              maxStaleDuration: 0,
              minFresh: 0,
              staleWhileRevalidate: 0,
              staleIfError: 0,
            ));
      });

      test('should parse common headers (1)', () {
        final cc = parse('no-cache, no-store, must-revalidate');
        expect(
            cc,
            DEFAULT_EMPTY.copyWith(
              noCache: true,
              noStore: true,
              mustRevalidate: true,
            ));
      });

      test('should parse common headers (2)', () {
        final cc = parse('public, max-age=31536000');
        expect(
            cc,
            DEFAULT_EMPTY.copyWith(
              public: true,
              maxAge: 31536000,
            ));
      });
    });
  });

  group('format', () {
    test('should return an empty string for an empty CacheControl', () {
      final cc = parse('{}').format();
      expect(cc, '');
    });

    test('should return an empty string for empty defaults', () {
      final cc = DEFAULT_EMPTY.format();
      expect(cc, '');
    });

    test('should return an empty string for a default instance', () {
      final cc = parse('').format();
      expect(cc, '');
    });

    test('should format durations', () {
      final cc = parse('')
          .copyWith(
            maxAge: 4242,
            sharedMaxAge: 4343,
            minFresh: 4444,
            staleWhileRevalidate: 4545,
            staleIfError: 4546,
          )
          .format();
      expect(
        cc,
        'max-age=4242, s-maxage=4343, min-fresh=4444, stale-while-revalidate=4545, stale-if-error=4546',
      );
    });

    test('should format booleans', () {
      final cc = parse('')
          .copyWith(
            maxStale: true,
            immutable: true,
            mustRevalidate: true,
            noCache: true,
            noStore: true,
            noTransform: true,
            onlyIfCached: true,
            private: true,
            proxyRevalidate: true,
            public: true,
          )
          .format();
      expect(
        cc,
        'max-stale, immutable, must-revalidate, no-cache, no-store, no-transform, only-if-cached, private, proxy-revalidate, public',
      );
    });

    test('should not include max-stale duration if maxStale is not true', () {
      final cc = parse('')
          .copyWith(
            maxStaleDuration: 4242,
          )
          .format();
      expect(cc, '');
    });

    test('should include max-stale duration if maxStale is true', () {
      final cc = parse('')
          .copyWith(
            maxStale: true,
            maxStaleDuration: 4242,
          )
          .format();
      expect(cc, 'max-stale=4242');
    });

    test('should include zero duration values', () {
      final cc = parse('')
          .copyWith(
            maxAge: 0,
            sharedMaxAge: 0,
            public: true,
            maxStale: true,
            maxStaleDuration: 0,
            minFresh: 0,
            staleWhileRevalidate: 0,
            staleIfError: 0,
          )
          .format();
      expect(cc, 'max-age=0, s-maxage=0, max-stale=0, min-fresh=0, public, stale-while-revalidate=0, stale-if-error=0');
    });
  });
}
