import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Two-typeface system taken from the mockups: Playfair Display for hero /
/// welcome moments (logo screens, auth headlines) and Inter for everything
/// functional (body copy, buttons, data-dense screens).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(
    Color color, {
    double size = 32,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.15,
      );

  static TextStyle heading(
    Color color, {
    double size = 22,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.25,
      );

  static TextStyle body(
    Color color, {
    double size = 15,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.45,
      );

  static TextStyle label(
    Color color, {
    double size = 13,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle button(Color color, {double size = 15}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption(Color color, {double size = 12}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
