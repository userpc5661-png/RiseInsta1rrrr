import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const bridge = MethodChannel('com.mashhad.app/browser');

Future<String> readJson(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode == 403 || response.statusCode == 401) {
      throw const FormatException(
        'هذا القسم يتطلب فتح الخدمة من صفحتها الأصلية.',
      );
    }
    if (response.statusCode != 200) {
      throw const FormatException('تعذّر تحميل البيانات من الخدمة.');
    }
    return await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 15));
  } finally {
    client.close(force: true);
  }
}

Future<String?> restore(String key) =>
    bridge.invokeMethod<String>('restore', key);

Future<void> persist(String key, String value) =>
    bridge.invokeMethod<void>('persist', {'key': key, 'value': value});

Future<void> openProvider(Uri uri) =>
    bridge.invokeMethod<void>('open', uri.toString());
