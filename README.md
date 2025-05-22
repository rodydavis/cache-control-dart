# cache-control

Dart only (minimal dependencies) package to parse and format HTTP Cache-Control header.

## Getting started

For Dart projects:
```bash
$ dart pub add cachecontrol
```

For Flutter projects:
```bash
$ flutter pub add cachecontrol
```

## API

The main class for working with Cache-Control headers is `CacheControl`.

### Parsing a Cache-Control header string:

```dart
import 'package:cachecontrol/cachecontrol.dart';

void main() {
  final headerValue = 'max-age=3600, no-cache, private';
  final cacheControl = CacheControl.fromString(headerValue);
  // You can also use the alias CacheControl.parse(headerValue);

  print('Max Age: ${cacheControl.maxAge}'); // Output: Max Age: 1:00:00.000000
  print('No Cache: ${cacheControl.noCache}');   // Output: No Cache: true
  print('Private: ${cacheControl.private}'); // Output: Private: true
}
```

### Building a Cache-Control header string:

```dart
import 'package:cachecontrol/cachecontrol.dart';

void main() {
  final cacheControlBuilder = CacheControl()
    ..public = true
    ..maxAge = const Duration(hours: 1)
    ..mustRevalidate = true;

  final headerString = cacheControlBuilder.build();
  // Or simply: final headerString = cacheControlBuilder.toString();
  // Or: final headerString = cacheControlBuilder.value;

  print(headerString); // Output: max-age=3600,must-revalidate,public (order may vary)
}
```

The `CacheControl` object provides getters for all standard directives (e.g., `maxAge`, `noCache`, `sMaxage`, `immutable`, etc.) and setters for building the header. It also includes helper methods like `isFresh()`, `isStale()`, `needsRevalidation()`, etc.

## Usage

This library helps you build and parse `Cache-Control` HTTP headers in Dart.

### 1. Creating Cache-Control Headers (Builder Pattern)

You can easily construct `Cache-Control` header strings using the `CacheControl` class. Set the desired directives and then call `build()` (or use the `value` getter / `toString()`) to get the formatted header string.

```dart
import 'package:cachecontrol/cachecontrol.dart';

void main() {
  // Example for a server response
  final responseCacheControl = CacheControl()
    ..public = true
    ..maxAge = const Duration(hours: 1)       // Cache for 1 hour
    ..sharedMaxAge = const Duration(hours: 2) // Shared caches (proxies) for 2 hours
    ..immutable = true;                       // Indicate the resource will not change

  print('Response Cache-Control: ${responseCacheControl.build()}');
  // Example Output: max-age=3600,s-maxage=7200,public,immutable (order may vary)

  // Example for a client request
  final requestCacheControl = CacheControl()
    ..noCache = true                   // Force revalidation with the server
    ..maxAge = Duration.zero;          // Prefer a response no older than 0 seconds

  print('Request Cache-Control: ${requestCacheControl.build()}');
  // Example Output: max-age=0,no-cache (order may vary)
}
```

### 2. Parsing Cache-Control Headers

Parse existing `Cache-Control` header strings into a `CacheControl` object to easily access and inspect their directives.

```dart
import 'package:cachecontrol/cachecontrol.dart';

void main() {
  final headerValue = 'max-age=3600, no-cache, private, stale-while-revalidate=86400';
  final cc = CacheControl.fromString(headerValue); // or CacheControl.parse()

  print('Parsed maxAge: ${cc.maxAge}');
  // Output: Parsed maxAge: 1:00:00.000000

  print('Parsed noCache: ${cc.noCache}');
  // Output: Parsed noCache: true

  print('Parsed private: ${cc.private}');
  // Output: Parsed private: true

  print('Parsed staleWhileRevalidate: ${cc.staleWhileRevalidate}');
  // Output: Parsed staleWhileRevalidate: 24:00:00.000000

  print('Parsed public: ${cc.public}');
  // Output: Parsed public: null (or false if not explicitly set to true)
}
```

### 3. Integration with `package:http` (Client-Side)

Use `cache_control` to generate headers for your HTTP requests when using the popular `package:http`.

```dart
import 'package:http/http.dart' as http;
import 'package:cachecontrol/cachecontrol.dart';

Future<void> fetchDataWithCustomCacheControl() async {
  final cacheControlSettings = CacheControl()
    ..noCache = true // Force the cache to submit the request to the origin server for validation
    ..maxAge = Duration.zero; // Tell caches that this request is fresh for 0 seconds

  try {
    final response = await http.get(
      Uri.parse('https://api.example.com/data'),
      headers: {
        'Cache-Control': cacheControlSettings.build(),
        // Add other headers as needed
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response Cache-Control header: ${response.headers['cache-control']}');
    print('Response body: ${response.body.substring(0, 100)}...'); // Print first 100 chars
    // Process the response...
  } catch (e) {
    print('Error fetching data: $e');
  }
}

void main() {
  fetchDataWithCustomCacheControl();
}
```

### 4. Server-Side Usage

When building a server in Dart (e.g., using `dart:io`'s `HttpServer` or `package:shelf`), you can use this library to construct the `Cache-Control` header string for your HTTP responses.

#### Using `dart:io` (`HttpServer`)

```dart
import 'dart:io';
import 'package:cachecontrol/cachecontrol.dart';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('Server listening on localhost:${server.port}');

  await for (HttpRequest request in server) {
    final responseCacheControl = CacheControl()
      ..public = true                           // Response can be cached by any cache
      ..maxAge = const Duration(minutes: 30)    // Fresh for 30 minutes
      ..mustRevalidate = true;                  // Must revalidate once stale

    request.response.headers.set('Cache-Control', responseCacheControl.build());
    request.response.headers.contentType = ContentType.json;
    request.response.write('{\"message\": \"Hello from server with Cache-Control!\", \"timestamp\": \"${DateTime.now()}\"}');
    await request.response.close();
  }
}
```

#### Using `package:shelf`

If you're using the `shelf` framework, you can set the header in your response handlers.

First, add `shelf` and `shelf_router` to your `pubspec.yaml` if you haven't already:
```yaml
dependencies:
  shelf: ^1.4.0 # Or latest version
  shelf_router: ^1.1.0 # Or latest version
  cache_control: # your_cache_control_version (e.g., ^1.0.0)
```

Then, use it in your Shelf handler:
```dart
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:cachecontrol/cachecontrol.dart';

void main() async {
  final app = shelf_router.Router();

  app.get('/data', (shelf.Request request) {
    final resourceCacheControl = CacheControl()
      ..private = true                             // Specific to one user
      ..maxAge = const Duration(minutes: 10)       // Fresh for 10 minutes
      ..staleWhileRevalidate = const Duration(days: 1); // Allow serving stale for 1 day while revalidating

    return shelf.Response.ok(
      '{\"message\": \"This is some private, cachable data.\"}\',
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': resourceCacheControl.build(),
      },
    );
  });

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(app.call); // Use app.call for shelf_router

  final server = await io.serve(handler, 'localhost', 8081);
  print('Shelf server serving at http://${server.address.host}:${server.port}');
}
```

This provides a good overview of how to use the library in common scenarios.
Remember to adjust import paths if your `cache_control` library is located differently relative to your files.
For the `package:http`, `package:shelf`, and `package:shelf_router` examples, ensure you have these dependencies in your `pubspec.yaml`.

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