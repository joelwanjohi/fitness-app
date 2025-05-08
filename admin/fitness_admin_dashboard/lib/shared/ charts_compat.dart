import 'package:flutter/material.dart';

/// Compatibility function to replace the deprecated hashValues function
/// This handles all the different parameter counts from the error logs
int hashValues(Object? a, [Object? b, Object? c, Object? d, Object? e, 
                          Object? f, Object? g, Object? h, Object? i]) {
  // For single argument, use different approach since Object.hash needs at least 2 args
  if (b == null) return a.hashCode;
  if (c == null) return Object.hash(a, b);
  if (d == null) return Object.hash(a, b, c);
  if (e == null) return Object.hash(a, b, c, d);
  if (f == null) return Object.hash(a, b, c, d, e);
  if (g == null) return Object.hash(a, b, c, d, e, f);
  if (h == null) return Object.hash(a, b, c, d, e, f, g);
  if (i == null) return Object.hash(a, b, c, d, e, f, g, h);
  return Object.hash(a, b, c, d, e, f, g, h, i);
}

/// Extension to handle the bodyText2 reference that has been renamed to bodyMedium
extension TextThemeCompat on TextTheme {
  TextStyle? get bodyText2 => bodyMedium;
}