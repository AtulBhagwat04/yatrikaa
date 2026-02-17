import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/text_styles.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText._(
      this.text, {
        required this.style,
        this.align = TextAlign.start,
        this.maxLines,
        this.overflow,
        super.key,
      });

  // ================= HEADING =================

  factory AppText.heading(
      String text, {
        TextAlign align = TextAlign.start,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.heading.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= SUB HEADING =================

  factory AppText.subHeading(
      String text, {
        TextAlign align = TextAlign.start,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.subHeading.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= BODY =================

  factory AppText.body(
      String text, {
        TextAlign align = TextAlign.start,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.body.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= CAPTION =================

  factory AppText.caption(
      String text, {
        TextAlign align = TextAlign.start,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= SMALL =================

  factory AppText.small(
      String text, {
        TextAlign align = TextAlign.start,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.caption.copyWith(
        fontSize: 10,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= BUTTON =================

  factory AppText.button(
      String text, {
        TextAlign align = TextAlign.center,
        Color? color,
        FontWeight? fontWeight,
        int? maxLines,
        TextOverflow? overflow,
        Key? key,
      }) {
    return AppText._(
      text,
      key: key,
      align: align,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.button.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
