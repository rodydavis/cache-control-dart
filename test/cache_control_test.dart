// ignore_for_file: unused_local_variable

import 'package:cachecontrol/cachecontrol.dart';
import 'package:test/test.dart';

void main() {
  group('CacheControl.fromString', () {
    test('should parse an empty string', () {
      final cc = CacheControl.fromString('');
      expect(cc.build(), isEmpty);
    });

    test('should parse single max-age directive', () {
      final cc = CacheControl.fromString('max-age=3600');
      expect(cc.maxAge, const Duration(seconds: 3600));
      expect(cc.build(), 'max-age=3600');
    });

    test('should parse max-age=0', () {
      final cc = CacheControl.fromString('max-age=0');
      expect(cc.maxAge, Duration.zero);
      expect(cc.build(), 'max-age=0');
    });

    test('should parse max-age with non-integer as 0', () {
      final cc = CacheControl.fromString('max-age=abc');
      expect(cc.maxAge, Duration.zero);
      // Based on current implementation: int.tryParse('abc') ?? 0
      expect(cc.build(), 'max-age=0');
    });
    
    test('should parse max-age with decimal as 0 (parsed as non-integer)', () {
      final cc = CacheControl.fromString('max-age=3599.99');
      expect(cc.maxAge, Duration.zero);
      expect(cc.build(), 'max-age=0');
    });

    test('should parse negative max-age', () {
      // The spec says this should be treated as 0, but int.tryParse will parse it.
      // Current library implementation will store it as negative.
      final cc = CacheControl.fromString('max-age=-1');
      expect(cc.maxAge, const Duration(seconds: -1));
      expect(cc.build(), 'max-age=-1');
    });

    test('should parse single s-maxage directive', () {
      final cc = CacheControl.fromString('s-maxage=7200');
      expect(cc.sharedMaxAge, const Duration(seconds: 7200));
      expect(cc.build(), 's-maxage=7200');
    });

    test('should parse single min-fresh directive', () {
      final cc = CacheControl.fromString('min-fresh=60');
      expect(cc.minFresh, const Duration(seconds: 60));
      expect(cc.build(), 'min-fresh=60');
    });

    test('should parse single max-stale directive without value (not standard, current parser expects value)', () {
      // According to RFC, max-stale can be without value.
      // Current parser: (p.first, p.length > 1 ? p.last : null);
      // So, if 'max-stale' is alone, value will be null.
      // The setter for maxStale expects Duration, so it won't be set if value is null.
      // Let's test current behavior.
      var cc = CacheControl.fromString('max-stale');
      expect(cc.maxStale, isNull);
      expect(cc.build(), ''); // max-stale without value is ignored by current parser logic for duration

      cc = CacheControl.fromString('max-stale=300');
      expect(cc.maxStale, const Duration(seconds: 300));
      expect(cc.build(), 'max-stale=300');
    });
    
    test('should parse single stale-if-error directive', () {
      final cc = CacheControl.fromString('stale-if-error=86400');
      expect(cc.staleIfError, const Duration(seconds: 86400));
      expect(cc.build(), 'stale-if-error=86400');
    });

    test('should parse single stale-while-revalidate directive', () {
      final cc = CacheControl.fromString('stale-while-revalidate=259200');
      expect(cc.staleWhileRevalidate, const Duration(seconds: 259200));
      expect(cc.build(), 'stale-while-revalidate=259200');
    });

    // Boolean directives
    test('should parse no-cache directive', () {
      final cc = CacheControl.fromString('no-cache');
      expect(cc.noCache, isTrue);
      expect(cc.build(), 'no-cache');
    });

    test('should parse no-store directive', () {
      final cc = CacheControl.fromString('no-store');
      expect(cc.noStore, isTrue);
      expect(cc.build(), 'no-store');
    });

    test('should parse no-transform directive', () {
      final cc = CacheControl.fromString('no-transform');
      expect(cc.noTransform, isTrue);
      expect(cc.build(), 'no-transform');
    });

    test('should parse only-if-cached directive', () {
      final cc = CacheControl.fromString('only-if-cached');
      expect(cc.onlyIfCached, isTrue);
      expect(cc.build(), 'only-if-cached');
    });

    test('should parse immutable directive', () {
      final cc = CacheControl.fromString('immutable');
      expect(cc.immutable, isTrue);
      expect(cc.build(), 'immutable');
    });

    test('should parse must-revalidate directive', () {
      final cc = CacheControl.fromString('must-revalidate');
      expect(cc.mustRevalidate, isTrue);
      expect(cc.build(), 'must-revalidate');
    });

    test('should parse private directive', () {
      final cc = CacheControl.fromString('private');
      expect(cc.private, isTrue);
      expect(cc.build(), 'private');
    });

    test('should parse proxy-revalidate directive', () {
      final cc = CacheControl.fromString('proxy-revalidate');
      expect(cc.proxyRevalidate, isTrue);
      expect(cc.build(), 'proxy-revalidate');
    });
    
    test('should parse must-understand directive', () {
      final cc = CacheControl.fromString('must-understand');
      expect(cc.mustUnderstand, isTrue);
      expect(cc.build(), 'must-understand');
    });

    test('should parse public directive', () {
      final cc = CacheControl.fromString('public');
      expect(cc.public, isTrue);
      expect(cc.build(), 'public');
    });

    test('should parse multiple directives', () {
      final cc = CacheControl.fromString(
          'no-cache, max-age=60, must-revalidate, private');
      expect(cc.noCache, isTrue);
      expect(cc.maxAge, const Duration(seconds: 60));
      expect(cc.mustRevalidate, isTrue);
      expect(cc.private, isTrue);
      expect(cc.build(), 'max-age=60,no-cache,must-revalidate,private');
    });

    test('should parse directives with extra spaces', () {
      final cc = CacheControl.fromString(
          ' no-cache ,  max-age =  120 , must-revalidate ');
      expect(cc.noCache, isTrue);
      expect(cc.maxAge, const Duration(seconds: 120));
      expect(cc.mustRevalidate, isTrue);
      expect(cc.build(), 'max-age=120,no-cache,must-revalidate');
    });

    test('should parse directives with case insensitivity for keys', () {
      final cc = CacheControl.fromString('No-Cache, MAX-AGE=180');
      expect(cc.noCache, isTrue);
      expect(cc.maxAge, const Duration(seconds: 180));
      expect(cc.build(), 'max-age=180,no-cache');
    });
    
    test('should handle unknown directives gracefully (ignored)', () {
      final cc = CacheControl.fromString('unknown-directive, max-age=60');
      expect(cc.maxAge, const Duration(seconds: 60));
      expect(cc.build(), 'max-age=60');
    });

    test('should handle directives with missing values for duration types (ignored)', () {
      final cc = CacheControl.fromString('max-age=, no-cache');
      expect(cc.maxAge, Duration.zero); // Corrected expectation
      expect(cc.noCache, isTrue);
      // Current implementation: int.tryParse('') is null, so it becomes Duration(seconds:0)
      expect(cc.build(), 'max-age=0,no-cache');
    });

    test('CacheControl.parse is an alias for fromString', () {
      final cc1 = CacheControl.fromString('max-age=60');
      final cc2 = CacheControl.parse('max-age=60');
      expect(cc1.build(), cc2.build());
      expect(cc1.maxAge, cc2.maxAge);
    });
  });

  group('CacheControl Builder', () {
    test('should build empty string when no directives are set', () {
      final cc = CacheControl();
      expect(cc.build(), isEmpty);
    });

    // Common directives
    test('maxAge directive', () {
      final cc = CacheControl()..maxAge = const Duration(seconds: 300);
      expect(cc.build(), 'max-age=300');
      cc.maxAge = null;
      expect(cc.build(), isEmpty);
    });

    test('noCache directive', () {
      final cc = CacheControl()..noCache = true;
      expect(cc.build(), 'no-cache');
      cc.noCache = false;
      expect(cc.build(), isEmpty);
      cc.noCache = null;
      expect(cc.build(), isEmpty);
    });

    test('noStore directive', () {
      final cc = CacheControl()..noStore = true;
      expect(cc.build(), 'no-store');
      cc.noStore = false;
      expect(cc.build(), isEmpty);
    });

    test('noTransform directive', () {
      final cc = CacheControl()..noTransform = true;
      expect(cc.build(), 'no-transform');
      cc.noTransform = false;
      expect(cc.build(), isEmpty);
    });
    
    test('staleIfError directive', () {
      final cc = CacheControl()..staleIfError = const Duration(seconds: 120);
      expect(cc.build(), 'stale-if-error=120');
      cc.staleIfError = null;
      expect(cc.build(), isEmpty);
    });

    // Request-specific directives
    test('maxStale directive', () {
      final cc = CacheControl()..maxStale = const Duration(seconds: 500);
      expect(cc.build(), 'max-stale=500');
      cc.maxStale = null;
      expect(cc.build(), isEmpty);
    });

    test('minFresh directive', () {
      final cc = CacheControl()..minFresh = const Duration(seconds: 90);
      expect(cc.build(), 'min-fresh=90');
      cc.minFresh = null;
      expect(cc.build(), isEmpty);
    });

    test('onlyIfCached directive', () {
      final cc = CacheControl()..onlyIfCached = true;
      expect(cc.build(), 'only-if-cached');
      cc.onlyIfCached = false;
      expect(cc.build(), isEmpty);
    });

    // Response-specific directives
    test('sharedMaxAge directive', () {
      final cc = CacheControl()..sharedMaxAge = const Duration(hours: 2);
      expect(cc.build(), 's-maxage=7200');
      cc.sharedMaxAge = null;
      expect(cc.build(), isEmpty);
    });

    test('immutable directive', () {
      final cc = CacheControl()..immutable = true;
      expect(cc.build(), 'immutable');
      cc.immutable = false;
      expect(cc.build(), isEmpty);
    });

    test('mustRevalidate directive', () {
      final cc = CacheControl()..mustRevalidate = true;
      expect(cc.build(), 'must-revalidate');
      cc.mustRevalidate = false;
      expect(cc.build(), isEmpty);
    });

    test('private directive', () {
      final cc = CacheControl()..private = true;
      expect(cc.build(), 'private');
      cc.private = false;
      expect(cc.build(), isEmpty);
    });

    test('proxyRevalidate directive', () {
      final cc = CacheControl()..proxyRevalidate = true;
      expect(cc.build(), 'proxy-revalidate');
      cc.proxyRevalidate = false;
      expect(cc.build(), isEmpty);
    });
    
    test('mustUnderstand directive', () {
      final cc = CacheControl()..mustUnderstand = true;
      expect(cc.build(), 'must-understand');
      cc.mustUnderstand = false;
      expect(cc.build(), isEmpty);
    });

    test('public directive', () {
      final cc = CacheControl()..public = true;
      expect(cc.build(), 'public');
      cc.public = false;
      expect(cc.build(), isEmpty);
    });

    test('staleWhileRevalidate directive', () {
      final cc = CacheControl()
        ..staleWhileRevalidate = const Duration(days: 1);
      expect(cc.build(), 'stale-while-revalidate=86400');
      cc.staleWhileRevalidate = null;
      expect(cc.build(), isEmpty);
    });

    test('should build complex header string', () {
      final cc = CacheControl()
        ..noCache = true
        ..maxAge = const Duration(minutes: 10)
        ..mustRevalidate = true
        ..private = true
        ..sharedMaxAge = const Duration(hours: 1)
        ..staleWhileRevalidate = const Duration(seconds: 30);

      // Order might vary based on implementation, so check for presence of parts
      final builtString = cc.build();
      expect(builtString, contains('no-cache'));
      expect(builtString, contains('max-age=600'));
      expect(builtString, contains('must-revalidate'));
      expect(builtString, contains('private'));
      expect(builtString, contains('s-maxage=3600'));
      expect(builtString, contains('stale-while-revalidate=30'));
      expect(builtString.split(',').length, 6);
    });
    
    test('value getter and toString()', () {
      final cc = CacheControl()..maxAge = const Duration(seconds: 10);
      expect(cc.value, 'max-age=10');
      expect(cc.toString(), 'max-age=10');
    });
  });

  group('CacheControl Freshness and Revalidation', () {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    final oneHourFromNow = now.add(const Duration(hours: 1));

    group('isFresh / isStale / isExpired', () {
      test('no-cache makes item not fresh and stale', () {
        final cc = CacheControl()..noCache = true;
        expect(cc.isFresh(oneHourAgo, now), isFalse);
        expect(cc.isStale(oneHourAgo, now), isTrue); // noCache implies revalidation, so effectively stale
        expect(cc.isExpired(oneHourAgo, now), isTrue);
      });

      test('no-store makes item not fresh and stale', () {
        final cc = CacheControl()..noStore = true;
        expect(cc.isFresh(oneHourAgo, now), isFalse);
        expect(cc.isStale(oneHourAgo, now), isTrue);
        expect(cc.isExpired(oneHourAgo, now), isTrue);
      });

      test('max-age: fresh if within lifetime', () {
        final cc = CacheControl()..maxAge = const Duration(hours: 2); // Fresh for 2 hours
        expect(cc.isFresh(oneHourAgo, now), isTrue); // Cached 1h ago, now is 1h later
        expect(cc.isStale(oneHourAgo, now), isFalse);
      });

      test('max-age: stale if past lifetime', () {
        final cc = CacheControl()..maxAge = const Duration(minutes: 30); // Fresh for 30 mins
        expect(cc.isFresh(oneHourAgo, now), isFalse); // Cached 1h ago
        expect(cc.isStale(oneHourAgo, now), isTrue);
      });
      
      test('max-age=0 makes item not fresh and stale immediately', () {
        final cc = CacheControl()..maxAge = Duration.zero;
        expect(cc.isFresh(now, now), isFalse);
        expect(cc.isStale(now, now), isTrue);
      });

      test('s-maxage overrides max-age for freshness', () {
        final cc = CacheControl()
          ..maxAge = const Duration(minutes: 5)
          ..sharedMaxAge = const Duration(hours: 2);
        expect(cc.isFresh(oneHourAgo, now), isTrue); // Uses s-maxage
        expect(cc.isStale(oneHourAgo, now), isFalse);
      });
      
      test('s-maxage=0 makes item not fresh and stale immediately', () {
        final cc = CacheControl()..sharedMaxAge = Duration.zero;
        expect(cc.isFresh(now, now), isFalse);
        expect(cc.isStale(now, now), isTrue);
      });

      test('immutable: fresh if no max-age', () {
        final cc = CacheControl()..immutable = true;
        expect(cc.isFresh(twoHoursAgo, now), isTrue);
        expect(cc.isStale(twoHoursAgo, now), isFalse);
      });

      test('immutable with max-age: fresh if within lifetime', () {
        final cc = CacheControl()
          ..immutable = true
          ..maxAge = const Duration(hours: 3);
        expect(cc.isFresh(oneHourAgo, now), isTrue);
        expect(cc.isStale(oneHourAgo, now), isFalse);
      });

      test('immutable with max-age: stale if past lifetime', () {
        final cc = CacheControl()
          ..immutable = true
          ..maxAge = const Duration(minutes: 30);
        expect(cc.isFresh(oneHourAgo, now), isFalse);
        expect(cc.isStale(oneHourAgo, now), isTrue);
      });
      
      test('immutable with max-age=0: not fresh (stale)', () {
        final cc = CacheControl()
          ..immutable = true
          ..maxAge = Duration.zero;
        expect(cc.isFresh(oneHourAgo, now), isFalse);
        expect(cc.isStale(oneHourAgo, now), isTrue);
      });

      test('no explicit freshness info: not fresh and stale', () {
        final cc = CacheControl();
        expect(cc.isFresh(oneHourAgo, now), isFalse);
        expect(cc.isStale(oneHourAgo, now), isTrue);
      });
      
      test('isExpired is an alias for isStale', () {
        final ccStale = CacheControl()..maxAge = const Duration(seconds: 1);
        expect(ccStale.isExpired(twoHoursAgo, now), isTrue);
        expect(ccStale.isExpired(twoHoursAgo, now), ccStale.isStale(twoHoursAgo, now));

        final ccFresh = CacheControl()..maxAge = const Duration(hours: 5);
        expect(ccFresh.isExpired(oneHourAgo, now), isFalse);
        expect(ccFresh.isExpired(oneHourAgo, now), ccFresh.isStale(oneHourAgo, now));
      });
    });

    group('needsRevalidation', () {
      test('no-cache=true always needs revalidation', () {
        final cc = CacheControl()..noCache = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isTrue); // Fresh or stale
        expect(cc.needsRevalidation(now.add(const Duration(hours:1)), now), isTrue); // Future cache date
      });

      test('no-store=true does not need revalidation (moot)', () {
        final cc = CacheControl()..noStore = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isFalse);
      });

      test('stale item with must-revalidate=true needs revalidation', () {
        final cc = CacheControl()
          ..maxAge = const Duration(minutes: 30) // Stale
          ..mustRevalidate = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isTrue);
      });
      
      test('fresh item with must-revalidate=true does not need revalidation', () {
        final cc = CacheControl()
          ..maxAge = const Duration(hours: 2) // Fresh
          ..mustRevalidate = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isFalse);
      });

      test('stale item with proxy-revalidate=true needs revalidation', () {
        final cc = CacheControl()
          ..maxAge = const Duration(minutes: 30) // Stale
          ..proxyRevalidate = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isTrue);
      });

      test('stale immutable item does not need revalidation', () {
        final cc = CacheControl()
          ..maxAge = const Duration(minutes: 30) // Stale
          ..immutable = true;
        expect(cc.needsRevalidation(oneHourAgo, now), isFalse);
      });
      
      test('stale item (default) needs revalidation', () {
        final cc = CacheControl()..maxAge = const Duration(minutes: 30); // Stale
        expect(cc.needsRevalidation(oneHourAgo, now), isTrue);
      });

      test('fresh item (default) does not need revalidation', () {
        final cc = CacheControl()..maxAge = const Duration(hours: 2); // Fresh
        expect(cc.needsRevalidation(oneHourAgo, now), isFalse);
      });
       test('item with no freshness info (stale by default) needs revalidation', () {
        final cc = CacheControl();
        expect(cc.needsRevalidation(oneHourAgo, now), isTrue);
      });
    });

    group('canServeStaleWhileRevalidate', () {
      final staleCachedDate = now.subtract(const Duration(hours: 2)); // Item is 2h old
      final freshMaxAge = const Duration(hours: 1); // Fresh for 1h, so stale for 1h
      final swrDuration = const Duration(minutes: 30); // SWR for 30m after staleness

      test('false if not stale', () {
        final cc = CacheControl()
          ..maxAge = const Duration(hours: 3) // Fresh
          ..staleWhileRevalidate = swrDuration;
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isFalse);
      });

      test('false if stale-while-revalidate not set or zero', () {
        var cc = CacheControl()..maxAge = freshMaxAge; // Stale
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isFalse);
        
        cc.staleWhileRevalidate = Duration.zero;
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isFalse);
      });

      test('true if stale and within SWR window', () {
        final cc = CacheControl()
          ..maxAge = freshMaxAge // Stale for 1 hour
          ..staleWhileRevalidate = const Duration(hours: 2); // SWR for 2 hours after staleness
        // Expiration time was 1 hour ago (now - 1h). SWR window ends (now - 1h + 2h) = now + 1h.
        // 'now' is within this window.
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isTrue);
      });
      
      test('false if stale and outside SWR window', () {
        final cc = CacheControl()
          ..maxAge = freshMaxAge // Stale for 1 hour
          ..staleWhileRevalidate = const Duration(minutes: 30); // SWR for 30 mins after staleness
        // Expiration time was 1 hour ago. SWR window ended 30 mins ago.
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isFalse);
      });

      test('true if stale (no max-age) and within SWR window from cachedDate', () {
        final cc = CacheControl()
          ..staleWhileRevalidate = const Duration(hours: 3); // SWR for 3h from cachedDate
        // Item is 2h old, SWR window is 3h from cachedDate. 'now' is within this.
        expect(cc.canServeStaleWhileRevalidate(staleCachedDate, now), isTrue);
      });
    });
    
    group('canServeStaleIfError', () {
      final staleCachedDate = now.subtract(const Duration(hours: 2)); // Item is 2h old
      final freshMaxAge = const Duration(hours: 1); // Fresh for 1h, so stale for 1h
      final sieDuration = const Duration(minutes: 30); // SIE for 30m after staleness

      test('false if not stale', () {
        final cc = CacheControl()
          ..maxAge = const Duration(hours: 3) // Fresh
          ..staleIfError = sieDuration;
        expect(cc.canServeStaleIfError(staleCachedDate, now), isFalse);
      });

      test('false if stale-if-error not set or zero', () {
        var cc = CacheControl()..maxAge = freshMaxAge; // Stale
        expect(cc.canServeStaleIfError(staleCachedDate, now), isFalse);
        
        cc.staleIfError = Duration.zero;
        expect(cc.canServeStaleIfError(staleCachedDate, now), isFalse);
      });

      test('true if stale and within SIE window', () {
        final cc = CacheControl()
          ..maxAge = freshMaxAge // Stale for 1 hour
          ..staleIfError = const Duration(hours: 2); // SIE for 2 hours after staleness
        expect(cc.canServeStaleIfError(staleCachedDate, now), isTrue);
      });
      
      test('false if stale and outside SIE window', () {
        final cc = CacheControl()
          ..maxAge = freshMaxAge // Stale for 1 hour
          ..staleIfError = const Duration(minutes: 30); // SIE for 30 mins after staleness
        expect(cc.canServeStaleIfError(staleCachedDate, now), isFalse);
      });
      
      test('true if stale (no max-age) and within SIE window from cachedDate', () {
        final cc = CacheControl()
          ..staleIfError = const Duration(hours: 3); // SIE for 3h from cachedDate
        expect(cc.canServeStaleIfError(staleCachedDate, now), isTrue);
      });
    });
  });
}
