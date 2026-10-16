import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Change [brand] / [brandAlt] to your college colours and rebuild.
class AppColors {
  static const brand = Color(0xFF4F46E5);
  static const brandAlt = Color(0xFF7C3AED);
  static const lost = Color(0xFFE5484D);
  static const found = Color(0xFF30A46C);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme =
        ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: b);
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      scaffoldBackgroundColor:
          b == Brightness.light ? const Color(0xFFF6F6FB) : scheme.surface,
    );
  }
}

IconData categoryIcon(String c) {
  switch (c) {
    case 'All':
      return Icons.apps;
    case 'ID Card':
      return Icons.badge_outlined;
    case 'Phone':
      return Icons.smartphone;
    case 'Wallet':
      return Icons.account_balance_wallet_outlined;
    case 'Keys':
      return Icons.key;
    case 'Books':
      return Icons.menu_book_outlined;
    case 'Bag':
      return Icons.backpack_outlined;
    case 'Laptop / Charger':
      return Icons.laptop_mac;
    case 'Clothing':
      return Icons.checkroom;
    default:
      return Icons.inventory_2_outlined;
  }
}

InputDecoration fieldDeco(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  IconData? icon,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surfaceContainerLowest,
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.8),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
