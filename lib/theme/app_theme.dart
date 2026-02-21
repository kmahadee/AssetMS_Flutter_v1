import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme provides the application's visual styling
/// 
/// Contains static methods to generate Material 3 light and dark themes
/// with custom color schemes, typography, and component styles.
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ============================================================================
  // COLOR DEFINITIONS
  // ============================================================================

  /// Primary color - Blue
  static const Color primaryColor = Color(0xFF2196F3);
  
  /// Secondary color - Teal
  static const Color secondaryColor = Color(0xFF009688);
  
  /// Success color - Green
  static const Color successColor = Color(0xFF4CAF50);
  
  /// Error color - Red
  static const Color errorColor = Color(0xFFF44336);
  
  /// Warning color - Orange
  static const Color warningColor = Color(0xFFFF9800);
  
  /// Light mode background
  static const Color backgroundLight = Color(0xFFF5F5F5);
  
  /// Dark mode background
  static const Color backgroundDark = Color(0xFF121212);
  
  /// Light mode card background
  static const Color cardLight = Color(0xFFFFFFFF);
  
  /// Dark mode card background
  static const Color cardDark = Color(0xFF1E1E1E);
  
  /// Gain color - Positive green
  static const Color gainColor = Color(0xFF4CAF50);
  
  /// Loss color - Negative red
  static const Color lossColor = Color(0xFFF44336);
  
  /// Neutral color - Gray for no change
  static const Color neutralColor = Color(0xFF9E9E9E);

  // Asset type colors
  static const Color stockColor = Color(0xFF2196F3);
  static const Color cryptoColor = Color(0xFFFF9800);
  static const Color forexColor = Color(0xFF9C27B0);
  static const Color commodityColor = Color(0xFF795548);
  static const Color bondColor = Color(0xFF009688);
  static const Color etfColor = Color(0xFF4CAF50);

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  /// Generate the light theme
  /// 
  /// Returns a ThemeData configured for light mode with Material 3 design
  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: cardLight,
      onSurface: Colors.black87,
      surfaceContainerHighest: backgroundLight,
      outline: Colors.grey.shade300,
      outlineVariant: Colors.grey.shade200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      
      // Typography
      textTheme: _buildTextTheme(isDark: false),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: cardLight,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        iconColor: primaryColor,
        textColor: Colors.black87,
        selectedTileColor: primaryColor.withOpacity(0.1),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardLight,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade800,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cardLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }

  // ============================================================================
  // DARK THEME
  // ============================================================================

  /// Generate the dark theme
  /// 
  /// Returns a ThemeData configured for dark mode with Material 3 design
  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: cardDark,
      onSurface: Colors.white,
      surfaceContainerHighest: backgroundDark,
      outline: Colors.grey.shade700,
      outlineVariant: Colors.grey.shade800,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      
      // Typography
      textTheme: _buildTextTheme(isDark: true),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade800,
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: cardDark,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        iconColor: primaryColor,
        textColor: Colors.white,
        selectedTileColor: primaryColor.withOpacity(0.2),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade800,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.shade700;
        }),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Build text theme for the app
  /// 
  /// Uses Poppins for headings and Inter for body text
  static TextTheme _buildTextTheme({required bool isDark}) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return TextTheme(
      // Display styles (largest text)
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      
      // Title styles
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
      
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        letterSpacing: 0.4,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // ============================================================================
  // CUSTOM DECORATIONS
  // ============================================================================

  /// Drawer header gradient decoration
  /// 
  /// Creates a gradient background for drawer headers
  static BoxDecoration drawerHeaderDecoration({bool isDark = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                primaryColor.withOpacity(0.8),
                secondaryColor.withOpacity(0.8),
              ]
            : [
                primaryColor,
                secondaryColor,
              ],
      ),
    );
  }

  /// Card decoration with custom styling
  /// 
  /// Returns a BoxDecoration for cards with optional gradient
  static BoxDecoration cardDecoration({
    bool isDark = false,
    bool hasGradient = false,
    List<Color>? gradientColors,
  }) {
    if (hasGradient && gradientColors != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: isDark ? cardDark : cardLight,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black54 : Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Get color for asset type
  /// 
  /// Returns the appropriate color based on asset type
  static Color getAssetTypeColor(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'stock':
      case 'stocks':
        return stockColor;
      case 'crypto':
      case 'cryptocurrency':
        return cryptoColor;
      case 'forex':
      case 'currency':
        return forexColor;
      case 'commodity':
      case 'commodities':
        return commodityColor;
      case 'bond':
      case 'bonds':
        return bondColor;
      case 'etf':
      case 'etfs':
        return etfColor;
      default:
        return primaryColor;
    }
  }

  /// Get icon for asset type
  /// 
  /// Returns the appropriate icon based on asset type
  static IconData getAssetTypeIcon(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'stock':
      case 'stocks':
        return Icons.show_chart;
      case 'crypto':
      case 'cryptocurrency':
        return Icons.currency_bitcoin;
      case 'forex':
      case 'currency':
        return Icons.attach_money;
      case 'commodity':
      case 'commodities':
        return Icons.local_gas_station;
      case 'bond':
      case 'bonds':
        return Icons.account_balance;
      case 'etf':
      case 'etfs':
        return Icons.pie_chart;
      default:
        return Icons.monetization_on;
    }
  }
}