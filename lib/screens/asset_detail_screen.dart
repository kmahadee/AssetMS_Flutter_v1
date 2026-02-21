import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../services/portfolio_provider.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../widgets/empty_state.dart';

/// Detailed view screen for a single asset
///
/// Shows comprehensive information including price charts, position summary,
/// transaction history, and allows editing and transaction management.
///
/// Required route parameter: assetId (int)
///
/// Example navigation:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   '/asset-detail',
///   arguments: {'assetId': 1},
/// );
/// ```
class AssetDetailScreen extends StatefulWidget {
  /// Asset ID to display (passed via route arguments)
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen>
    with TickerProviderStateMixin {
  /// Whether position summary card is expanded
  bool _isPositionExpanded = false;

  /// Whether asset info section is expanded
  bool _isInfoExpanded = false;

  /// Selected chart time period (0: 1D, 1: 1W, 2: 1M, 3: 3M, 4: 1Y)
  int _selectedPeriod = 1;

  /// Animation controller for price pulse effect
  late AnimationController _priceAnimationController;

  /// Animation controller for section slide-ins
  late AnimationController _slideController;

  /// Previous price for pulse animation
  double? _previousPrice;

  /// Chart time period labels
  final List<String> _periods = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _priceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start slide-in animation
    _slideController.forward();

    // Load asset data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssetData();
    });
  }

  @override
  void dispose() {
    _priceAnimationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Load asset data from provider
  Future<void> _loadAssetData() async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    // Refresh all data from database
    await provider.refresh();
  }

  /// Refresh data from database
  Future<void> _refreshData() async {
    await _loadAssetData();
  }

  /// Generate fake historical price data for chart
  List<FlSpot> _generateChartData(double currentPrice) {
    // Generate 7 data points with slight variations
    final random = currentPrice.hashCode;
    final List<FlSpot> spots = [];

    for (int i = 0; i < 7; i++) {
      // Create slight variations around current price
      final variance = (random % 100) / 1000; // ±0.1 variation
      final sign = (i + random) % 2 == 0 ? 1 : -1;
      final price = currentPrice * (1 + (variance * sign));
      spots.add(FlSpot(i.toDouble(), price));
    }

    return spots;
  }

  /// Navigate to edit asset screen
  void _navigateToEditAsset(Asset asset) {
    Navigator.pushNamed(
      context,
      '/edit-asset',
      arguments: {'assetId': asset.id},
    ).then((_) => _refreshData());
  }

  /// Navigate to add transaction screen
  // void _navigateToAddTransaction({String? type}) {
  //   Navigator.pushNamed(
  //     context,
  //     '/add-transaction',
  //     arguments: {
  //       'assetId': widget.assetId,
  //       'type': ?type,
  //     },
  //   ).then((_) => _refreshData());
  // }

  /// Navigate to add transaction screen
  void _navigateToAddTransaction({String? type}) {
    Navigator.pushNamed(
      context,
      '/add-transaction',
      arguments: {
        'assetId': widget.assetId,
        if (type != null) 'type': type, // ✅ FIXED
      },
    ).then((_) => _refreshData());
  }

  /// Navigate to edit transaction screen
  void _navigateToEditTransaction(Transaction transaction) {
    Navigator.pushNamed(
      context,
      '/edit-transaction',
      arguments: {'transactionId': transaction.id},
    ).then((_) => _refreshData());
  }

  /// Delete transaction with confirmation
  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${transaction.type} transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (transaction.id == null) return;

      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      await provider.deleteTransaction(transaction.id!);
      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Delete asset with confirmation
  Future<void> _deleteAsset(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text(
          'Are you sure you want to delete ${asset.symbol}? This will also delete all associated transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (asset.id == null) return;

      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      await provider.deleteAsset(asset.id!);

      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${asset.symbol} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show transaction options menu
  void _showTransactionMenu(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditTransaction(transaction);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete Transaction',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTransaction(transaction);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final asset = provider.assets.firstWhere(
          (a) => a.id == widget.assetId,
          orElse: () => throw Exception('Asset not found'),
        );

        // Trigger price pulse animation if price changed
        if (_previousPrice != null && _previousPrice != asset.currentPrice) {
          _priceAnimationController.forward(from: 0);
        }
        _previousPrice = asset.currentPrice;

        return Scaffold(
          appBar: _buildAppBar(asset),
          body: _buildBody(asset, provider),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  /// Build app bar with asset info and actions
  PreferredSizeWidget _buildAppBar(Asset asset) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.symbol,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(asset.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        // Edit button
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditAsset(asset),
          tooltip: 'Edit Asset',
        ),
        // More menu
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'add_transaction') {
              _navigateToAddTransaction();
            } else if (value == 'delete_asset') {
              _deleteAsset(asset);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add_transaction',
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Transaction'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete_asset',
              child: ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete Asset',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build main body with scrollable content
  Widget _buildBody(Asset asset, PortfolioProvider provider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceHeader(asset),
            const SizedBox(height: 16),
            _buildPositionSummary(asset),
            const SizedBox(height: 16),
            _buildMiniChart(asset),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildStatsGrid(asset),
            const SizedBox(height: 16),
            _buildTransactionHistory(provider),
            const SizedBox(height: 16),
            _buildAssetInfo(asset),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  /// Build floating action button for adding transactions
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddTransaction(),
      icon: const Icon(Icons.add),
      label: const Text('Add Transaction'),
    );
  }

  /// Build price header section with hero animation
  Widget _buildPriceHeader(Asset asset) {
    final theme = Theme.of(context);
    final dayChange = asset.currentPrice - asset.previousClose;
    final dayChangePercent = asset.previousClose != 0
        ? dayChange / asset.previousClose
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero-animated symbol
          Hero(
            tag: 'asset-symbol-${asset.id}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                asset.symbol,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current price with pulse animation
          AnimatedBuilder(
            animation: _priceAnimationController,
            builder: (context, child) {
              final scale = 1.0 + (0.1 * _priceAnimationController.value);
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              Formatters.formatCurrency(asset.currentPrice),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Day change pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Formatters.getChangeColor(dayChange).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Formatters.getChangeColor(dayChange),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Formatters.getChangeIconData(dayChange),
                  size: 16,
                  color: Formatters.getChangeColor(dayChange),
                ),
                const SizedBox(width: 6),
                Text(
                  '${dayChange >= 0 ? '+' : ''}${Formatters.formatCurrency(dayChange)} (${Formatters.formatPercentWithSign(dayChangePercent)})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Formatters.getChangeColor(dayChange),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Previous close and 24h range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Close',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(asset.previousClose),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24h Range',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.formatCurrency(asset.previousClose * 0.98)} - ${Formatters.formatCurrency(asset.previousClose * 1.02)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last updated time
          Text(
            'Last updated: ${_formatUpdateTime(DateTime.now())}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build position summary card
  Widget _buildPositionSummary(Asset asset) {
    final theme = Theme.of(context);
    final totalValue = asset.currentPrice * asset.quantity;
    final gainLoss = totalValue - (asset.averageCost * asset.quantity);
    final gainLossPercent = asset.averageCost != 0
        ? gainLoss / (asset.averageCost * asset.quantity)
        : 0.0;
    final totalInvested = asset.averageCost * asset.quantity;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPositionExpanded = !_isPositionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Position Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isPositionExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Always visible summary
                  _buildSummaryRow(
                    'Shares Owned',
                    Formatters.formatShares(asset.quantity),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Avg Cost Basis',
                    Formatters.formatCurrency(asset.averageCost),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Current Value',
                    Formatters.formatCurrency(totalValue),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Unrealized Gain/Loss',
                    '${gainLoss >= 0 ? '+' : ''}${Formatters.formatCurrency(gainLoss)} (${Formatters.formatPercentWithSign(gainLossPercent)})',
                    color: Formatters.getChangeColor(gainLoss),
                  ),

                  // Expanded details
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Total Invested',
                          Formatters.formatCurrency(totalInvested),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Current Value',
                          Formatters.formatCurrency(totalValue),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Gain/Loss (₹)',
                          Formatters.formatCurrency(gainLoss.abs()),
                          color: Formatters.getChangeColor(gainLoss),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Gain/Loss (%)',
                          Formatters.formatPercent(gainLossPercent.abs()),
                          color: Formatters.getChangeColor(gainLoss),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Return on Investment',
                          Formatters.formatPercentWithSign(gainLossPercent),
                          color: Formatters.getChangeColor(gainLoss),
                        ),
                      ],
                    ),
                    crossFadeState: _isPositionExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build summary row helper
  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Build mini chart section
  Widget _buildMiniChart(Asset asset) {
    final theme = Theme.of(context);
    final chartData = _generateChartData(asset.currentPrice);
    final isUpTrend = chartData.last.y > chartData.first.y;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Price Chart',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time period selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_periods.length, (index) {
                    final isSelected = _selectedPeriod == index;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPeriod = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                _periods[index],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Chart
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.outline.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY:
                          chartData
                              .map((e) => e.y)
                              .reduce((a, b) => a < b ? a : b) *
                          0.998,
                      maxY:
                          chartData
                              .map((e) => e.y)
                              .reduce((a, b) => a > b ? a : b) *
                          1.002,
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          color: isUpTrend ? Colors.green : Colors.red,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: isUpTrend
                                    ? Colors.green
                                    : Colors.red,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                (isUpTrend ? Colors.green : Colors.red)
                                    .withOpacity(0.3),
                                (isUpTrend ? Colors.green : Colors.red)
                                    .withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                Formatters.formatCurrency(spot.y),
                                TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.add_circle,
                      label: 'Buy',
                      color: Colors.green,
                      onTap: () => _navigateToAddTransaction(type: 'buy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.remove_circle,
                      label: 'Sell',
                      color: Colors.red,
                      onTap: () => _navigateToAddTransaction(type: 'sell'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build action card helper
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build stats grid section
  Widget _buildStatsGrid(Asset asset) {
    final theme = Theme.of(context);
    final totalValue = asset.currentPrice * asset.quantity;
    final gainLoss = totalValue - (asset.averageCost * asset.quantity);
    final gainLossPercent = asset.averageCost != 0
        ? gainLoss / (asset.averageCost * asset.quantity)
        : 0.0;
    final dayChange = asset.currentPrice - asset.previousClose;
    final dayChangePercent = asset.previousClose != 0
        ? dayChange / asset.previousClose
        : 0.0;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Market Value',
                      value: Formatters.formatCurrency(totalValue),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      label: 'Total Gain/Loss',
                      value:
                          '${gainLoss >= 0 ? '+' : ''}${Formatters.formatCurrency(gainLoss)}',
                      color: Formatters.getChangeColor(gainLoss),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_today,
                      label: 'Day Change',
                      value:
                          '${dayChange >= 0 ? '+' : ''}${Formatters.formatCurrency(dayChange)}',
                      color: Formatters.getChangeColor(dayChange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.percent,
                      label: 'Total Return',
                      value: Formatters.formatPercentWithSign(gainLossPercent),
                      color: Formatters.getChangeColor(gainLoss),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build stat card helper
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build transaction history section
  Widget _buildTransactionHistory(PortfolioProvider provider) {
    final theme = Theme.of(context);
    // Filter transactions for this asset
    final transactions =
        provider.transactions.where((t) => t.assetId == widget.assetId).toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending

    // Get asset for symbol and name
    final asset = provider.assets.firstWhere(
      (a) => a.id == widget.assetId,
      orElse: () => throw Exception('Asset not found'),
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Transaction History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${transactions.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (transactions.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long,
                    title: 'No Transactions',
                    message: 'No transactions yet',
                    actionLabel: 'Add Transaction',
                    onAction: () => _navigateToAddTransaction(),
                  )
                else
                  ...transactions.map((transaction) {
                    return Dismissible(
                      key: Key('transaction-${transaction.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: theme.colorScheme.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: const Text(
                              'Are you sure you want to delete this transaction?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteTransaction(transaction);
                      },
                      child: InkWell(
                        onTap: () => _navigateToEditTransaction(transaction),
                        onLongPress: () => _showTransactionMenu(transaction),
                        child: TransactionItem(
                          transaction: transaction,
                          assetSymbol: asset.symbol,
                          assetName: asset.name,
                        ),
                      ),
                    );
                  }),

                if (transactions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _navigateToAddTransaction(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Transaction'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build asset info section
  Widget _buildAssetInfo(Asset asset) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(
        opacity: _slideController,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              setState(() {
                _isInfoExpanded = !_isInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildInfoRow('Symbol', asset.symbol),
                        const SizedBox(height: 8),
                        _buildInfoRow('Name', asset.name),
                        const SizedBox(height: 8),
                        _buildInfoRow('Type', asset.assetType),
                      ],
                    ),
                    crossFadeState: _isInfoExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build info row helper
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Format update time
  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
