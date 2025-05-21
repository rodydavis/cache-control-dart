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
  /// Stores an item in the cache.
  ///
  /// [key]: The key to identify the item.
  /// [value]: The value of the item.
  /// [cacheControl]: The CacheControl policy associated with this item.
  /// [cachedDate]: The date and time when this item is being cached or validated.
  void set(K key, V value, CacheControl cacheControl, DateTime cachedDate);

  /// Retrieves a cached item from the store.
  ///
  /// Returns the [CachedItem] if found, otherwise null.
  CachedItem<V>? get(K key);

  /// Removes an item from the cache.
  void remove(K key);

  /// Clears all items from the cache.
  void clear();

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
  FutureOr<V?> getOrUpdateValue(
    K key,
    DateTime now,
    FutureOr<(V, CacheControl)> Function() updateValueFactory,
  );

  /// Removes all expired (stale) items from the cache.
  ///
  /// - [now]: The current DateTime, used to determine which items are stale.
  void removeExpired(DateTime now);
}
