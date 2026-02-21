import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting values throughout the application
/// 
/// Provides consistent formatting for currency, percentages, numbers,
/// dates, and other display values. All functions handle edge cases
/// including null, zero, and very large/small numbers.
class Formatters {
  // Prevent instantiation
  Formatters._();

  // ============================================================================
  // CURRENCY FORMATTING
  // ============================================================================

  /// Format a number as currency
  /// 
  /// Examples:
  /// - formatCurrency(1234.56) → "$1,234.56"
  /// - formatCurrency(1234.56, showCents: false) → "$1,235"
  /// - formatCurrency(-500.25) → "-$500.25"
  /// - formatCurrency(null) → "$0.00"
  static String formatCurrency(double? value, {bool showCents = true}) {
    if (value == null) {
      return showCents ? '\$0.00' : '\$0';
    }

    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: showCents ? 2 : 0,
    );

    return formatter.format(value);
  }

  /// Format a large number as compact currency
  /// 
  /// Examples:
  /// - formatCompactCurrency(1234) → "$1.2K"
  /// - formatCompactCurrency(1234567) → "$1.2M"
  /// - formatCompactCurrency(1234567890) → "$1.2B"
  /// - formatCompactCurrency(1234567890123) → "$1.2T"
  /// - formatCompactCurrency(123) → "$123"
  static String formatCompactCurrency(double? value) {
    if (value == null || value == 0) return '\$0';

    final absValue = value.abs();
    final isNegative = value < 0;
    final prefix = isNegative ? '-\$' : '\$';

    if (absValue >= 1000000000000) {
      // Trillions
      return '$prefix${(absValue / 1000000000000).toStringAsFixed(1)}T';
    } else if (absValue >= 1000000000) {
      // Billions
      return '$prefix${(absValue / 1000000000).toStringAsFixed(1)}B';
    } else if (absValue >= 1000000) {
      // Millions
      return '$prefix${(absValue / 1000000).toStringAsFixed(1)}M';
    } else if (absValue >= 1000) {
      // Thousands
      return '$prefix${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      // Less than 1000
      return formatCurrency(value, showCents: absValue < 100);
    }
  }

  // ============================================================================
  // PERCENTAGE FORMATTING
  // ============================================================================

  /// Format a number as a percentage
  /// 
  /// Examples:
  /// - formatPercent(0.1234) → "12.34%"
  /// - formatPercent(0.1234, decimals: 1) → "12.3%"
  /// - formatPercent(-0.05) → "-5.00%"
  /// - formatPercent(null) → "0.00%"
  static String formatPercent(double? value, {int decimals = 2}) {
    if (value == null) {
      return '0.${'0' * decimals}%';
    }

    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format a percentage with sign indicator
  /// 
  /// Examples:
  /// - formatPercentWithSign(0.05) → "+5.00%"
  /// - formatPercentWithSign(-0.05) → "-5.00%"
  /// - formatPercentWithSign(0) → "0.00%"
  static String formatPercentWithSign(double? value, {int decimals = 2}) {
    if (value == null || value == 0) {
      return '0.${'0' * decimals}%';
    }

    final percentage = value * 100;
    final sign = value > 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(decimals)}%';
  }

  // ============================================================================
  // NUMBER FORMATTING
  // ============================================================================

  /// Format a large number with K/M/B/T suffixes
  /// 
  /// Examples:
  /// - formatLargeNumber(1234) → "1.2K"
  /// - formatLargeNumber(1234567) → "1.2M"
  /// - formatLargeNumber(1234567890) → "1.2B"
  /// - formatLargeNumber(123) → "123"
  static String formatLargeNumber(double? value) {
    if (value == null || value == 0) return '0';

    final absValue = value.abs();
    final isNegative = value < 0;
    final prefix = isNegative ? '-' : '';

    if (absValue >= 1000000000000) {
      // Trillions
      return '$prefix${(absValue / 1000000000000).toStringAsFixed(1)}T';
    } else if (absValue >= 1000000000) {
      // Billions
      return '$prefix${(absValue / 1000000000).toStringAsFixed(1)}B';
    } else if (absValue >= 1000000) {
      // Millions
      return '$prefix${(absValue / 1000000).toStringAsFixed(1)}M';
    } else if (absValue >= 1000) {
      // Thousands
      return '$prefix${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      // Less than 1000
      return value.toStringAsFixed(absValue < 10 ? 2 : 0);
    }
  }

  /// Format number with thousands separators
  /// 
  /// Examples:
  /// - formatNumber(1234567) → "1,234,567"
  /// - formatNumber(1234.56) → "1,234.56"
  /// - formatNumber(null) → "0"
  static String formatNumber(double? value, {int decimals = 0}) {
    if (value == null) return '0';

    final formatter = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}');
    return formatter.format(value);
  }

  /// Format shares/quantity
  /// 
  /// Examples:
  /// - formatShares(100) → "100"
  /// - formatShares(100.5) → "100.5"
  /// - formatShares(0.00123456) → "0.001235" (6 decimals for small amounts)
  /// - formatShares(null) → "0"
  static String formatShares(double? quantity) {
    if (quantity == null || quantity == 0) return '0';

    final absQuantity = quantity.abs();

    // For very small quantities (crypto), show more decimals
    if (absQuantity < 0.01) {
      return quantity.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    // For small quantities, show 2-4 decimals
    else if (absQuantity < 1) {
      return quantity.toStringAsFixed(4).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    // For regular quantities, show up to 2 decimals
    else {
      final formatted = quantity.toStringAsFixed(2);
      // Remove trailing zeros after decimal point
      return formatted.replaceAll(RegExp(r'\.00$'), '');
    }
  }

  // ============================================================================
  // DATE & TIME FORMATTING
  // ============================================================================

  /// Format a date
  /// 
  /// Examples:
  /// - formatDate(DateTime(2024, 1, 15)) → "January 15, 2024"
  /// - formatDate(DateTime(2024, 1, 15), shortFormat: true) → "Jan 15, 2024"
  /// - formatDate(null) → "N/A"
  static String formatDate(DateTime? date, {bool shortFormat = false}) {
    if (date == null) return 'N/A';

    if (shortFormat) {
      return DateFormat('MMM d, y').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  /// Format date and time
  /// 
  /// Examples:
  /// - formatDateTime(DateTime(2024, 1, 15, 14, 30)) → "Jan 15, 2024 2:30 PM"
  /// - formatDateTime(null) → "N/A"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  /// Format time only
  /// 
  /// Examples:
  /// - formatTime(DateTime(2024, 1, 15, 14, 30)) → "2:30 PM"
  /// - formatTime(null) → "N/A"
  static String formatTime(DateTime? time) {
    if (time == null) return 'N/A';

    return DateFormat('h:mm a').format(time);
  }

  /// Format date as relative time (time ago)
  /// 
  /// Examples:
  /// - formatTimeAgo(DateTime.now()) → "Just now"
  /// - formatTimeAgo(DateTime.now().subtract(Duration(minutes: 5))) → "5 minutes ago"
  /// - formatTimeAgo(DateTime.now().subtract(Duration(hours: 2))) → "2 hours ago"
  /// - formatTimeAgo(DateTime.now().subtract(Duration(days: 1))) → "Yesterday"
  /// - formatTimeAgo(DateTime.now().subtract(Duration(days: 3))) → "3 days ago"
  static String formatTimeAgo(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Format date for display in lists (shows time if today, date otherwise)
  /// 
  /// Examples:
  /// - formatSmartDate(DateTime.now()) → "2:30 PM"
  /// - formatSmartDate(yesterday) → "Yesterday"
  /// - formatSmartDate(lastWeek) → "Jan 15"
  static String formatSmartDate(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      // Today - show time
      return formatTime(date);
    } else if (difference == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      // This year - show month and day
      return DateFormat('MMM d').format(date);
    } else {
      // Different year - show full date
      return DateFormat('MMM d, y').format(date);
    }
  }

  // ============================================================================
  // COLOR HELPERS
  // ============================================================================

  /// Get color based on value change
  /// 
  /// Returns green for positive, red for negative, gray for zero/null
  /// 
  /// Examples:
  /// - getChangeColor(10.5) → Green
  /// - getChangeColor(-5.2) → Red
  /// - getChangeColor(0) → Gray
  static Color getChangeColor(double? value) {
    if (value == null || value == 0) {
      return Colors.grey;
    } else if (value > 0) {
      return const Color(0xFF4CAF50); // Green
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  /// Get change icon based on value
  /// 
  /// Returns ↑ for positive, ↓ for negative, → for zero/null
  /// 
  /// Examples:
  /// - getChangeIcon(10.5) → "↑"
  /// - getChangeIcon(-5.2) → "↓"
  /// - getChangeIcon(0) → "→"
  static String getChangeIcon(double? value) {
    if (value == null || value == 0) {
      return '→';
    } else if (value > 0) {
      return '↑';
    } else {
      return '↓';
    }
  }

  /// Get change icon as IconData
  /// 
  /// Returns appropriate arrow icon based on value
  static IconData getChangeIconData(double? value) {
    if (value == null || value == 0) {
      return Icons.trending_flat;
    } else if (value > 0) {
      return Icons.trending_up;
    } else {
      return Icons.trending_down;
    }
  }

  // ============================================================================
  // TEXT STYLE HELPERS
  // ============================================================================

  /// Get text style with appropriate color for change value
  /// 
  /// Returns TextStyle with color based on positive/negative value
  static TextStyle getChangeTextStyle({
    required double? value,
    required TextStyle baseStyle,
  }) {
    return baseStyle.copyWith(
      color: getChangeColor(value),
      fontWeight: FontWeight.w600,
    );
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Check if a value is effectively zero
  /// 
  /// Returns true if value is null, zero, or very close to zero
  static bool isEffectivelyZero(double? value, {double epsilon = 0.0001}) {
    if (value == null) return true;
    return value.abs() < epsilon;
  }

  /// Parse currency string to double
  /// 
  /// Examples:
  /// - parseCurrency("$1,234.56") → 1234.56
  /// - parseCurrency("1234.56") → 1234.56
  /// - parseCurrency("invalid") → null
  static double? parseCurrency(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove currency symbols and commas
    final cleanedValue = value.replaceAll(RegExp(r'[$,\s]'), '');

    return double.tryParse(cleanedValue);
  }

  /// Parse percentage string to double (as decimal)
  /// 
  /// Examples:
  /// - parsePercent("12.34%") → 0.1234
  /// - parsePercent("12.34") → 0.1234
  /// - parsePercent("invalid") → null
  static double? parsePercent(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove percentage symbol
    final cleanedValue = value.replaceAll('%', '').trim();

    final parsedValue = double.tryParse(cleanedValue);
    if (parsedValue == null) return null;

    return parsedValue / 100;
  }

  // ============================================================================
  // FORMATTING HELPERS
  // ============================================================================

  /// Format gain/loss with currency and percentage
  /// 
  /// Examples:
  /// - formatGainLoss(value: 123.45, percent: 0.05) → "+$123.45 (+5.00%)"
  /// - formatGainLoss(value: -50.00, percent: -0.02) → "-$50.00 (-2.00%)"
  static String formatGainLoss({
    required double? value,
    required double? percent,
  }) {
    if (value == null || percent == null) return '\$0.00 (0.00%)';

    final valueStr = formatCurrency(value.abs());
    final percentStr = formatPercent(percent.abs());
    final sign = value >= 0 ? '+' : '-';

    return '$sign$valueStr ($sign$percentStr)';
  }

  /// Format market cap or other large monetary values
  /// 
  /// Examples:
  /// - formatMarketCap(1234567890) → "$1.23B"
  /// - formatMarketCap(1234567) → "$1.23M"
  static String formatMarketCap(double? value) {
    return formatCompactCurrency(value);
  }

  /// Format volume (number of shares/units traded)
  /// 
  /// Examples:
  /// - formatVolume(1234567) → "1.2M"
  /// - formatVolume(1234) → "1.2K"
  static String formatVolume(double? value) {
    return formatLargeNumber(value);
  }
}