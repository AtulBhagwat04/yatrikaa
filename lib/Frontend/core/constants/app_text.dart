import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/text_styles.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;

  AppText.heading(
      this.text, {
        super.key,
        this.align = TextAlign.center,
        Color? color,
      }) : style = AppTextStyles.heading.copyWith(color: color);

  AppText.body(
      this.text, {
        super.key,
        this.align = TextAlign.center,
        Color? color,
      }) : style = AppTextStyles.body.copyWith(color: color);

  AppText.caption(
      this.text, {
        super.key,
        this.align = TextAlign.center,
        Color? color,
      }) : style = AppTextStyles.caption.copyWith(color: color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: align,
    );
  }
}