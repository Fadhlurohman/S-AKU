import 'package:flutter/services.dart';

void importBackupFile(void Function(String content) onLoaded) {
  Clipboard.getData(Clipboard.kTextPlain).then((value) {
    if (value != null && value.text != null) {
      onLoaded(value.text!);
    } else {
      onLoaded('');
    }
  });
}
