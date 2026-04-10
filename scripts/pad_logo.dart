import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logo/LogoSquared.png');
  if (!file.existsSync()) {
    print('Source file not found!');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Failed to decode image');
    return;
  }

  // Get the background color from the logo itself to ensure a perfect match.
  // We'll sample a few pixels near the corner (but inside the rounded area).
  final bgColor = image.getPixelSafe(image.width ~/ 2, 20);
  
  // We want to make the logo look smaller and not zoomed.
  // We'll use a larger canvas (scale 1.8x).
  final newSize = (image.width * 1.8).toInt();
  final padded = img.Image(width: newSize, height: newSize);

  // Fill with the logo's ACTUAL background color
  img.fill(padded, color: bgColor);

  // Center the logo
  final x = (newSize - image.width) ~/ 2;
  final y = (newSize - image.height) ~/ 2;
  img.compositeImage(padded, image, dstX: x, dstY: y);

  File('assets/logo/LogoPadded.png').writeAsBytesSync(img.encodePng(padded));
  print('Successfully created assets/logo/LogoPadded.png with exact color match and 1.8x scale.');
}
