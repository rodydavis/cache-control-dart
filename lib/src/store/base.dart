import 'dart:async';

import '../cache_control.dart';

/// Represents an item stored in the cache, including its value,
/// the CacheControl policy it was stored with, and the date it was cached.
class CachedItem<V> {
  V value;
  CacheControl cacheControl;
  DateTime cachedDate;

  CachedItem(this.value, this.cacheControl, this.cachedDate);
}

/// Abstract interface for a cache store.
abstract class CacheStore<K, V> {
  const CacheStore();

  /// Stores an item in the cache.
  ///
  /// [key]: The key to identify the item.
  /// [value]: The value of the item.
  /// [cacheControl]: The CacheControl policy associated with this item.
  /// [cachedDate]: The date and time when this item is being cached or validated.
  FutureOr<void> set(K key, CachedItem<V> value);

  /// Retrieves a cached item from the store.
  ///
  /// Returns the [CachedItem] if found, otherwise null.
  FutureOr<CachedItem<V>?> get(K key);

  /// Removes an item from the cache.
  FutureOr<void> remove(K key);

  /// Clears all items from the cache.
  FutureOr<void> clear();

  /// Removes all expired (stale) items from the cache.
  ///
  /// - [now]: The current DateTime, used to determine which items are stale.
  FutureOr<void> removeExpired([DateTime? now]);

  /// Retrieves an item's value from the cache. If the item is missing or stale,
  /// it uses the [updateValueFactory] to generate a new value and its associated
  /// [CacheControl] policy, stores it, and then returns the value.
  ///
  /// - [key]: The key of the item to retrieve or update.
  /// - [now]: The current DateTime, used for staleness calculations.
  /// - [updateValueFactory]: A callback function that produces the new value
  ///   and its [CacheControl] policy (possibly asynchronously) if the item
  ///   is not found or is stale.
  ///
  /// Returns the fresh value, either from the cache or from the factory.
  Stream<V> fetch(
    K key,
    FutureOr<CachedItem<V>> Function() updateValueFactory, [
    DateTime? now,
  ]) async* {
    now ??= DateTime.now();
    // `get` now handles no-store check
    CachedItem<V>? cachedItem = await get(key);

    if (cachedItem == null) {
      // Item not in cache (or was no-store), fetch, store, and return
      final newResult = await updateValueFactory();

      // `set` will handle newPolicy.noStore
      await set(key, newResult);
      // If newPolicy.noStore was true, `set` would have removed it (or not stored it),
      // so we return the freshly generated value but it won't be cached as per its policy.
      yield newResult.value;
      return;
    }

    if (!cachedItem.cacheControl.isStale(cachedItem.cachedDate, now)) {
      // Item is fresh, return its value
      yield cachedItem.value;
      return;
    }

    // Item exists in cache and is not no-store
    // Check if stale using its own CacheControl policy
    if (cachedItem.cacheControl
        .canServeStaleWhileRevalidate(cachedItem.cachedDate, now)) {
      // Item is stale but can be served while revalidating.
      // Return the cached value and revalidate in the background.
      yield cachedItem.value;
    }
    // Item is stale. Try to fetch a new value.
    try {
      final newResult = await updateValueFactory();
      // Successfully fetched new value. Store and return it.
      // `set` will handle newResult.cacheControl.noStore
      await set(key, newResult);
      yield newResult.value;
      return;
    } catch (e) {
      // Failed to fetch new value. Check for stale-if-error.
      final cc = cachedItem.cacheControl;
      if (cc.canServeStaleIfError(cachedItem.cachedDate, now)) {
        yield cachedItem.value;
        return;
      }

      // Stale-if-error not configured, or the item is too old even for stale-if-error,
      // or the error was not one that stale-if-error should cover (though we don't distinguish error types here).
      // Propagate the error.
      rethrow;
    }
  }
}
