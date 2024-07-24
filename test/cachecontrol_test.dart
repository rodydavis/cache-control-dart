import 'package:test/test.dart';

import 'package:cachecontrol/cachecontrol.dart';

void main() {
  group('Cache-Control', () {
    group('Request Headers', () {
      test('empty', () {
        var target = '';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
      });

      test('max-age', () {
        var target = 'max-age=1';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.maxAge, 1);

        cc = cc.copyWith(maxAge: 2);

        expect(cc.value, 'max-age=2');
        expect(cc.maxAge, 2);
      });

      test('max-stale', () {
        var target = 'max-stale=1';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.maxStale, 1);

        cc = cc.copyWith(maxStale: 2);

        expect(cc.value, 'max-stale=2');
        expect(cc.maxStale, 2);
      });

      test('min-fresh', () {
        var target = 'min-fresh=1';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.minFresh, 1);

        cc = cc.copyWith(minFresh: 2);

        expect(cc.value, 'min-fresh=2');
        expect(cc.minFresh, 2);
      });

      test('no-cache', () {
        var target = 'no-cache';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noCache, true);

        cc = cc.copyWith(noCache: false);

        expect(cc.value, '');
        expect(cc.noCache, false);
      });

      test('no-store', () {
        var target = 'no-store';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noStore, true);

        cc = cc.copyWith(noStore: false);

        expect(cc.value, '');
        expect(cc.noStore, false);
      });

      test('no-transform', () {
        var target = 'no-transform';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noTransform, true);

        cc = cc.copyWith(noTransform: false);

        expect(cc.value, '');
        expect(cc.noTransform, false);
      });

      test('only-if-cached', () {
        var target = 'only-if-cached';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.onlyIfCached, true);

        cc = cc.copyWith(onlyIfCached: false);

        expect(cc.value, '');
        expect(cc.onlyIfCached, false);
      });

      test('stale-if-error', () {
        var target = 'stale-if-error=1';
        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.staleIfError, 1);

        cc = cc.copyWith(staleIfError: 2);

        expect(cc.value, 'stale-if-error=2');
        expect(cc.staleIfError, 2);
      });

      test('formatted', () {
        var target = 'max-age=1, stale-if-Error=2,    NO-STORE,no-Cache   ';
        var actual = 'max-age=1,stale-if-error=2,no-store,no-cache';

        var cc = RequestCacheControl.parse(target);

        expect(cc.value, actual);
      });

      test('mixed', () {
        var target = 'max-age=1,stale-if-error=2,no-store,no-cache';

        var cc = RequestCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.maxAge, 1);
        expect(cc.staleIfError, 2);
        expect(cc.noCache, true);
        expect(cc.noStore, true);
      });
    });
    group('Response Headers', () {
      test('empty', () {
        var target = '';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
      });

      test('max-age', () {
        var target = 'max-age=1';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.maxAge, 1);

        cc = cc.copyWith(maxAge: 2);

        expect(cc.value, 'max-age=2');
        expect(cc.maxAge, 2);
      });

      test('s-maxage', () {
        var target = 's-maxage=1';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.sharedMaxAge, 1);

        cc = cc.copyWith(sharedMaxAge: 2);

        expect(cc.value, 's-maxage=2');
        expect(cc.sharedMaxAge, 2);
      });

      test('no-cache', () {
        var target = 'no-cache';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noCache, true);

        cc = cc.copyWith(noCache: false);

        expect(cc.value, '');
        expect(cc.noCache, false);
      });

      test('no-store', () {
        var target = 'no-store';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noStore, true);

        cc = cc.copyWith(noStore: false);

        expect(cc.value, '');
        expect(cc.noStore, false);
      });

      test('no-transform', () {
        var target = 'no-transform';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.noTransform, true);

        cc = cc.copyWith(noTransform: false);

        expect(cc.value, '');
        expect(cc.noTransform, false);
      });

      test('must-revalidate', () {
        var target = 'must-revalidate';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.mustRevalidate, true);

        cc = cc.copyWith(mustRevalidate: false);

        expect(cc.value, '');
        expect(cc.mustRevalidate, false);
      });

      test('proxy-revalidate', () {
        var target = 'proxy-revalidate';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.proxyRevalidate, true);

        cc = cc.copyWith(proxyRevalidate: false);

        expect(cc.value, '');
        expect(cc.proxyRevalidate, false);
      });

      test('must-understand', () {
        var target = 'must-understand';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.mustUnderstand, true);

        cc = cc.copyWith(mustUnderstand: false);

        expect(cc.value, '');
        expect(cc.mustUnderstand, false);
      });

      test('private', () {
        var target = 'private';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.private, true);

        cc = cc.copyWith(private: false);

        expect(cc.value, '');
        expect(cc.private, false);
      });

      test('public', () {
        var target = 'public';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.public, true);

        cc = cc.copyWith(public: false);

        expect(cc.value, '');
        expect(cc.public, false);
      });

      test('immutable', () {
        var target = 'immutable';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.immutable, true);

        cc = cc.copyWith(immutable: false);

        expect(cc.value, '');
        expect(cc.immutable, false);
      });

      test('stale-while-revalidate', () {
        var target = 'stale-while-revalidate=1';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.staleWhileRevalidate, 1);

        cc = cc.copyWith(staleWhileRevalidate: 2);

        expect(cc.value, 'stale-while-revalidate=2');
        expect(cc.staleWhileRevalidate, 2);
      });

      test('stale-if-error', () {
        var target = 'stale-if-error=1';
        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.staleIfError, 1);

        cc = cc.copyWith(staleIfError: 2);

        expect(cc.value, 'stale-if-error=2');
        expect(cc.staleIfError, 2);
      });

      test('formatted', () {
        var target = 'max-age=1, stale-if-Error=2,    NO-STORE,no-Cache   ';
        var actual = 'max-age=1,stale-if-error=2,no-store,no-cache';

        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, actual);
      });

      test('mixed', () {
        var target = 'max-age=1,stale-while-revalidate=2,no-store,no-cache';

        var cc = ResponseCacheControl.parse(target);

        expect(cc.value, target);
        expect(cc.maxAge, 1);
        expect(cc.staleWhileRevalidate, 2);
        expect(cc.noCache, true);
        expect(cc.noStore, true);
      });
    });
  });
}
