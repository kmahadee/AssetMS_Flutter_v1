/// Application-wide constants and configuration values
/// 
/// This file contains all constant values used throughout the application
/// including app metadata, timing configurations, default values, and
/// database schema constants.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ============================================================================
  // APP METADATA
  // ============================================================================

  /// Application name
  static const String appName = 'Portfolio Tracker';

  /// Application version
  static const String appVersion = '2.0.0';

  /// Application build number
  static const String buildNumber = '1';

  /// Application tagline
  static const String appTagline = 'Track your investments with ease';

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Short animation duration (for quick transitions)
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  /// Medium animation duration (for standard transitions)
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);

  /// Long animation duration (for complex animations)
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// Splash screen duration
  static const Duration splashDuration = Duration(seconds: 2);

  /// Snackbar display duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Error message display duration
  static const Duration errorMessageDuration = Duration(seconds: 4);

  /// Success message display duration
  static const Duration successMessageDuration = Duration(seconds: 2);

  // ============================================================================
  // UPDATE INTERVALS
  // ============================================================================

  /// Price update interval (how often to fetch new prices)
  /// Set to 30 seconds for real-time feel without overwhelming the API
  static const Duration priceUpdateInterval = Duration(seconds: 30);

  /// Portfolio refresh interval (how often to recalculate totals)
  static const Duration portfolioRefreshInterval = Duration(seconds: 60);

  /// Auto-save interval for user preferences
  static const Duration autoSaveInterval = Duration(seconds: 5);

  /// Chart data update interval
  static const Duration chartUpdateInterval = Duration(minutes: 1);

  // ============================================================================
  // DATABASE SAVE INTERVALS
  // ============================================================================

  /// Price save interval (batch save prices to SQLite)
  /// Save every 5 minutes to reduce database writes
  static const Duration priceSaveInterval = Duration(minutes: 5);

  /// Transaction batch size for bulk operations
  static const int transactionBatchSize = 50;

  /// Maximum number of price history entries to keep per asset
  static const int maxPriceHistoryEntries = 365; // 1 year of daily data

  // ============================================================================
  // DEFAULT VALUES
  // ============================================================================

  /// Default number of decimal places for currency
  static const int defaultCurrencyDecimals = 2;

  /// Default number of decimal places for percentages
  static const int defaultPercentDecimals = 2;

  /// Default number of decimal places for shares
  static const int defaultShareDecimals = 4;

  /// Default initial investment amount
  static const double defaultInvestmentAmount = 1000.0;

  /// Default portfolio currency
  static const String defaultCurrency = 'USD';

  /// Default theme mode (light/dark)
  static const String defaultThemeMode = 'system';

  /// Default chart time range
  static const String defaultChartRange = '1M'; // 1 month

  /// Default sort order for assets
  static const String defaultAssetSort = 'value_desc'; // By value, descending

  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Minimum username length
  static const int minUsernameLength = 3;

  /// Maximum username length
  static const int maxUsernameLength = 20;

  // ============================================================================
  // ASSET TYPE CONSTANTS
  // ============================================================================

  /// Asset type: Stock
  static const String assetTypeStock = 'stock';

  /// Asset type: Cryptocurrency
  static const String assetTypeCrypto = 'crypto';

  /// Asset type: Forex/Currency
  static const String assetTypeForex = 'forex';

  /// Asset type: Commodity
  static const String assetTypeCommodity = 'commodity';

  /// Asset type: Bond
  static const String assetTypeBond = 'bond';

  /// Asset type: ETF
  static const String assetTypeETF = 'etf';

  /// List of all asset types
  static const List<String> assetTypes = [
    assetTypeStock,
    assetTypeCrypto,
    assetTypeForex,
    assetTypeCommodity,
    assetTypeBond,
    assetTypeETF,
  ];

  /// Asset type display names
  static const Map<String, String> assetTypeDisplayNames = {
    assetTypeStock: 'Stock',
    assetTypeCrypto: 'Cryptocurrency',
    assetTypeForex: 'Forex',
    assetTypeCommodity: 'Commodity',
    assetTypeBond: 'Bond',
    assetTypeETF: 'ETF',
  };

  // ============================================================================
  // TRANSACTION TYPE CONSTANTS
  // ============================================================================

  /// Transaction type: Buy
  static const String transactionTypeBuy = 'buy';

  /// Transaction type: Sell
  static const String transactionTypeSell = 'sell';

  /// List of all transaction types
  static const List<String> transactionTypes = [
    transactionTypeBuy,
    transactionTypeSell,
  ];

  /// Transaction type display names
  static const Map<String, String> transactionTypeDisplayNames = {
    transactionTypeBuy: 'Buy',
    transactionTypeSell: 'Sell',
  };

  // ============================================================================
  // CHART CONFIGURATION
  // ============================================================================

  /// Chart time ranges
  static const Map<String, String> chartTimeRanges = {
    '1D': '1 Day',
    '1W': '1 Week',
    '1M': '1 Month',
    '3M': '3 Months',
    '6M': '6 Months',
    '1Y': '1 Year',
    'ALL': 'All Time',
  };

  /// Chart types
  static const String chartTypeLine = 'line';
  static const String chartTypeBar = 'bar';
  static const String chartTypePie = 'pie';
  static const String chartTypeCandle = 'candle';

  /// Default chart height
  static const double defaultChartHeight = 250.0;

  /// Default number of chart data points
  static const int defaultChartDataPoints = 30;

  /// Maximum number of chart data points
  static const int maxChartDataPoints = 365;

  // ============================================================================
  // UI CONSTANTS
  // ============================================================================

  /// Drawer width
  static const double drawerWidth = 280.0;

  /// Standard padding
  static const double standardPadding = 16.0;

  /// Small padding
  static const double smallPadding = 8.0;

  /// Large padding
  static const double largePadding = 24.0;

  /// Card border radius
  static const double cardBorderRadius = 16.0;

  /// Button border radius
  static const double buttonBorderRadius = 12.0;

  /// Input field border radius
  static const double inputBorderRadius = 12.0;

  /// Bottom sheet border radius
  static const double bottomSheetBorderRadius = 20.0;

  /// Dialog border radius
  static const double dialogBorderRadius = 16.0;

  /// Avatar radius
  static const double avatarRadius = 20.0;

  /// Large avatar radius
  static const double largeAvatarRadius = 40.0;

  /// Icon size small
  static const double iconSizeSmall = 16.0;

  /// Icon size medium
  static const double iconSizeMedium = 24.0;

  /// Icon size large
  static const double iconSizeLarge = 32.0;

  /// List tile height
  static const double listTileHeight = 72.0;

  // ============================================================================
  // NAVIGATION CONSTANTS
  // ============================================================================

  /// Navigation: Dashboard
  static const String navDashboard = 'dashboard';

  /// Navigation: Portfolio
  static const String navPortfolio = 'portfolio';

  /// Navigation: Transactions
  static const String navTransactions = 'transactions';

  /// Navigation: Assets
  static const String navAssets = 'assets';

  /// Navigation: Settings
  static const String navSettings = 'settings';

  /// Navigation: Profile
  static const String navProfile = 'profile';

  /// Navigation: Analytics
  static const String navAnalytics = 'analytics';

  /// List of main navigation items
  static const List<String> mainNavigationItems = [
    navDashboard,
    navPortfolio,
    navTransactions,
    navAnalytics,
  ];

  /// Navigation item icons
  static const Map<String, String> navigationIcons = {
    navDashboard: 'dashboard',
    navPortfolio: 'portfolio',
    navTransactions: 'transactions',
    navAssets: 'assets',
    navSettings: 'settings',
    navProfile: 'profile',
    navAnalytics: 'analytics',
  };

  /// Navigation item display names
  static const Map<String, String> navigationDisplayNames = {
    navDashboard: 'Dashboard',
    navPortfolio: 'Portfolio',
    navTransactions: 'Transactions',
    navAssets: 'Assets',
    navSettings: 'Settings',
    navProfile: 'Profile',
    navAnalytics: 'Analytics',
  };

  // ============================================================================
  // DATABASE CONSTANTS
  // ============================================================================

  /// Database name
  static const String databaseName = 'portfolio_tracker.db';

  /// Database version
  static const int databaseVersion = 1;

  // Table names
  /// Users table name
  static const String tableUsers = 'users';

  /// Assets table name
  static const String tableAssets = 'assets';

  /// Transactions table name
  static const String tableTransactions = 'transactions';

  /// App settings table name
  static const String tableAppSettings = 'app_settings';

  // Users table columns
  /// Users table: id column
  static const String colUserId = 'id';

  /// Users table: username column
  static const String colUserUsername = 'username';

  /// Users table: email column
  static const String colUserEmail = 'email';

  /// Users table: full name column
  static const String colUserFullName = 'full_name';

  /// Users table: password hash column
  static const String colUserPasswordHash = 'password_hash';

  /// Users table: created at column
  static const String colUserCreatedAt = 'created_at';

  /// Users table: last login at column
  static const String colUserLastLoginAt = 'last_login_at';

  // Assets table columns
  /// Assets table: id column
  static const String colAssetId = 'id';

  /// Assets table: user id column
  static const String colAssetUserId = 'user_id';

  /// Assets table: symbol column
  static const String colAssetSymbol = 'symbol';

  /// Assets table: name column
  static const String colAssetName = 'name';

  /// Assets table: asset type column
  static const String colAssetType = 'asset_type';

  /// Assets table: current price column
  static const String colAssetCurrentPrice = 'current_price';

  /// Assets table: previous close column
  static const String colAssetPreviousClose = 'previous_close';

  /// Assets table: quantity column
  static const String colAssetQuantity = 'quantity';

  /// Assets table: average cost column
  static const String colAssetAverageCost = 'average_cost';

  /// Assets table: created at column
  static const String colAssetCreatedAt = 'created_at';

  /// Assets table: updated at column
  static const String colAssetUpdatedAt = 'updated_at';

  // Transactions table columns
  /// Transactions table: id column
  static const String colTransactionId = 'id';

  /// Transactions table: user id column
  static const String colTransactionUserId = 'user_id';

  /// Transactions table: asset id column
  static const String colTransactionAssetId = 'asset_id';

  /// Transactions table: type column
  static const String colTransactionType = 'type';

  /// Transactions table: quantity column
  static const String colTransactionQuantity = 'quantity';

  /// Transactions table: price per unit column
  static const String colTransactionPricePerUnit = 'price_per_unit';

  /// Transactions table: date column
  static const String colTransactionDate = 'date';

  /// Transactions table: notes column
  static const String colTransactionNotes = 'notes';

  /// Transactions table: created at column
  static const String colTransactionCreatedAt = 'created_at';

  // App Settings table columns
  /// Settings table: id column
  static const String colSettingId = 'id';

  /// Settings table: user id column
  static const String colSettingUserId = 'user_id';

  /// Settings table: setting key column
  static const String colSettingKey = 'setting_key';

  /// Settings table: setting value column
  static const String colSettingValue = 'setting_value';

  /// Settings table: updated at column
  static const String colSettingUpdatedAt = 'updated_at';

  // Index names
  /// Index: users username
  static const String idxUsersUsername = 'idx_users_username';

  /// Index: assets user id
  static const String idxAssetsUserId = 'idx_assets_user_id';

  /// Index: assets symbol
  static const String idxAssetsSymbol = 'idx_assets_symbol';

  /// Index: assets type
  static const String idxAssetsType = 'idx_assets_type';

  /// Index: transactions user id
  static const String idxTransactionsUserId = 'idx_transactions_user_id';

  /// Index: transactions asset id
  static const String idxTransactionsAssetId = 'idx_transactions_asset_id';

  /// Index: transactions date
  static const String idxTransactionsDate = 'idx_transactions_date';

  /// Index: settings user id
  static const String idxSettingsUserId = 'idx_settings_user_id';

  // ============================================================================
  // SETTINGS KEYS
  // ============================================================================

  /// Setting key: theme mode
  static const String settingKeyThemeMode = 'theme_mode';

  /// Setting key: currency
  static const String settingKeyCurrency = 'currency';

  /// Setting key: notifications enabled
  static const String settingKeyNotificationsEnabled = 'notifications_enabled';

  /// Setting key: price alerts enabled
  static const String settingKeyPriceAlertsEnabled = 'price_alerts_enabled';

  /// Setting key: biometric enabled
  static const String settingKeyBiometricEnabled = 'biometric_enabled';

  /// Setting key: auto refresh
  static const String settingKeyAutoRefresh = 'auto_refresh';

  /// Setting key: default chart range
  static const String settingKeyDefaultChartRange = 'default_chart_range';

  /// Setting key: show portfolio value
  static const String settingKeyShowPortfolioValue = 'show_portfolio_value';

  /// Setting key: compact mode
  static const String settingKeyCompactMode = 'compact_mode';

  // ============================================================================
  // VALIDATION CONSTANTS
  // ============================================================================

  /// Email regex pattern
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  /// Username regex pattern (alphanumeric and underscore only)
  static const String usernamePattern = r'^[a-zA-Z0-9_]+$';

  /// Minimum transaction amount
  static const double minTransactionAmount = 0.01;

  /// Maximum transaction amount
  static const double maxTransactionAmount = 999999999.99;

  /// Minimum asset quantity
  static const double minAssetQuantity = 0.00000001; // For crypto

  /// Maximum asset quantity
  static const double maxAssetQuantity = 999999999.99;

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  /// Error: Invalid email
  static const String errorInvalidEmail = 'Please enter a valid email address';

  /// Error: Invalid username
  static const String errorInvalidUsername = 'Username can only contain letters, numbers, and underscores';

  /// Error: Username too short
  static const String errorUsernameTooShort = 'Username must be at least 3 characters';

  /// Error: Username too long
  static const String errorUsernameTooLong = 'Username must be less than 20 characters';

  /// Error: Password too short
  static const String errorPasswordTooShort = 'Password must be at least 6 characters';

  /// Error: Passwords don't match
  static const String errorPasswordsDontMatch = 'Passwords do not match';

  /// Error: Invalid amount
  static const String errorInvalidAmount = 'Please enter a valid amount';

  /// Error: Network error
  static const String errorNetworkError = 'Network error. Please check your connection.';

  /// Error: Server error
  static const String errorServerError = 'Server error. Please try again later.';

  /// Error: Not found
  static const String errorNotFound = 'Resource not found';

  /// Error: Unauthorized
  static const String errorUnauthorized = 'Unauthorized. Please log in again.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  /// Success: Login
  static const String successLogin = 'Logged in successfully';

  /// Success: Logout
  static const String successLogout = 'Logged out successfully';

  /// Success: Registration
  static const String successRegistration = 'Account created successfully';

  /// Success: Transaction added
  static const String successTransactionAdded = 'Transaction added successfully';

  /// Success: Transaction updated
  static const String successTransactionUpdated = 'Transaction updated successfully';

  /// Success: Transaction deleted
  static const String successTransactionDeleted = 'Transaction deleted successfully';

  /// Success: Asset added
  static const String successAssetAdded = 'Asset added successfully';

  /// Success: Asset updated
  static const String successAssetUpdated = 'Asset updated successfully';

  /// Success: Asset deleted
  static const String successAssetDeleted = 'Asset deleted successfully';

  /// Success: Settings saved
  static const String successSettingsSaved = 'Settings saved successfully';

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  /// Enable price alerts feature
  static const bool featurePriceAlerts = true;

  /// Enable biometric authentication
  static const bool featureBiometricAuth = true;

  /// Enable cloud sync
  static const bool featureCloudSync = false;

  /// Enable advanced analytics
  static const bool featureAdvancedAnalytics = true;

  /// Enable portfolio sharing
  static const bool featurePortfolioSharing = false;

  /// Enable dark mode
  static const bool featureDarkMode = true;

  /// Enable notifications
  static const bool featureNotifications = true;

  /// Enable export to CSV
  static const bool featureExportCSV = true;

  /// Enable export to PDF
  static const bool featureExportPDF = true;
}