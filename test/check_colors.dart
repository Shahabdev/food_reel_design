import 'dart:io';

void main() {
  final dir = Directory('assets/images');
  for (var file in dir.listSync()) {
    if (file is File && file.path.endsWith('.jpg')) {
      final bytes = file.readAsBytesSync();
      print('${file.path}: ${bytes.length} bytes');
    }
  }
}
