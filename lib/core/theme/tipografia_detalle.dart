import 'package:flutter/material.dart';

/// Tipografía específica del detalle, derivada del tema Poppins global.
/// Los tamaños corresponden a «Detalle / programado» del archivo .pen.
extension TipografiaDetalle on TextTheme {
  TextStyle get encabezadoDetalle =>
      titleLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  TextStyle get nombreClienteDetalle =>
      titleMedium!.copyWith(fontSize: 17, fontWeight: FontWeight.w600);
  TextStyle get etiquetaDatoDetalle =>
      labelSmall!.copyWith(fontWeight: FontWeight.w400);
  TextStyle get valorDatoDetalle =>
      bodyMedium!.copyWith(fontWeight: FontWeight.w500);
  TextStyle get encabezadoSeccionDetalle =>
      bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get precioServicioDetalle =>
      bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get totalDetalle =>
      titleMedium!.copyWith(fontWeight: FontWeight.w700);
  TextStyle get notasDetalle =>
      bodyMedium!.copyWith(fontSize: 13, height: 1.45);
}
