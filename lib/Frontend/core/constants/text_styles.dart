import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle heading = GoogleFonts.montserrat(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Colors.black,
  );

  static TextStyle subHeading = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static TextStyle body = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static TextStyle caption = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Colors.white,
  );
}

