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
        FontWeight? fontWeight,
      }) : style = AppTextStyles.heading.copyWith(
    color: color,
    fontWeight: fontWeight,
  );

  AppText.body(
      this.text, {
        super.key,
        this.align = TextAlign.center,
        Color? color,
        FontWeight? fontWeight,
      }) : style = AppTextStyles.body.copyWith(
    color: color,
    fontWeight: fontWeight,
  );

  AppText.caption(
      this.text, {
        super.key,
        this.align = TextAlign.center,
        Color? color,
        FontWeight? fontWeight,
      }) : style = AppTextStyles.caption.copyWith(
    color: color,
    fontWeight: fontWeight,
  );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: align,
    );
  }
}
