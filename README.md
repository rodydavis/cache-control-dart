# cache-control

Dart only (no dependencies) package to parse and format HTTP Cache-Control header.

## Getting started

```bash
$ flutter pub add cachecontrol
```

## API

HTTP requests can have a [Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header for both the request and response header.

```
Cache-Control: max-age=604800, stale-if-error=86400
```

To parse request headers:

```dart
final headers = <String, String>{'Cache-Control': 'max-age=604800, stale-if-error=86400'}
final cacheControl = RequestCacheControl.parse(headers['Cache-Control']!);
```

To parse response headers:

```dart
final headers = <String, String>{'Cache-Control': 'max-age=604800, stale-if-error=86400'}
final cacheControl = ResponseCacheControl.parse(headers['Cache-Control']!);
```

## Contributing

Contributions are welcome. Please open up an issue or create PR if you would like to help out.

Make sure to run `dart format` and `dart test` before submitting a PR.

## FAQ

**Why another cache-control library?**

None of the existing libraries focus on just parsing the `Cache-Control` headers. There are some that expose Express (or connect-like) middlewares, and some unmaintained other ones that do rudimentary parsing of the header. The idea of this module is to parse the header according to the RFC with no further analysis or integration.

## See also

- [`cachecontrol`](https://github.com/pquerna/cachecontrol): Golang HTTP Cache-Control Parser and Interpretation
- [`cachecontrol`](https://github.com/tusbar/cache-control): TypeScript parser and formatter
- https://shayy.org/posts/cache-control/
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
- https://www.mnot.net/cache_docs/
- https://jakearchibald.com/2016/caching-best-practices/
- https://csswizardry.com/2019/03/cache-control-for-civilians/
- https://httpwg.org/specs/rfc9111.html
- https://httpwg.org/specs/rfc5861.html
- https://httpwg.org/specs/rfc8246.html