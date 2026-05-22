import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cv_app/providers/permissions_provider.dart';

class MockHttpOverrides extends HttpOverrides {
  static Map<String, dynamic> responsePayload = {};
  static int responseStatusCode = 200;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return MockHttpClientRequest();
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) return null;
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  int contentLength = 0;

  @override
  bool bufferOutput = true;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> get done => Future.value(MockHttpClientResponse());

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => MockHttpOverrides.responseStatusCode;

  @override
  int get contentLength =>
      utf8.encode(jsonEncode(MockHttpOverrides.responsePayload)).length;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final bytes = utf8.encode(jsonEncode(MockHttpOverrides.responsePayload));
    return Stream<List<int>>.fromIterable([bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  String? value(String name) {
    final values = _headers[name];
    if (values == null || values.isEmpty) return null;
    return values.join(', ');
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MockHttpOverrides();

  const MethodChannel channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> storage = {};

  // Helper to generate signature
  Future<String> generateSignature({
    required bool canGen,
    required bool canExp,
    required bool isPrem,
    required String? expiresAt,
    required String? appUserId,
    required String? jti,
    required int? iat,
  }) async {
    final expiresVal = expiresAt == null ? 'null' : '"$expiresAt"';
    final appUserVal = appUserId == null ? 'null' : '"$appUserId"';
    final jtiVal = jti == null ? 'null' : '"$jti"';
    final iatVal = iat == null ? 'null' : '$iat';
    final message =
        '{"canGenerateCV":$canGen,"canExportPDF":$canExp,"isPremium":$isPrem,"expiresAt":$expiresVal,"appUserId":$appUserVal,"jti":$jtiVal,"iat":$iatVal}';

    // Hex-encoded seed for Ed25519 key pair
    const seedHex =
        'ce30f35159f150178fafcc52912eee3062ee4ddc7a98e7004f6f73669cd41976';
    final seedBytes = <int>[];
    for (var i = 0; i < seedHex.length; i += 2) {
      seedBytes.add(int.parse(seedHex.substring(i, i + 2), radix: 16));
    }

    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(seedBytes);
    final signature = await algorithm.sign(
      utf8.encode(message),
      keyPair: keyPair,
    );

    return signature.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  setUp(() async {
    storage.clear();
    MockHttpOverrides.responseStatusCode = 200;

    final iatVal = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    MockHttpOverrides.responsePayload = {
      'canGenerateCV': true,
      'canExportPDF': false,
      'isPremium': false,
      'expiresAt': null,
      'appUserId': null,
      'jti': 'test-uuid-111',
      'iat': iatVal,
      'signature': await generateSignature(
        canGen: true,
        canExp: false,
        isPrem: false,
        expiresAt: null,
        appUserId: null,
        jti: 'test-uuid-111',
        iat: iatVal,
      ),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          final key = methodCall.arguments['key'];
          return storage[key];
        case 'write':
          final key = methodCall.arguments['key'];
          final value = methodCall.arguments['value'];
          storage[key] = value;
          return null;
        case 'delete':
          final key = methodCall.arguments['key'];
          storage.remove(key);
          return null;
        case 'readAll':
          return storage;
        case 'deleteAll':
          storage.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('PermissionsNotifier loads default permissions when cache is empty',
      () async {
    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.init();

    expect(notifier.state.canGenerateCV, isTrue);
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
    expect(notifier.state.expiresAt, null);
  });

  test(
      'PermissionsNotifier loads premium permissions when signature and date are valid',
      () async {
    final futureDate =
        DateTime.now().add(const Duration(days: 5)).toIso8601String();
    final iatVal = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sig = await generateSignature(
      canGen: true,
      canExp: true,
      isPrem: true,
      expiresAt: futureDate,
      appUserId: null,
      jti: 'cached-uuid-555',
      iat: iatVal,
    );

    storage['cached_canGenerateCV'] = 'true';
    storage['cached_canExportPDF'] = 'true';
    storage['cached_isPremium'] = 'true';
    storage['cached_expiresAt'] = futureDate;
    storage['cached_appUserId'] = '';
    storage['cached_jti'] = 'cached-uuid-555';
    storage['cached_iat'] = iatVal.toString();
    storage['cached_signature'] = sig;
    storage['cached_lastUpdated'] = DateTime.now().toIso8601String();

    // Prepare matching HTTP response for refresh check
    MockHttpOverrides.responsePayload = {
      'canGenerateCV': true,
      'canExportPDF': true,
      'isPremium': true,
      'expiresAt': futureDate,
      'appUserId': null,
      'jti': 'cached-uuid-555',
      'iat': iatVal,
      'signature': sig,
    };

    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.init();

    expect(notifier.state.canGenerateCV, isTrue);
    expect(notifier.state.canExportPDF, isTrue);
    expect(notifier.state.isPremium, isTrue);
    expect(notifier.state.expiresAt, futureDate);
  });

  test(
      'PermissionsNotifier invalidates cache and downgrades when signature is invalid (tampered)',
      () async {
    final futureDate =
        DateTime.now().add(const Duration(days: 5)).toIso8601String();

    storage['cached_canGenerateCV'] = 'true';
    storage['cached_canExportPDF'] = 'true';
    storage['cached_isPremium'] = 'true';
    storage['cached_expiresAt'] = futureDate;
    storage['cached_signature'] = 'invalid_signature_tampered';
    storage['cached_lastUpdated'] = DateTime.now().toIso8601String();

    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.init();

    expect(notifier.state.canGenerateCV, isTrue);
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
    expect(notifier.state.expiresAt, null);

    // Verify cache was cleared
    expect(storage['cached_signature'], null);
  });

  test(
      'PermissionsNotifier invalidates cache and downgrades when subscription is expired',
      () async {
    final pastDate =
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final iatVal = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sig = await generateSignature(
      canGen: true,
      canExp: true,
      isPrem: true,
      expiresAt: pastDate,
      appUserId: null,
      jti: 'cached-uuid-past',
      iat: iatVal,
    );

    storage['cached_canGenerateCV'] = 'true';
    storage['cached_canExportPDF'] = 'true';
    storage['cached_isPremium'] = 'true';
    storage['cached_expiresAt'] = pastDate;
    storage['cached_appUserId'] = '';
    storage['cached_jti'] = 'cached-uuid-past';
    storage['cached_iat'] = iatVal.toString();
    storage['cached_signature'] = sig;
    storage['cached_lastUpdated'] = DateTime.now().toIso8601String();

    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.init();

    expect(notifier.state.canGenerateCV, isTrue);
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
    expect(notifier.state.expiresAt, null);

    // Verify cache was cleared
    expect(storage['cached_signature'], null);
  });

  test('PermissionsNotifier handles 426 Upgrade Required correctly', () async {
    MockHttpOverrides.responseStatusCode = 426;
    MockHttpOverrides.responsePayload = {
      'upgradeRequired': true,
      'minimumVersion': '1.0.0',
      'message': 'App update required.'
    };

    final notifier = PermissionsNotifier(autoInit: false);
    expect(notifier.state.upgradeRequired, isFalse);

    await notifier.refreshPermissions();

    expect(notifier.state.upgradeRequired, isTrue);
    expect(notifier.state.canGenerateCV, isFalse);
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
  });

  test(
      'PermissionsNotifier invalidates cache and downgrades when cached appUserId does not match active appUserId (Token sharing defense)',
      () async {
    final futureDate =
        DateTime.now().add(const Duration(days: 5)).toIso8601String();
    final iatVal = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Sign for 'another_user'
    final sig = await generateSignature(
      canGen: true,
      canExp: true,
      isPrem: true,
      expiresAt: futureDate,
      appUserId: 'another_user',
      jti: 'test-uuid-sharing',
      iat: iatVal,
    );

    storage['cached_canGenerateCV'] = 'true';
    storage['cached_canExportPDF'] = 'true';
    storage['cached_isPremium'] = 'true';
    storage['cached_expiresAt'] = futureDate;
    storage['cached_appUserId'] = 'another_user';
    storage['cached_jti'] = 'test-uuid-sharing';
    storage['cached_iat'] = iatVal.toString();
    storage['cached_signature'] = sig;
    storage['cached_lastUpdated'] = DateTime.now().toIso8601String();

    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.init();

    // Since Purchases.appUserID returns null or empty in tests, it won't match 'another_user', so cache is cleared.
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
    expect(storage['cached_signature'], null);
  });

  test(
      'PermissionsNotifier invalidates response and downgrades when live response iat is replayed/too old (Replay defense)',
      () async {
    // Generate signature with an extremely old iat timestamp (e.g., 2 days ago)
    final pastIat =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 172800; // 48h ago
    final futureDate =
        DateTime.now().add(const Duration(days: 5)).toIso8601String();

    final sig = await generateSignature(
      canGen: true,
      canExp: true,
      isPrem: true,
      expiresAt: futureDate,
      appUserId: null,
      jti: 'test-uuid-replay',
      iat: pastIat,
    );

    MockHttpOverrides.responseStatusCode = 200;
    MockHttpOverrides.responsePayload = {
      'canGenerateCV': true,
      'canExportPDF': true,
      'isPremium': true,
      'expiresAt': futureDate,
      'appUserId': null,
      'jti': 'test-uuid-replay',
      'iat': pastIat,
      'signature': sig,
    };

    final notifier = PermissionsNotifier(autoInit: false);
    await notifier.refreshPermissions();

    // Since iat is too old, it should fail verification and fall back to free tier
    expect(notifier.state.canExportPDF, isFalse);
    expect(notifier.state.isPremium, isFalse);
  });
}
