import 'package:flutter/material.dart';
import 'package:portfolio_tracker/models/asset.dart';
import 'package:portfolio_tracker/theme/app_theme.dart';
import 'package:portfolio_tracker/utils/formatters.dart';

/// Asset card widget for displaying asset information in a list
/// 
/// Shows symbol, name, price, quantity, value, and gain/loss with
/// color-coded indicators. Includes hero animation and press effects.
/// 
/// Example usage:
/// ```dart
/// AssetCard(
///   asset: Asset(
///     id: 1,
///     userId: 1,
///     symbol: 'AAPL',
///     name: 'Apple Inc.',
///     assetType: 'stock',
///     currentPrice: 175.50,
///     previousClose: 174.00,
///     quantity: 10,
///     averageCost: 150.00,
///     createdAt: DateTime.now(),
///     updatedAt: DateTime.now(),
///   ),
///   onTap: () => Navigator.push(...),
/// )
/// ```
class AssetCard extends StatefulWidget {
  /// The asset to display
  final Asset asset;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether to show detailed information
  final bool showDetails;

  /// Whether to enable hero animation
  final bool enableHero;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.showDetails = true,
    this.enableHero = true,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  bool _isPressed = false;

  // Calculate derived values
  double get totalValue => widget.asset.currentPrice * widget.asset.quantity;
  
  double get gainLoss => totalValue - (widget.asset.averageCost * widget.asset.quantity);
  
  double get gainLossPercent {
    final cost = widget.asset.averageCost * widget.asset.quantity;
    if (cost == 0) return 0;
    return gainLoss / cost;
  }
  
  double get dayChange => widget.asset.currentPrice - widget.asset.previousClose;
  
  double get dayChangePercent {
    if (widget.asset.previousClose == 0) return 0;
    return dayChange / widget.asset.previousClose;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetTypeColor = AppTheme.getAssetTypeColor(widget.asset.assetType);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          elevation: _isPressed ? 1 : 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Symbol and Name
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Symbol with hero animation
                      Row(
                        children: [
                          // Asset type indicator
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: assetTypeColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Symbol
                          Flexible(
                            child: widget.enableHero
                                ? Hero(
                                    tag: 'asset_symbol_${widget.asset.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: _buildSymbolText(theme),
                                    ),
                                  )
                                : _buildSymbolText(theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Name
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          widget.asset.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.showDetails) ...[
                        const SizedBox(height: 8),
                        // Quantity
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            '${Formatters.formatShares(widget.asset.quantity)} shares',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right side: Price and Gain/Loss
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current Price
                      Text(
                        Formatters.formatCurrency(widget.asset.currentPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Day Change
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Formatters.getChangeIconData(dayChange),
                            size: 14,
                            color: Formatters.getChangeColor(dayChange),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatPercentWithSign(dayChangePercent),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Formatters.getChangeColor(dayChange),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (widget.showDetails) ...[
                        const SizedBox(height: 12),
                        // Total Value
                        Text(
                          Formatters.formatCurrency(totalValue),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Gain/Loss
                        _buildGainLoss(theme),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build symbol text widget
  Widget _buildSymbolText(ThemeData theme) {
    return Text(
      widget.asset.symbol,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build gain/loss widget with color coding
  Widget _buildGainLoss(ThemeData theme) {
    final color = Formatters.getChangeColor(gainLoss);
    final icon = Formatters.getChangeIconData(gainLoss);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${Formatters.formatCurrency(gainLoss.abs())} (${Formatters.formatPercentWithSign(gainLossPercent)})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compact version of asset card for smaller displays
/// 
/// Example usage:
/// ```dart
/// CompactAssetCard(
///   asset: myAsset,
///   onTap: () => Navigator.push(...),
/// )
/// ```
class CompactAssetCard extends StatelessWidget {
  /// The asset to display
  final Asset asset;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  const CompactAssetCard({
    super.key,
    required this.asset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetTypeColor = AppTheme.getAssetTypeColor(asset.assetType);
    final dayChange = asset.currentPrice - asset.previousClose;
    final dayChangePercent = asset.previousClose != 0
        ? dayChange / asset.previousClose
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Asset type indicator
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: assetTypeColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 12),
            
            // Symbol and Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    asset.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(asset.currentPrice),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Formatters.getChangeIconData(dayChange),
                      size: 12,
                      color: Formatters.getChangeColor(dayChange),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      Formatters.formatPercentWithSign(dayChangePercent),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Formatters.getChangeColor(dayChange),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}