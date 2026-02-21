import 'package:flutter/material.dart';
import 'package:portfolio_tracker/models/transaction.dart';
import 'package:portfolio_tracker/utils/constants.dart';
import 'package:portfolio_tracker/utils/formatters.dart';

/// Transaction item widget for displaying transaction information
/// 
/// Shows transaction type, asset, date, quantity, price, and total amount
/// with color coding for buy/sell transactions.
/// 
/// Example usage:
/// ```dart
/// TransactionItem(
///   transaction: Transaction(
///     id: 1,
///     userId: 1,
///     assetId: 5,
///     type: 'buy',
///     quantity: 10,
///     pricePerUnit: 150.50,
///     date: DateTime.now(),
///     notes: 'Initial investment',
///     createdAt: DateTime.now(),
///   ),
///   assetSymbol: 'AAPL',
///   assetName: 'Apple Inc.',
///   onTap: () => showTransactionDetails(...),
/// )
/// ```
class TransactionItem extends StatelessWidget {
  /// The transaction to display
  final Transaction transaction;

  /// Asset symbol (e.g., 'AAPL', 'BTC')
  final String assetSymbol;

  /// Asset name (optional, for additional context)
  final String? assetName;

  /// Callback when item is tapped
  final VoidCallback? onTap;

  /// Whether to show the divider
  final bool showDivider;

  /// Whether to show notes
  final bool showNotes;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.assetSymbol,
    this.assetName,
    this.onTap,
    this.showDivider = true,
    this.showNotes = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = transaction.type == AppConstants.transactionTypeBuy;
    final typeColor = isBuy ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final totalAmount = transaction.quantity * transaction.pricePerUnit;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    transaction.type.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Asset Symbol and Name
                      Row(
                        children: [
                          Text(
                            assetSymbol,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (assetName != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                assetName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Quantity and Price
                      Text(
                        '${Formatters.formatShares(transaction.quantity)} @ ${Formatters.formatCurrency(transaction.pricePerUnit)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatDateTime(transaction.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Notes (if any and showNotes is true)
                      if (showNotes &&
                          transaction.notes != null &&
                          transaction.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notes,
                                size: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  transaction.notes!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBuy ? 'INVESTED' : 'REALIZED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerColor,
          ),
      ],
    );
  }
}

/// Compact transaction item for smaller displays
/// 
/// Example usage:
/// ```dart
/// CompactTransactionItem(
///   transaction: myTransaction,
///   assetSymbol: 'AAPL',
///   onTap: () => showDetails(),
/// )
/// ```
class CompactTransactionItem extends StatelessWidget {
  /// The transaction to display
  final Transaction transaction;

  /// Asset symbol
  final String assetSymbol;

  /// Callback when item is tapped
  final VoidCallback? onTap;

  const CompactTransactionItem({
    super.key,
    required this.transaction,
    required this.assetSymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = transaction.type == AppConstants.transactionTypeBuy;
    final typeColor = isBuy ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final totalAmount = transaction.quantity * transaction.pricePerUnit;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Type indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Symbol and quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetSymbol,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${transaction.type.toUpperCase()} ${Formatters.formatShares(transaction.quantity)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Date and amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
                Text(
                  Formatters.formatSmartDate(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction list section header
/// 
/// Example usage:
/// ```dart
/// TransactionSectionHeader(
///   title: 'December 2024',
///   count: 5,
///   totalAmount: 5000.00,
/// )
/// ```
class TransactionSectionHeader extends StatelessWidget {
  /// Section title (e.g., month name)
  final String title;

  /// Number of transactions in this section
  final int count;

  /// Total amount for this section (optional)
  final double? totalAmount;

  const TransactionSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count transaction${count != 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (totalAmount != null)
            Text(
              Formatters.formatCurrency(totalAmount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}