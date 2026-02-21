import 'package:flutter/material.dart';
import 'package:portfolio_tracker/database/portfolio_calculator.dart';
import 'package:portfolio_tracker/services/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:portfolio_tracker/models/asset.dart';
// import 'package:portfolio_tracker/providers/portfolio_provider.dart';
import 'package:portfolio_tracker/database/demo_data_service.dart';
// import 'package:portfolio_tracker/utils/portfolio_calculator.dart';
import 'package:portfolio_tracker/widgets/portfolio_header.dart';
import 'package:portfolio_tracker/widgets/metric_card.dart';
import 'package:portfolio_tracker/widgets/asset_card.dart';
import 'package:portfolio_tracker/widgets/app_drawer.dart';

/// Main dashboard screen for the portfolio tracker
///
/// Features:
/// - Portfolio summary header with total value, gains, and day change
/// - Quick stats grid showing key metrics
/// - Asset allocation breakdown by type
/// - Top performers (gainers and losers)
/// - Complete asset list with filtering
/// - Empty state for new users
/// - FAB for adding assets
/// - Pull-to-refresh
/// - Swipe-to-delete on assets
/// - Long-press quick actions menu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Load data and start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize screen: load data and start price updates
  Future<void> _initializeScreen() async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);

    // Start price updates when screen appears
    provider.startPriceUpdates();

    // Trigger stagger animation
    _animationController.forward();
  }

  @override
  void deactivate() {
    // Stop price updates when leaving screen
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    provider.stopPriceUpdates();
    super.deactivate();
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    await provider.refresh();

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Portfolio updated'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show menu with options
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Asset'),
            onTap: () {
              Navigator.pop(context);
              _navigateToAddAsset();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset to Demo Data'),
            onTap: () {
              Navigator.pop(context);
              _showResetDemoDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear All Data'),
            onTap: () {
              Navigator.pop(context);
              _showClearAllDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              _navigateToSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm reset to demo data
  void _showResetDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Demo Data?'),
        content: const Text(
          'This will clear all your current assets and replace them with demo data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetToDemo();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm clearing all data
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your assets and transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Reset portfolio to demo data
  Future<void> _resetToDemo() async {
    try {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      final userId = provider.currentUser?.id;

      if (userId == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading demo data...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Clear and reseed - CREATE INSTANCE FIRST
      final demoDataService = DemoDataService();
      await demoDataService.seedDemoDataForUser(userId);

      // Reload data
      await provider.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Demo data loaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading demo data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Clear all user data
  Future<void> _clearAllData() async {
    try {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      final userId = provider.currentUser?.id;

      if (userId == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Clearing data...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Clear all data - CREATE INSTANCE FIRST
      final demoDataService = DemoDataService();
      await demoDataService.clearUserData(userId);

      // Reload data
      await provider.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('All data cleared'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error clearing data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Navigate to add asset screen
  void _navigateToAddAsset() {
    Navigator.pushNamed(context, '/add-asset').then((result) {
      if (result == true) {
        _handleRefresh();
      }
    });
  }

  /// Navigate to settings screen
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  /// Show about dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Portfolio Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const Text(
          'A comprehensive portfolio tracking app for managing your investments.',
        ),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Real-time price tracking'),
        const Text('• Multi-asset support (Stocks, Crypto, ETFs)'),
        const Text('• Transaction history'),
        const Text('• Performance analytics'),
      ],
    );
  }

  /// Get filtered assets based on selected filter
  List<Asset> _getFilteredAssets(List<Asset> assets) {
    if (_selectedFilter == 'All') {
      return assets;
    }
    // FIXED: Changed from asset.type to asset.assetType
    return assets
        .where((asset) => asset.assetType == _selectedFilter.toLowerCase())
        .toList();
  }

  /// Handle asset deletion with undo
  Future<void> _handleDeleteAsset(Asset asset) async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);

    // Remove asset
    await provider.deleteAsset(asset.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${asset.symbol} removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Re-add the asset
              await provider.addAsset(asset);
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show quick actions menu for asset
  void _showAssetQuickActions(Asset asset) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.menu),
                const SizedBox(width: 12),
                Text(
                  asset.symbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Asset'),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditAsset(asset);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Transaction'),
            onTap: () {
              Navigator.pop(context);
              _navigateToAddTransaction(asset);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Delete Asset',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleDeleteAsset(asset);
            },
          ),
        ],
      ),
    );
  }

  /// Navigate to edit asset screen
  void _navigateToEditAsset(Asset asset) {
    Navigator.pushNamed(context, '/edit-asset', arguments: asset).then((
      result,
    ) {
      if (result == true) {
        _handleRefresh();
      }
    });
  }

  /// Navigate to add transaction screen
  void _navigateToAddTransaction(Asset asset) {
    Navigator.pushNamed(context, '/add-transaction', arguments: asset).then((
      result,
    ) {
      if (result == true) {
        _handleRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          // Error state
          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          // Empty state
          if (provider.assets.isEmpty) {
            return _buildEmptyState();
          }

          // Data state
          return _buildDataState(provider);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddAsset,
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
        elevation: 4,
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading portfolio...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading portfolio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Your portfolio is empty',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first asset to get started tracking your investments',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _navigateToAddAsset,
              icon: const Icon(Icons.add),
              label: const Text('Add Asset'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showLoadDemoDialog(),
              icon: const Icon(Icons.download),
              label: const Text('Load Demo Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to confirm loading demo data
  void _showLoadDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Demo Data?'),
        content: const Text(
          'This will add sample assets to help you explore the app. You can delete them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _loadDemoData();
            },
            child: const Text('Load Demo'),
          ),
        ],
      ),
    );
  }

  /// Load demo data
  Future<void> _loadDemoData() async {
    try {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      final userId = provider.currentUser?.id;

      if (userId == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading demo data...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Seed demo data - CREATE INSTANCE FIRST
      final demoDataService = DemoDataService();
      await demoDataService.seedDemoDataForUser(userId);

      // Reload data
      await provider.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Demo data loaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading demo data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Build data state with portfolio content
  Widget _buildDataState(PortfolioProvider provider) {
    final filteredAssets = _getFilteredAssets(provider.assets);
    final summary = provider.summary;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Header - FIXED: Pass individual parameters with proper null handling
            _buildAnimatedSection(
              0,
              PortfolioHeader(
                totalValue: summary?.totalValue ?? 0,
                totalGain: summary?.totalGain ?? 0,
                totalGainPercent:
                    (summary?.totalGainPercent ?? 0) /
                    100, // Convert to decimal
                dayChange:
                    summary?.dayGain ?? 0, // FIXED: Access dayGain property
                dayChangePercent:
                    (summary?.dayGainPercent ?? 0) /
                    100, // FIXED: Access dayGainPercent property
                lastUpdate: DateTime.now(),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Grid
            _buildAnimatedSection(1, _buildQuickStatsGrid(provider)),
            const SizedBox(height: 24),

            // Asset Allocation Section
            _buildAnimatedSection(2, _buildAssetAllocationSection(provider)),
            const SizedBox(height: 24),

            // Top Movers Section
            _buildAnimatedSection(3, _buildTopMoversSection(provider)),
            const SizedBox(height: 24),

            // All Assets Section
            _buildAnimatedSection(4, _buildAllAssetsSection(filteredAssets)),

            // Bottom padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Build animated section with stagger effect
  Widget _buildAnimatedSection(int index, Widget child) {
    final delay = index * 50;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay / 1200,
          (delay + 400) / 1200,
          curve: Curves.easeOut,
        ),
      ),
    );

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
  }

  /// Build quick stats grid
  Widget _buildQuickStatsGrid(PortfolioProvider provider) {
    final summary = provider.summary;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.9,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        // FIXED: Access totalInvested property with null handling
        MetricCard(
          title: 'Total Invested',
          icon: Icons.monetization_on,
          value: '\$${(summary?.totalInvested ?? 0).toStringAsFixed(2)}',
          color: Colors.blue,
        ),
        MetricCard(
          title: 'Unrealized Gain',
          icon: Icons.trending_up,
          value: '\$${(summary?.totalGain ?? 0).toStringAsFixed(2)}',
          color: (summary?.totalGain ?? 0) >= 0 ? Colors.green : Colors.red,
        ),
        // FIXED: Access dayGain property with null handling
        MetricCard(
          title: "Day's Return",
          icon: Icons.calendar_today,
          value: '\$${(summary?.dayGain ?? 0).toStringAsFixed(2)}',
          color: (summary?.dayGain ?? 0) >= 0 ? Colors.green : Colors.red,
        ),
        MetricCard(
          title: 'Total Assets',
          icon: Icons.account_balance_wallet,
          value: '${provider.assets.length}',
          color: Colors.purple,
        ),
      ],
    );
  }

  /// Build asset allocation section
  Widget _buildAssetAllocationSection(PortfolioProvider provider) {
    final assets = provider.assets;

    // Calculate allocation by type - FIXED: Changed asset.type to asset.assetType
    // and asset.totalValue to asset.currentValue
    final stocksValue = assets
        .where((a) => a.assetType == 'stock')
        .fold<double>(0, (sum, a) => sum + a.currentValue);
    final cryptoValue = assets
        .where((a) => a.assetType == 'crypto')
        .fold<double>(0, (sum, a) => sum + a.currentValue);
    final etfsValue = assets
        .where((a) => a.assetType == 'etf')
        .fold<double>(0, (sum, a) => sum + a.currentValue);

    final totalValue = stocksValue + cryptoValue + etfsValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Allocation',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (stocksValue > 0)
                _buildAllocationCard(
                  'Stocks',
                  stocksValue,
                  totalValue > 0 ? (stocksValue / totalValue * 100) : 0,
                  Colors.blue,
                  Icons.trending_up,
                ),
              if (cryptoValue > 0)
                _buildAllocationCard(
                  'Crypto',
                  cryptoValue,
                  totalValue > 0 ? (cryptoValue / totalValue * 100) : 0,
                  Colors.orange,
                  Icons.currency_bitcoin,
                ),
              if (etfsValue > 0)
                _buildAllocationCard(
                  'ETFs',
                  etfsValue,
                  totalValue > 0 ? (etfsValue / totalValue * 100) : 0,
                  Colors.purple,
                  Icons.pie_chart,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build allocation card
  Widget _buildAllocationCard(
    String label,
    double value,
    double percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build top movers section
  Widget _buildTopMoversSection(PortfolioProvider provider) {
    // FIXED: Use getTopPerformers and getWorstPerformers instead of getTopGainers/getTopLosers
    final topGainers = PortfolioCalculator.getTopPerformers(
      provider.assets,
      limit: 3,
    );
    final topLosers = PortfolioCalculator.getWorstPerformers(
      provider.assets,
      limit: 3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performers',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Stack on small screens, side by side on larger screens
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildTopMoversList('Top Gainers', topGainers, Colors.green),
                  const SizedBox(height: 16),
                  _buildTopMoversList('Top Losers', topLosers, Colors.red),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: _buildTopMoversList(
                      'Top Gainers',
                      topGainers,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTopMoversList(
                      'Top Losers',
                      topLosers,
                      Colors.red,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  /// Build top movers list
  Widget _buildTopMoversList(String title, List<Asset> assets, Color color) {
    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == 'Top Gainers'
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...assets.map((asset) => _buildMiniAssetCard(asset, color)),
        ],
      ),
    );
  }

  /// Build mini asset card for top movers
  Widget _buildMiniAssetCard(Asset asset, Color accentColor) {
    // FIXED: Changed asset.gainPercent to asset.unrealizedGainPercent
    final gainPercent = asset.unrealizedGainPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/asset-detail', arguments: asset.id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withOpacity(0.1),
                child: Text(
                  asset.symbol.substring(0, 1),
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // FIXED: Changed asset.totalValue to asset.currentValue
                    Text(
                      '\$${asset.currentValue.toStringAsFixed(2)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${gainPercent >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build all assets section
  Widget _buildAllAssetsSection(List<Asset> filteredAssets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'All Assets',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filteredAssets.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('Stocks'),
              _buildFilterChip('Crypto'),
              _buildFilterChip('ETFs'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Asset list
        ...filteredAssets.map((asset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: Key('asset-${asset.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Asset?'),
                    content: Text(
                      'Are you sure you want to delete ${asset.symbol}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                _handleDeleteAsset(asset);
              },
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/asset-detail',
                    arguments: asset.id,
                  );
                },
                onLongPress: () {
                  _showAssetQuickActions(asset);
                },
                child: AssetCard(asset: asset),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        showCheckmark: false,
      ),
    );
  }
}
