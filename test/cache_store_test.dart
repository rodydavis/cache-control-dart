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

    setUp(() {
      store = InMemoryCacheStore<String, String>();
    });

    group('set and get', () {
      test('should store and retrieve an item', () async {
        await store.set(testKey, testValue, testPolicy, now);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, testValue);
        expect(item.cacheControl.maxAge, const Duration(seconds: 60));
        expect(item.cachedDate, now);
      });

      test('set with no-store policy should not store the item', () async {
        await store.set(testKey, testValue, noStorePolicy, now);
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('set with no-store should remove existing item', () async {
        await store.set(testKey, testValue, testPolicy, now); // Store it first
        var item = await store.get(testKey);
        expect(item, isNotNull);

        await store.set(
            testKey, 'newValue', noStorePolicy, now); // Now set with no-store
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
        // Set an item initially that would be valid
        await store.set(testKey, testValue, testPolicy, now);
        // Directly manipulate the internal entries to simulate an item that was stored with no-store
        // This is to test the safeguard in the get() method.
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
        await store.set(testKey, testValue, testPolicy, now);
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
        await store.set('key1', 'value1', testPolicy, now);
        await store.set('key2', 'value2', testPolicy, now);
        await store.clear();
        expect(await store.get('key1'), isNull);
        expect(await store.get('key2'), isNull);
        expect(store.entries.isEmpty, isTrue);
      });
    });

    group('getOrUpdateValue', () {
      final freshPolicy = CacheControl()..maxAge = const Duration(hours: 1);
      final stalePolicy = CacheControl()
        ..maxAge = const Duration(seconds: -1); // Already stale
      final factoryNewValue = 'factoryValue';
      final factoryNewPolicy = CacheControl()
        ..maxAge = const Duration(minutes: 30);

      Future<(String, CacheControl)> updateFactory(
          {String value = 'factoryValue', CacheControl? policy}) async {
        await Future.delayed(Duration.zero); // Simulate async
        return (value, policy ?? factoryNewPolicy);
      }

      test(
          'item not in cache: factory is called, item is stored, value is returned',
          () async {
        final result =
            await store.getOrUpdateValue(testKey, now, () => updateFactory());

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
        final result = await store.getOrUpdateValue(
            testKey, now, () => updateFactory(policy: noStorePolicy));

        expect(result, factoryNewValue);
        final item = await store.get(testKey);
        expect(item, isNull);
      });

      test('item in cache and fresh: factory NOT called, cached value returned',
          () async {
        await store.set(testKey, testValue, freshPolicy, now);
        bool factoryCalled = false;

        final result = await store
            .getOrUpdateValue(testKey, now.add(const Duration(minutes: 1)), () {
          factoryCalled = true;
          return updateFactory();
        });

        expect(result, testValue);
        expect(factoryCalled, isFalse);
      });

      test(
          'item in cache and stale: factory IS called, item updated, new value returned',
          () async {
        await store.set(
            testKey,
            testValue,
            stalePolicy,
            now.subtract(const Duration(
                seconds: 1))); // cached 1 sec ago, policy makes it stale
        bool factoryCalled = false;

        final result = await store.getOrUpdateValue(testKey, now, () {
          factoryCalled = true;
          return updateFactory(value: 'updatedViaFactory');
        });

        expect(result, 'updatedViaFactory');
        expect(factoryCalled, isTrue);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, 'updatedViaFactory');
        expect(item.cacheControl.maxAge,
            factoryNewPolicy.maxAge); // Policy updated from factory
        expect(item.cachedDate, now); // Cached date updated
      });

      test(
          'item in cache and stale, factory returns no-store: factory called, item removed',
          () async {
        await store.set(testKey, testValue, stalePolicy,
            now.subtract(const Duration(seconds: 1)));
        bool factoryCalled = false;

        final result = await store.getOrUpdateValue(testKey, now, () {
          factoryCalled = true;
          return updateFactory(policy: noStorePolicy);
        });

        expect(result, factoryNewValue); // Factory value is returned
        expect(factoryCalled, isTrue);
        final item = await store.get(testKey); // Should be removed due to no-store
        expect(item, isNull);
      });

      test('getOrUpdateValue with synchronous factory', () async {
        final syncFactoryValue = 'syncFactoryValue';
        final syncFactoryPolicy = CacheControl()
          ..maxAge = const Duration(minutes: 5);

        final result = await store.getOrUpdateValue(testKey, now, () {
          return (syncFactoryValue, syncFactoryPolicy);
        });

        expect(result, syncFactoryValue);
        final item = await store.get(testKey);
        expect(item, isNotNull);
        expect(item!.value, syncFactoryValue);
        expect(item.cacheControl.maxAge, syncFactoryPolicy.maxAge);
      });
    });
  });
}
