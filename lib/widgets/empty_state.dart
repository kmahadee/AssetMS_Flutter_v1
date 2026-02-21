import 'package:flutter/material.dart';

/// Empty state widget for displaying when there's no data
/// 
/// A friendly, helpful widget that shows when lists or collections are empty.
/// Includes an icon, title, message, and optional action button.
/// 
/// Example usage:
/// ```dart
/// // Basic empty state
/// EmptyState(
///   icon: Icons.account_balance_wallet,
///   title: 'No Assets Yet',
///   message: 'Start building your portfolio by adding your first asset',
/// )
/// 
/// // Empty state with action button
/// EmptyState(
///   icon: Icons.receipt_long,
///   title: 'No Transactions',
///   message: 'Your transaction history will appear here',
///   actionLabel: 'Add Transaction',
///   onAction: () => Navigator.push(...),
/// )
/// 
/// // Empty state with illustration
/// EmptyState(
///   illustration: AssetImage('assets/images/empty_portfolio.png'),
///   title: 'Portfolio Empty',
///   message: 'Start tracking your investments today',
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display (optional if illustration is provided)
  final IconData? icon;

  /// Illustration image (optional, used instead of icon)
  final ImageProvider? illustration;

  /// Title text
  final String title;

  /// Message text
  final String message;

  /// Action button label (optional)
  final String? actionLabel;

  /// Action button callback (optional)
  final VoidCallback? onAction;

  /// Secondary action button label (optional)
  final String? secondaryActionLabel;

  /// Secondary action button callback (optional)
  final VoidCallback? onSecondaryAction;

  /// Custom color for the icon/illustration background
  final Color? color;

  /// Whether to show in compact mode (smaller size)
  final bool compact;

  const EmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.color,
    this.compact = false,
  }) : assert(
          icon != null || illustration != null,
          'Either icon or illustration must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or Illustration
            if (illustration != null)
              _buildIllustration(compact)
            else if (icon != null)
              _buildIcon(theme, primaryColor, compact),

            SizedBox(height: compact ? 16 : 24),

            // Title
            Text(
              title,
              style: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: compact ? 8 : 12),

            // Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                style: (compact
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Action Buttons
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 20 : 32),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  /// Build icon with colored background
  Widget _buildIcon(ThemeData theme, Color primaryColor, bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 32),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: compact ? 64 : 80,
        color: primaryColor.withOpacity(0.7),
      ),
    );
  }

  /// Build illustration
  Widget _buildIllustration(bool compact) {
    return Container(
      width: compact ? 120 : 160,
      height: compact ? 120 : 160,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: illustration!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(ThemeData theme) {
    if (secondaryActionLabel != null && onSecondaryAction != null) {
      // Two buttons layout
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ),
        ],
      );
    } else {
      // Single button
      return ElevatedButton(
        onPressed: onAction,
        child: Text(actionLabel!),
      );
    }
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  /// Empty portfolio state
  static Widget portfolio({VoidCallback? onAddAsset}) {
    return EmptyState(
      icon: Icons.account_balance_wallet,
      title: 'No Assets Yet',
      message:
          'Start building your portfolio by adding your first investment asset',
      actionLabel: 'Add Asset',
      onAction: onAddAsset,
    );
  }

  /// Empty transactions state
  static Widget transactions({VoidCallback? onAddTransaction}) {
    return EmptyState(
      icon: Icons.receipt_long,
      title: 'No Transactions',
      message: 'Your transaction history will appear here once you start trading',
      actionLabel: 'Add Transaction',
      onAction: onAddTransaction,
    );
  }

  /// Empty search results state
  static Widget searchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: query != null
          ? 'We couldn\'t find any results for "$query". Try different keywords.'
          : 'No results match your search criteria. Try adjusting your filters.',
      compact: true,
    );
  }

  /// Empty assets state for specific type
  static Widget assetType({
    required String assetType,
    VoidCallback? onAddAsset,
  }) {
    final typeNames = {
      'stock': 'Stocks',
      'crypto': 'Cryptocurrencies',
      'forex': 'Forex',
      'commodity': 'Commodities',
      'bond': 'Bonds',
      'etf': 'ETFs',
    };

    return EmptyState(
      icon: Icons.pie_chart_outline,
      title: 'No ${typeNames[assetType] ?? 'Assets'}',
      message: 'You haven\'t added any ${typeNames[assetType]?.toLowerCase() ?? 'assets'} yet',
      actionLabel: 'Add ${typeNames[assetType]?.replaceAll('s', '') ?? 'Asset'}',
      onAction: onAddAsset,
      compact: true,
    );
  }

  /// No internet connection state
  static Widget noConnection({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No Connection',
      message: 'Please check your internet connection and try again',
      actionLabel: 'Retry',
      onAction: onRetry,
      color: Colors.orange,
    );
  }

  /// Error state
  static Widget error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      message: message ?? 'An error occurred while loading the data. Please try again.',
      actionLabel: 'Try Again',
      onAction: onRetry,
      color: Colors.red,
    );
  }

  /// Maintenance state
  static Widget maintenance() {
    return const EmptyState(
      icon: Icons.construction,
      title: 'Under Maintenance',
      message: 'We\'re currently performing maintenance. Please check back soon.',
      color: Colors.orange,
    );
  }

  /// Coming soon state
  static Widget comingSoon({String? feature}) {
    return EmptyState(
      icon: Icons.rocket_launch,
      title: 'Coming Soon',
      message: feature != null
          ? '$feature is coming soon! Stay tuned for updates.'
          : 'This feature is coming soon! Stay tuned for updates.',
      color: Colors.purple,
    );
  }

  /// Permission denied state
  static Widget permissionDenied({
    String? permission,
    VoidCallback? onRequest,
  }) {
    return EmptyState(
      icon: Icons.block,
      title: 'Permission Required',
      message: permission != null
          ? 'This feature requires $permission permission to work properly.'
          : 'Please grant the necessary permissions to use this feature.',
      actionLabel: 'Grant Permission',
      onAction: onRequest,
      color: Colors.orange,
    );
  }

  /// Filters applied with no results
  static Widget filteredEmpty({VoidCallback? onClearFilters}) {
    return EmptyState(
      icon: Icons.filter_list_off,
      title: 'No Results',
      message: 'No items match your current filters. Try adjusting them.',
      actionLabel: 'Clear Filters',
      onAction: onClearFilters,
      compact: true,
    );
  }
}

/// Loading state widget (alternative to shimmer)
/// 
/// Example usage:
/// ```dart
/// LoadingState(
///   message: 'Loading your portfolio...',
/// )
/// ```
class LoadingState extends StatelessWidget {
  /// Loading message (optional)
  final String? message;

  /// Whether to show in compact mode
  final bool compact;

  const LoadingState({
    super.key,
    this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 32 : 48,
              height: compact ? 32 : 48,
              child: CircularProgressIndicator(
                strokeWidth: compact ? 3 : 4,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: compact ? 16 : 24),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}