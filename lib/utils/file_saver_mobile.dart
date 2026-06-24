import 'package:flutter/services.dart';

void saveFile({required String content, required String fileName, required String mimeType}) {
  Clipboard.setData(ClipboardData(text: content));
}
