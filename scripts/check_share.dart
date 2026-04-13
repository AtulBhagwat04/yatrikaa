import 'package:share_plus/share_plus.dart';

void main() {
  SharePlus.instance.share(ShareParams(text: 'hello', subject: 'world'));
}
