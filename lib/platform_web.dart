import 'dart:js_interop';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString input);

extension type _Response(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSString> text();
}

@JS('localStorage')
external _Storage get _storage;

extension type _Storage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

@JS('open')
external JSObject? _open(JSString url, JSString target, JSString features);

Future<String> readJson(Uri uri) async {
  final response = await _fetch(uri.toString().toJS).toDart
      .timeout(const Duration(seconds: 15));
  if (!response.ok) {
    throw const FormatException('تعذّر تحميل البيانات من الخدمة.');
  }
  return (await response.text().toDart).toDart;
}

Future<String?> restore(String key) async => _storage.getItem(key.toJS)?.toDart;

Future<void> persist(String key, String value) async =>
    _storage.setItem(key.toJS, value.toJS);

Future<void> openProvider(Uri uri) async {
  _open(uri.toString().toJS, '_blank'.toJS, 'noopener,noreferrer'.toJS);
}
