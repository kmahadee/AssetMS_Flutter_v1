import 'package:flutter/material.dart';
import 'package:portfolio_tracker/utils/formatters.dart';
import 'package:portfolio_tracker/widgets/loading_shimmer.dart';

/// Portfolio header widget displaying portfolio summary
/// 
/// Shows total value, gains/losses, day change, and last update time.
/// Includes animations and responsive layout for different screen sizes.
/// 
/// Example usage:
/// ```dart
/// PortfolioHeader(
///   totalValue: 50000.00,
///   totalGain: 5000.00,
///   totalGainPercent: 0.11,
///   dayChange: 250.00,
///   dayChangePercent: 0.005,
///   lastUpdate: DateTime.now(),
///   isLoading: false,
/// )
/// ```
class PortfolioHeader extends StatelessWidget {
  /// Total portfolio value
  final double? totalValue;

  /// Total gain/loss amount
  final double? totalGain;

  /// Total gain/loss percentage (as decimal, e.g., 0.10 for 10%)
  final double? totalGainPercent;

  /// Day change amount
  final double? dayChange;

  /// Day change percentage (as decimal)
  final double? dayChangePercent;

  /// Last update timestamp
  final DateTime? lastUpdate;

  /// Whether data is loading
  final bool isLoading;

  /// Callback when header is tapped
  final VoidCallback? onTap;

  const PortfolioHeader({
    super.key,
    this.totalValue,
    this.totalGain,
    this.totalGainPercent,
    this.dayChange,
    this.dayChangePercent,
    this.lastUpdate,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingState(theme);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.secondary.withOpacity(0.15),
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.08),
                    theme.colorScheme.secondary.withOpacity(0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Value Label
            Text(
              'Portfolio Value',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Total Value
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                Formatters.formatCurrency(totalValue ?? 0),
                key: ValueKey(totalValue),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout: stack on narrow screens
                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalGainLoss(theme),
                      const SizedBox(height: 12),
                      _buildDayChange(theme),
                      const SizedBox(height: 12),
                      _buildLastUpdate(theme),
                    ],
                  );
                }

                // Side-by-side layout for wider screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildTotalGainLoss(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDayChange(theme)),
                  ],
                );
              },
            ),

            // Last update time (only shown on wider screens)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 400) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildLastUpdate(theme),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build total gain/loss section
  Widget _buildTotalGainLoss(ThemeData theme) {
    final gainColor = Formatters.getChangeColor(totalGain);
    final gainIcon = Formatters.getChangeIconData(totalGain);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('$totalGain-$totalGainPercent'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Gain/Loss',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                gainIcon,
                size: 18,
                color: gainColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  Formatters.formatCurrency(totalGain?.abs() ?? 0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: gainColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${Formatters.formatPercentWithSign(totalGainPercent)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: gainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build day change section
  Widget _buildDayChange(ThemeData theme) {
    final changeColor = Formatters.getChangeColor(dayChange);
    final changeIcon = Formatters.getChangeIconData(dayChange);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('$dayChange-$dayChangePercent'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                changeIcon,
                size: 18,
                color: changeColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  Formatters.formatCurrency(dayChange?.abs() ?? 0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${Formatters.formatPercentWithSign(dayChangePercent)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build last update section
  Widget _buildLastUpdate(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'Updated ${Formatters.formatTimeAgo(lastUpdate)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build loading state with shimmer effect
  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(
            width: 120,
            height: 16,
          ),
          const SizedBox(height: 8),
          const LoadingShimmer(
            width: 200,
            height: 36,
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: LoadingShimmer(
                  height: 60,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: LoadingShimmer(
                  height: 60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingShimmer(
            width: 150,
            height: 14,
          ),
        ],
      ),
    );
  }
}