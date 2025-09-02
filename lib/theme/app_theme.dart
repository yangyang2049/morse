import 'package:flutter/material.dart';

class AppTheme {
  // 主色调 - 黑色
  static const Color primaryColor = Color(0xFF000000);

  // 次要颜色 - 白色
  static const Color secondaryColor = Color(0xFFFFFFFF);

  // 互补色 - 黄色
  static const Color accentColor = Color(0xFFFFD700);

  // 背景色 - 黑色
  static const Color backgroundColor = Color(0xFF000000);

  // 表面色 - 深灰色
  static const Color surfaceColor = Color(0xFF1A1A1A);

  // 卡片色 - 深灰色
  static const Color cardColor = Color(0xFF1A1A1A);

  // 文字颜色 - 白色
  static const Color textColor = Color(0xFFFFFFFF);

  // 次要文字颜色 - 浅灰色
  static const Color textSecondaryColor = Color(0xFFB0B0B0);

  // 边框颜色 - 深灰色
  static const Color borderColor = Color(0xFF333333);

  // 分割线颜色 - 深灰色
  static const Color dividerColor = Color(0xFF333333);

  // 错误颜色 - 红色
  static const Color errorColor = Color(0xFFFF4444);

  // 成功颜色 - 绿色
  static const Color successColor = Color(0xFF4CAF50);

  // 警告颜色 - 橙色
  static const Color warningColor = Color(0xFFFF9800);

  // 信息颜色 - 蓝色
  static const Color infoColor = Color(0xFF2196F3);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        onPrimary: secondaryColor,
        onSecondary: primaryColor,
        onTertiary: primaryColor,
        onSurface: textColor,
        error: errorColor,
        onError: secondaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: secondaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        enableFeedback: false,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: const BorderSide(color: accentColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        bodySmall: TextStyle(color: textColor, fontSize: 12),
        labelLarge: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: accentColor,
        labelStyle: const TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
