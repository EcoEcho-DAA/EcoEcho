import 'dart:typed_data';

void downloadPngPlatform(Uint8List bytes, String filename) {
  // No-op on mobile/desktop platforms, as mobile handles sharing/saving using path_provider and Share.shareXFiles.
}
