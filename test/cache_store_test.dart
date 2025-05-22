import 'package:cachecontrol/cachecontrol.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCacheStore', () {
    late InMemoryCacheStore<String, String> store;
    final testKey = 'testKey';
    final testValue = 'testValue';
    final testPolicy = CacheControl()..maxAge = const Duration(seconds: 60);
    final noStorePolicy = CacheControl()..noStore = true;
    final now = DateTime.now();

    CachedItem<String> createItem({
      CacheControl? policy,
      String? value,
      DateTime? now,
    }) {
      return CachedItem<String>(
          value ?? testValue, policy ?? testPolicy, now ?? DateTime.now());
    }

    setUp(() {
      store = InMemoryCacheStore<String, String>();
    });

    group('set and get', () {
      test('should store and retrieve an item', () async {
        await store.set(testKey, createItem(policy: testPolicy, now: now));
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, testValue);
        expect(item.cacheControl.maxAge, const Duration(seconds: 60));
        expect(item.cachedDate, now);
      });

      test('set with no-store policy should not store the item', () async {
        await store.set(testKey, createItem(policy: noStorePolicy, now: now));
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('set with no-store should remove existing item', () async {
        await store.set(testKey, createItem(policy: testPolicy, now: now));
        var item = await store.get(testKey);
        expect(item, isNotNull);

        await store.set(
            testKey,
            createItem(
              policy: noStorePolicy,
              value: 'newValue',
              now: now,
            ));
        item = await store.get(testKey);
        expect(item, isNull);
      });

      test('get should return null for non-existent key', () async {
        final item = await store.get('nonExistentKey');
        expect(item, isNull);
      });

      test(
          'get should return null and remove item if it has no-store policy (safeguard)',
          () async {
        await store.set(testKey, createItem(policy: testPolicy, now: now));
        store.entries[testKey] = CachedItem(testValue, noStorePolicy, now);

        final item = await store.get(testKey);
        expect(item, isNull,
            reason: "Item with no-store should be returned as null by get()");
        expect(store.entries.containsKey(testKey), isFalse,
            reason: "Item with no-store should be removed by get()");
      });
    });

    group('remove', () {
      test('should remove an existing item', () async {
        await store.set(testKey, createItem(now: now));
        await store.remove(testKey);
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('remove should do nothing for non-existent key', () async {
        await store.remove('nonExistentKey');
      });
    });

    group('clear', () {
      test('should remove all items from the store', () async {
        await store.set(
            'key1', createItem(value: 'value1', policy: testPolicy, now: now));
        await store.set(
            'key2', createItem(value: 'value2', policy: testPolicy, now: now));
        await store.clear();
        expect(await store.get('key1'), isNull);
        expect(await store.get('key2'), isNull);
        expect(store.entries.isEmpty, isTrue);
      });
    });

    group('fetch', () {
      final freshPolicy = CacheControl()..maxAge = const Duration(hours: 1);
      final stalePolicy = CacheControl()..maxAge = const Duration(seconds: -1);
      final factoryNewValue = 'factoryValue';
      final factoryNewPolicy = CacheControl()
        ..maxAge = const Duration(minutes: 30);

      Future<CachedItem<String>> updateFactory({
        String value = 'factoryValue',
        CacheControl? policy,
        required DateTime dateTime,
      }) async {
        await Future.delayed(Duration.zero);
        return CachedItem(value, policy ?? factoryNewPolicy, dateTime);
      }

      test(
          'item not in cache: factory is called, item is stored, value is returned',
          () async {
        final result = await store
            .fetch(
              testKey,
              () => updateFactory(dateTime: now),
              now,
            )
            .last;

        expect(result, factoryNewValue);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, factoryNewValue);
        expect(item.cacheControl.maxAge, factoryNewPolicy.maxAge);
        expect(item.cachedDate, now);
      });

      test(
          'item not in cache, factory policy is no-store: factory called, item NOT stored',
          () async {
        final result = await store
            .fetch(
              testKey,
              () => updateFactory(policy: noStorePolicy, dateTime: now),
              now,
            )
            .last;

        expect(result, factoryNewValue);
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('item in cache and fresh: factory NOT called, cached value returned',
          () async {
        final itemNow = now.subtract(const Duration(seconds: 1));
        await store.set(testKey,
            createItem(value: testValue, policy: freshPolicy, now: itemNow));
        bool factoryCalled = false;

        final result = await store.fetch(testKey, () {
          factoryCalled = true;
          return updateFactory(dateTime: now.add(const Duration(minutes: 1)));
        }, now.add(const Duration(minutes: 1))).last;

        expect(result, testValue);
        expect(factoryCalled, isFalse);
      });

      test(
          'item in cache and stale: factory IS called, item updated, new value returned',
          () async {
        final itemCreationTime = now.subtract(const Duration(seconds: 100));
        await store.set(
            testKey,
            createItem(
                value: testValue, policy: stalePolicy, now: itemCreationTime));
        bool factoryCalled = false;
        final callTime = now;

        final result = await store.fetch(testKey, () {
          factoryCalled = true;
          return updateFactory(value: 'updatedViaFactory', dateTime: callTime);
        }, callTime).last;

        expect(result, 'updatedViaFactory');
        expect(factoryCalled, isTrue);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, 'updatedViaFactory');
        expect(item.cacheControl.maxAge, factoryNewPolicy.maxAge);
        expect(item.cachedDate, callTime);
      });

      test(
          'item in cache and stale, factory returns no-store: factory called, item removed',
          () async {
        await store.set(
          testKey,
          createItem(
              value: testValue,
              policy: stalePolicy,
              now: now.subtract(const Duration(seconds: 1))),
        );
        bool factoryCalled = false;
        final callTime = now;

        final result = await store.fetch(testKey, () {
          factoryCalled = true;
          return updateFactory(policy: noStorePolicy, dateTime: callTime);
        }, callTime).last;

        expect(result, factoryNewValue);
        expect(factoryCalled, isTrue);
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('fetch with synchronous factory', () async {
        final syncFactoryValue = 'syncFactoryValue';
        final syncFactoryPolicy = CacheControl()
          ..maxAge = const Duration(minutes: 5);
        final callTime = now;

        final result = await store.fetch(testKey, () {
          return CachedItem(syncFactoryValue, syncFactoryPolicy, callTime);
        }, callTime).last;

        expect(result, syncFactoryValue);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, syncFactoryValue);
        expect(item.cacheControl.maxAge, syncFactoryPolicy.maxAge);
      });
    });
  });
}
