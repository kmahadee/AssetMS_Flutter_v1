import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../services/portfolio_provider.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';
import '../widgets/transaction_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_drawer.dart';

/// Transactions history screen showing all portfolio transactions
/// 
/// Displays a comprehensive view of all transactions with filtering,
/// grouping by date, and detailed transaction information.
/// 
/// Features:
/// - Summary cards showing total buy/sell volumes and net invested
/// - Filter chips for transaction type and date range
/// - Grouped transaction list by date
/// - Swipe to delete transactions
/// - Tap to edit transactions
/// - FAB to add new transactions
/// - Pull to refresh
/// - Drawer navigation
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  /// Selected filter type
  String _selectedFilter = 'all';

  /// Animation controller for list items
  late AnimationController _animationController;

  /// Available filter options
  final List<FilterOption> _filterOptions = [
    FilterOption('all', 'All', Icons.list),
    FilterOption('buy', 'Buys', Icons.add_circle),
    FilterOption('sell', 'Sells', Icons.remove_circle),
    FilterOption('7days', 'Last 7 Days', Icons.calendar_today),
    FilterOption('30days', 'Last 30 Days', Icons.calendar_month),
    FilterOption('3months', 'Last 3 Months', Icons.date_range),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Filter transactions based on selected filter
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'buy':
        return transactions
            .where((t) => t.type == AppConstants.transactionTypeBuy)
            .toList();
      case 'sell':
        return transactions
            .where((t) => t.type == AppConstants.transactionTypeSell)
            .toList();
      case '7days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return transactions.where((t) => t.date.isAfter(sevenDaysAgo)).toList();
      case '30days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return transactions
            .where((t) => t.date.isAfter(thirtyDaysAgo))
            .toList();
      case '3months':
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        return transactions
            .where((t) => t.date.isAfter(threeMonthsAgo))
            .toList();
      case 'all':
      default:
        return transactions;
    }
  }

  /// Group transactions by date category
  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    for (final transaction in transactions) {
      final transactionDate =
          DateTime(transaction.date.year, transaction.date.month, transaction.date.day);

      String category;
      if (transactionDate == today) {
        category = 'Today';
      } else if (transactionDate == yesterday) {
        category = 'Yesterday';
      } else if (transactionDate.isAfter(thisWeekStart) &&
          transactionDate.isBefore(today)) {
        category = 'This Week';
      } else if (transactionDate.isAfter(thisMonthStart) &&
          transactionDate.isBefore(thisWeekStart)) {
        category = 'This Month';
      } else {
        category = 'Older';
      }

      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(transaction);
    }

    return grouped;
  }

  /// Calculate summary statistics
  Map<String, double> _calculateSummary(List<Transaction> transactions) {
    double totalBuy = 0;
    double totalSell = 0;

    for (final transaction in transactions) {
      final amount = transaction.quantity * transaction.pricePerUnit;
      if (transaction.type == AppConstants.transactionTypeBuy) {
        totalBuy += amount;
      } else {
        totalSell += amount;
      }
    }

    return {
      'totalBuy': totalBuy,
      'totalSell': totalSell,
      'netInvested': totalBuy - totalSell,
      'count': transactions.length.toDouble(),
    };
  }

  /// Refresh transactions from database
  Future<void> _refreshTransactions() async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    await provider.refresh();
  }

  /// Navigate to add transaction screen
  void _navigateToAddTransaction() {
    Navigator.pushNamed(context, '/add-transaction').then((_) {
      _refreshTransactions();
    });
  }

  /// Navigate to edit transaction screen
  void _navigateToEditTransaction(Transaction transaction) {
    if (transaction.id == null) return;

    Navigator.pushNamed(
      context,
      '/edit-transaction',
      arguments: {'transactionId': transaction.id},
    ).then((_) {
      _refreshTransactions();
    });
  }

  /// Navigate to asset detail screen
  void _navigateToAssetDetail(int assetId) {
    Navigator.pushNamed(
      context,
      '/asset-detail',
      arguments: {'assetId': assetId},
    );
  }

  /// Delete transaction with confirmation
  Future<void> _deleteTransaction(Transaction transaction) async {
    if (transaction.id == null) return;

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
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      try {
        await provider.deleteTransaction(transaction.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete transaction: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Show transaction details in bottom sheet
  void _showTransactionDetails(Transaction transaction, Asset? asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTransactionDetailsSheet(transaction, asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(currentRoute: '/transactions'),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  /// Build app bar
  /// 
  /// FIX #1: Wrap Consumer in PreferredSize to satisfy PreferredSizeWidget contract
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final transactionCount = provider.transactions.length;

          return AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open menu',
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transactions'),
                Text(
                  '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Filter icon - functionality already implemented via chips
                },
                tooltip: 'Filter',
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                onPressed: null, // Grayed out for future
                tooltip: 'Search (Coming Soon)',
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build main body
  Widget _buildBody() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTransactions = provider.transactions;
        final filteredTransactions = _filterTransactions(allTransactions);
        final summary = _calculateSummary(allTransactions);

        return RefreshIndicator(
          onRefresh: _refreshTransactions,
          child: CustomScrollView(
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(
                child: _buildSummaryCards(summary),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),

              // Transactions List
              if (filteredTransactions.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                _buildTransactionsList(filteredTransactions, provider),
            ],
          ),
        );
      },
    );
  }

  /// Build floating action button
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddTransaction,
      icon: const Icon(Icons.add),
      label: const Text('Add Transaction'),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards(Map<String, double> summary) {
    final theme = Theme.of(context);

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSummaryCard(
            icon: Icons.add_circle,
            label: 'Total Buy Volume',
            value: Formatters.formatCurrency(summary['totalBuy']!),
            color: Colors.green,
          ),
          _buildSummaryCard(
            icon: Icons.remove_circle,
            label: 'Total Sell Volume',
            value: Formatters.formatCurrency(summary['totalSell']!),
            color: Colors.red,
          ),
          _buildSummaryCard(
            icon: Icons.account_balance_wallet,
            label: 'Net Invested',
            value: Formatters.formatCurrency(summary['netInvested']!),
            color: summary['netInvested']! >= 0
                ? Colors.blue
                : Colors.orange,
          ),
          _buildSummaryCard(
            icon: Icons.receipt,
            label: 'Total Transactions',
            value: summary['count']!.toInt().toString(),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(option.label),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = option.id;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Build transactions list
  Widget _buildTransactionsList(
    List<Transaction> transactions,
    PortfolioProvider provider,
  ) {
    final grouped = _groupTransactionsByDate(transactions);
    final categories = ['Today', 'Yesterday', 'This Week', 'This Month', 'Older'];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Build sections for each category that has transactions
          int currentIndex = 0;
          for (final category in categories) {
            if (!grouped.containsKey(category)) continue;

            final categoryTransactions = grouped[category]!;
            final sectionItemCount = categoryTransactions.length + 1; // +1 for header

            if (index >= currentIndex && index < currentIndex + sectionItemCount) {
              final itemIndex = index - currentIndex;

              if (itemIndex == 0) {
                // Section header
                return _buildSectionHeader(category, categoryTransactions.length);
              } else {
                // Transaction item
                final transaction = categoryTransactions[itemIndex - 1];
                final asset = provider.assets.firstWhere(
                  (a) => a.id == transaction.assetId,
                  orElse: () => Asset(
                    userId: 0,
                    symbol: 'N/A',
                    name: 'Unknown Asset',
                    assetType: 'stock',
                    currentPrice: 0,
                    previousClose: 0,
                    quantity: 0,
                    averageCost: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: _buildTransactionItem(transaction, asset),
                  ),
                );
              }
            }

            currentIndex += sectionItemCount;
          }

          return null;
        },
        childCount: () {
          int count = 0;
          for (final category in categories) {
            if (grouped.containsKey(category)) {
              count += grouped[category]!.length + 1; // +1 for header
            }
          }
          return count;
        }(),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, int count) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build transaction item with swipe to delete
  Widget _buildTransactionItem(Transaction transaction, Asset asset) {
    return Dismissible(
      key: Key('transaction-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
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
                  foregroundColor: Theme.of(context).colorScheme.error,
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
        onLongPress: () => _showTransactionDetails(transaction, asset),
        child: TransactionItem(
          transaction: transaction,
          assetSymbol: asset.symbol,
          assetName: asset.name,
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    if (_selectedFilter == 'all') {
      return EmptyStates.transactions(
        onAddTransaction: _navigateToAddTransaction,
      );
    } else {
      return EmptyStates.filteredEmpty(
        onClearFilters: () {
          setState(() {
            _selectedFilter = 'all';
          });
        },
      );
    }
  }

  /// Build transaction details bottom sheet
  /// 
  /// FIX #2: Removed references to transaction.fees since it doesn't exist in the model
  Widget _buildTransactionDetailsSheet(Transaction transaction, Asset? asset) {
    final theme = Theme.of(context);
    final isBuy = transaction.type == AppConstants.transactionTypeBuy;
    final typeColor = isBuy ? Colors.green : Colors.red;
    final totalAmount = transaction.quantity * transaction.pricePerUnit;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBuy ? Icons.add_circle : Icons.remove_circle,
                  color: typeColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.type.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (asset != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${asset.symbol} - ${asset.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details
          _buildDetailRow('Date & Time', Formatters.formatDateTime(transaction.date)),
          const SizedBox(height: 12),
          _buildDetailRow('Quantity', Formatters.formatShares(transaction.quantity)),
          const SizedBox(height: 12),
          _buildDetailRow('Price per Unit', Formatters.formatCurrency(transaction.pricePerUnit)),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Total Amount',
            Formatters.formatCurrency(totalAmount),
            valueColor: typeColor,
            valueBold: true,
          ),

          // Removed fees section since Transaction model doesn't have fees property

          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToEditTransaction(transaction);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              if (asset != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToAssetDetail(asset.id!);
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('View Asset'),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
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
            color: valueColor,
            fontWeight: valueBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

/// Filter option model
class FilterOption {
  final String id;
  final String label;
  final IconData icon;

  FilterOption(this.id, this.label, this.icon);
}