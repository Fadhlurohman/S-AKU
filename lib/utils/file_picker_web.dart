// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void importBackupFile(void Function(String content) onLoaded) {
  final uploadInput = html.FileUploadInputElement()..accept = '.json';
  uploadInput.click();
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final reader = html.FileReader();
      reader.readAsText(files[0]);
      reader.onLoadEnd.listen((evt) {
        final jsonStr = reader.result as String;
        onLoaded(jsonStr);
      });
    }
  });
}
