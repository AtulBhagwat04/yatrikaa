import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logo/LogoSquared.png');
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final bgColor = image.getPixelSafe(image.width ~/ 2, 20);
  // img.Color encodes as ABGR or RGBA. 
  // Let's just print the components.
  print('Color at top-center: R:${bgColor.r}, G:${bgColor.g}, B:${bgColor.b}');
  
  String hex = '#${(bgColor.r as int).toRadixString(16).padLeft(2, '0')}${(bgColor.g as int).toRadixString(16).padLeft(2, '0')}${(bgColor.b as int).toRadixString(16).padLeft(2, '0')}';
  print('HEX: $hex');
}
