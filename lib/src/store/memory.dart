import 'dart:async';

import 'package:meta/meta.dart';

import 'base.dart';

/// An in-memory implementation of [CacheStore].
class InMemoryCacheStore<K, V> extends CacheStore<K, V> {
  @visibleForTesting
  final Map<K, CachedItem<V>> entries =
      {}; // Renamed from _entries and made visible for testing

  @override
  FutureOr<void> set(K key, CachedItem<V> value) {
    void save() {
      entries[key] = value;
    }

    // Respect the no-store directive of the policy being applied.
    // Also, if the policy marks the content as private, and this cache is not explicitly
    // a private cache (which InMemoryCacheStore isn't by default), it should not store it.
    if (value.cacheControl.noStore == true) {
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
  FutureOr<void> removeExpired([DateTime? now]) {
    now ??= DateTime.now();
    entries.removeWhere((key, item) {
      return item.cacheControl.isStale(item.cachedDate, now!);
    });
  }
}
