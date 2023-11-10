# cache-control

> Format and parse HTTP Cache-Control header

Based on the [TypeScript implementation](https://github.com/tusbar/cache-control) and ported to Dart.

## Getting started

```bash
$ flutter pub add cachecontrol
```

## API

This library exposes a `CacheControl` record, `parse()` method and extension method `format()`.

### `parse(header)`

```dart
import 'package:cachecontrol/cachecontrol.dart';
```

`parse()` takes a `Cache-Control` HTTP header value and returns a `CacheControl` instance.

For example, `parse('max-age=31536000, public')` will return [CacheControl] Dart record type:

```dart
CacheControl (
  maxAge: 31536000,
  sharedMaxAge: null,
  maxStale: false,
  maxStaleDuration: null,
  minFresh: null,
  immutable: false,
  mustRevalidate: false,
  noCache: false,
  noStore: false,
  noTransform: false,
  onlyIfCached: false,
  private: false,
  proxyRevalidate: false,
  public: true,
  staleIfError: null,
  staleWhileRevalidate: null
);
```

### `cacheControl.format()`

```dart
import 'package:cachecontrol/cachecontrol.dart';
```

`format()` is a method on `CacheControl` (or similar object) and returns a `Cache-Control` HTTP header value.

For example, `parse('').copyWith(maxAge: 31536000, public: true).format()` will return

```dart
max-age=31536000, public
```

## Example usage

```dart
res.setHeader(
  "Cache-Control",
  parse('')
    .copyWith(
      public: true,
      immutable: true,
    )
   .format()
);
```

## FAQ

**Why another cache-control library?**

None of the existing libraries focus on just parsing the `Cache-Control` headers. There are some that expose Express (or connect-like) middlewares, and some unmaintained other ones that do rudimentary parsing of the header. The idea of this module is to parse the header according to the RFC with no further analysis or integration.

## See also

- [`cachecontrol`](https://github.com/pquerna/cachecontrol): Golang HTTP Cache-Control Parser and Interpretation
- [`cachecontrol`](https://github.com/tusbar/cache-control): TypeScript parser and formatter
