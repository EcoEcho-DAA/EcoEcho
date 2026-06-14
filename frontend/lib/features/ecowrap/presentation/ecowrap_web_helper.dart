import 'dart:typed_data';
import 'ecowrap_web_helper_stub.dart'
    if (dart.library.html) 'ecowrap_web_helper_web.dart';

void downloadWebPng(Uint8List bytes, String filename) {
  downloadPngPlatform(bytes, filename);
}
