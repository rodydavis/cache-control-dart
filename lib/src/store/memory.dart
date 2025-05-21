import 'dart:async';

import 'package:meta/meta.dart';

import '../cache_control.dart';
import 'base.dart';

/// An in-memory implementation of [CacheStore].
class InMemoryCacheStore<K, V> extends CacheStore<K, V> {
  @visibleForTesting
  final Map<K, CachedItem<V>> entries =
      {}; // Renamed from _entries and made visible for testing

  @override
  FutureOr<void> set(K key, V value, CacheControl cacheControl, DateTime cachedDate) {
    void save() {
      entries[key] = CachedItem(value, cacheControl, cachedDate);
    }

    // Respect the no-store directive of the policy being applied.
    // Also, if the policy marks the content as private, and this cache is not explicitly
    // a private cache (which InMemoryCacheStore isn't by default), it should not store it.
    if (cacheControl.noStore == true) {
      entries.remove(key);
    } else {
      save();
    }
  }

  @override
  FutureOr<CachedItem<V>?> get(K key) {
    final item = entries[key];
    // Ensure that items with no-store are not returned as if they are cached.
    // They should ideally not be in entries if set was called with no-store=true.
    // This is a safeguard.
    if (item != null && item.cacheControl.noStore == true) {
      entries.remove(key);
      return null;
    }
    return item;
  }

  @override
  FutureOr<void> remove(K key) {
    entries.remove(key);
  }

  @override
  FutureOr<void> clear() {
    entries.clear();
  }

  @override
  FutureOr<void> removeExpired(DateTime now) {
    entries.removeWhere((key, item) {
      return item.cacheControl.isStale(item.cachedDate, now);
    });
  }

  @override
  FutureOr<V?> getOrUpdateValue(
    K key,
    DateTime now,
    FutureOr<(V, CacheControl)> Function() updateValueFactory,
  ) async {
    CachedItem<V>? cachedItem = await get(key); // `get` now handles no-store check

    if (cachedItem == null) {
      // Item not in cache (or was no-store), fetch, store, and return
      final (V newValue, CacheControl newPolicy) = await updateValueFactory();
      // `set` will handle newPolicy.noStore
      await set(key, newValue, newPolicy, now);
      // If newPolicy.noStore was true, `set` would have removed it (or not stored it),
      // so we return the freshly generated value but it won't be cached as per its policy.
      return newValue;
    } else {
      // Item exists in cache and is not no-store
      // Check if stale using its own CacheControl policy
      if (cachedItem.cacheControl.isStale(cachedItem.cachedDate, now)) {
        // Item is stale, fetch new value and its policy
        final (V newValue, CacheControl newPolicy) = await updateValueFactory();
        // Update the item in the store with the new value, new policy, and current time.
        // `set` will handle newPolicy.noStore
        await set(key, newValue, newPolicy, now);
        return newValue;
      } else {
        // Item is fresh, return its value
        return cachedItem.value;
      }
    }
  }
}
