import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/asset.dart';
import '../services/portfolio_provider.dart';
import '../widgets/app_drawer.dart';
import '../utils/formatters.dart';

/// Analytics and Charts Screen
///
/// Displays comprehensive portfolio analytics with multiple interactive charts:
/// - Portfolio performance over time
/// - Asset allocation pie chart
/// - Top holdings bar chart
/// - Performance comparison by asset type
/// - Gains/losses breakdown
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  /// Selected time period for charts
  String _selectedPeriod = '1M';

  /// Available time periods
  final List<String> _periods = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  /// Animation controller for chart animations
  late AnimationController _animationController;

  /// Touched section index for pie chart
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Refresh data from database
  Future<void> _refreshData() async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    await provider.refresh();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(currentRoute: '/charts'),
      body: _buildBody(),
    );
  }

  /// Build app bar with time period selector
  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);

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
          const Text('Analytics'),
          DropdownButton<String>(
            value: _selectedPeriod,
            isDense: true,
            underline: Container(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            items: _periods.map((String period) {
              return DropdownMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPeriod = newValue;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build main body with all charts
  Widget _buildBody() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.hasAssets) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio Performance Chart
                _buildPortfolioPerformanceChart(provider),
                const SizedBox(height: 32),

                // Asset Allocation Pie Chart
                _buildAssetAllocationSection(provider),
                const SizedBox(height: 32),

                // Top Holdings Bar Chart
                _buildTopHoldingsSection(provider),
                const SizedBox(height: 32),

                // Performance Comparison
                _buildPerformanceComparison(provider),
                const SizedBox(height: 32),

                // Gains/Losses Breakdown
                _buildGainsLossesBreakdown(provider),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
              Icons.insert_chart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some assets to your portfolio to see analytics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build portfolio performance chart
  Widget _buildPortfolioPerformanceChart(PortfolioProvider provider) {
    final theme = Theme.of(context);
    final currentValue = provider.summary?.totalValue ?? 0;
    final historicalData = _generateHistoricalData(currentValue);

    final isPositive = historicalData.last.value >= historicalData.first.value;
    final primaryColor = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Expanded lets this Column flex-shrink when the
                // badge needs space, preventing the 191 px overflow.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Performance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(currentValue),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // breathing room before badge
                _buildPerformanceBadge(historicalData, primaryColor),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _animationController,
                child: LineChart(
                  _createLineChartData(historicalData, primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build performance badge
  Widget _buildPerformanceBadge(List<ChartDataPoint> data, Color color) {
    final changePercent =
        ((data.last.value - data.first.value) / data.first.value) * 100;
    final isPositive = changePercent >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Create line chart data
  LineChartData _createLineChartData(
    List<ChartDataPoint> data,
    Color primaryColor,
  ) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval:
            (data.map((d) => d.value).reduce(math.max) -
                data.map((d) => d.value).reduce(math.min)) /
            4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (data.length / 5).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= data.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _formatDateForPeriod(data[value.toInt()].date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                Formatters.formatCompactCurrency(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: data.map((d) => d.value).reduce(math.min) * 0.95,
      maxY: data.map((d) => d.value).reduce(math.max) * 1.05,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.3),
                primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Theme.of(context).colorScheme.surface,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${Formatters.formatCurrency(spot.y)}\n${_formatDateForPeriod(data[spot.x.toInt()].date)}',
                TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(color: primaryColor, strokeWidth: 2),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: primaryColor,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      );
                    },
                  ),
                );
              }).toList();
            },
      ),
    );
  }

  /// Build asset allocation section
  /// FIX: Wrapped the Row in a LayoutBuilder so the PieChart gets an
  /// explicit width constraint.  Also removed the badge widget that was
  /// pushed 120 % outside the pie radius (the main cause of the 191 px
  /// right overflow).
  Widget _buildAssetAllocationSection(PortfolioProvider provider) {
    final theme = Theme.of(context);
    final allocation = _calculateAssetAllocation(provider.assets);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Allocation',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // FIX: LayoutBuilder gives the Row a known width so Expanded
            // children can share it properly and the PieChart cannot
            // overflow horizontally.
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 200,
                  width: constraints.maxWidth,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Row(
                      children: [
                        // FIX: give PieChart a fixed width instead of
                        // relying on Expanded inside a height-only box
                        SizedBox(
                          width: constraints.maxWidth * 0.6,
                          child: PieChart(_createPieChartData(allocation)),
                        ),
                        const SizedBox(width: 8),
                        // Legend fills the remaining space
                        Expanded(child: _buildPieChartLegend(allocation)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Create pie chart data
  /// FIX: Removed badgeWidget entirely — it was rendered at
  /// badgePositionPercentageOffset: 1.2 (i.e. 120 % of the radius)
  /// which pushed content far outside the chart bounds and caused the
  /// 191 px right overflow.  The touched-section effect is kept via
  /// the larger radius alone.
  PieChartData _createPieChartData(Map<String, AllocationData> allocation) {
    final sections = allocation.entries.map((entry) {
      final index = allocation.keys.toList().indexOf(entry.key);
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 65.0 : 52.0;

      return PieChartSectionData(
        color: entry.value.color,
        value: entry.value.value,
        title: '${entry.value.percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // FIX: badge removed – it was the source of the overflow.
      );
    }).toList();

    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              _touchedPieIndex = -1;
              return;
            }
            _touchedPieIndex =
                pieTouchResponse.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: 0,
      sections: sections,
    );
  }

  /// Build pie chart legend
  Widget _buildPieChartLegend(Map<String, AllocationData> allocation) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allocation.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: entry.value.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(entry.value.value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build top holdings section
  Widget _buildTopHoldingsSection(PortfolioProvider provider) {
    final theme = Theme.of(context);
    final topHoldings = _getTopHoldings(provider.assets);
    final totalValue = provider.summary?.totalValue ?? 1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 Holdings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: FadeTransition(
                opacity: _animationController,
                child: BarChart(_createBarChartData(topHoldings, totalValue)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create bar chart data
  BarChartData _createBarChartData(List<Asset> assets, double totalValue) {
    final barGroups = assets.asMap().entries.map((entry) {
      final asset = entry.value;
      final value = asset.quantity * asset.currentPrice;
      final color = _getAssetTypeColor(asset.assetType);

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: assets
                  .map((a) => a.quantity * a.currentPrice)
                  .reduce(math.max),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: assets.isEmpty
          ? 100
          : assets.map((a) => a.quantity * a.currentPrice).reduce(math.max) *
                1.1,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Theme.of(context).colorScheme.surface,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final asset = assets[groupIndex];
            final value = asset.quantity * asset.currentPrice;
            final percentage = (value / totalValue) * 100;
            return BarTooltipItem(
              '${asset.symbol}\n${Formatters.formatCurrency(value)}\n${percentage.toStringAsFixed(1)}%',
              TextStyle(
                color: _getAssetTypeColor(asset.assetType),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= assets.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  assets[value.toInt()].symbol,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            reservedSize: 32,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                Formatters.formatCompactCurrency(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  /// Build performance comparison section
  Widget _buildPerformanceComparison(PortfolioProvider provider) {
    final theme = Theme.of(context);
    final performance = _calculateTypePerformance(provider.assets);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Asset Type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...performance.entries.map((entry) {
              return _buildPerformanceCard(
                entry.key,
                entry.value,
                _getAssetTypeColor(entry.key.toLowerCase()),
                _getAssetTypeIcon(entry.key.toLowerCase()),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build individual performance card
  Widget _buildPerformanceCard(
    String type,
    double gainPercent,
    Color color,
    IconData icon,
  ) {
    final isPositive = gainPercent >= 0;
    final displayColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Return',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: displayColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${gainPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build gains/losses breakdown section
  Widget _buildGainsLossesBreakdown(PortfolioProvider provider) {
    final theme = Theme.of(context);
    final unrealizedGain = provider.summary?.totalGain ?? 0;
    final unrealizedPercent = provider.summary?.totalGainPercent ?? 0;

    // Calculate realized gains from transaction history
    final realizedGain = _calculateRealizedGains(provider.transactions);
    final totalInvested = provider.summary?.totalCost ?? 1;
    final realizedPercent = totalInvested > 0
        ? ((realizedGain / totalInvested) * 100).toDouble()
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gains & Losses',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGainLossGauge(
                    'Unrealized',
                    unrealizedGain,
                    unrealizedPercent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGainLossGauge(
                    'Realized',
                    realizedGain,
                    realizedPercent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build gain/loss gauge widget
  /// FIX: The outer Column previously overflowed 16 px at the bottom.
  /// Root causes:
  ///   1. CircularProgressIndicator with strokeWidth 12 bleeds a few px
  ///      outside its nominal size.  Wrapped it in a Padding to absorb
  ///      that bleed.
  ///   2. The inner text Column added height that pushed past the
  ///      120 px SizedBox.  Reduced font sizes slightly and tightened
  ///      the inner spacing so everything fits inside 120 px.
  Widget _buildGainLossGauge(String label, double amount, double percent) {
    final theme = Theme.of(context);
    final isPositive = amount >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    // Normalize percent to 0-1 range for gauge (cap at ±100%)
    final normalizedPercent = (percent.abs().clamp(0, 100) / 100);

    return FadeTransition(
      opacity: _animationController,
      child: Column(
        mainAxisSize: MainAxisSize.min, // FIX: don't stretch the column
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // FIX: reduced from 16
          // FIX: use a single SizedBox for the gauge area.  Add 6 px
          // padding on each side to absorb the strokeWidth bleed of
          // CircularProgressIndicator.
          SizedBox(
            height: 120,
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(6), // FIX: absorbs stroke bleed
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The indicator now lives inside the padded area so its
                  // stroke cannot escape the outer SizedBox.
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: normalizedPercent,
                      strokeWidth: 10, // FIX: reduced from 12
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  // Centre text — kept small so it fits inside the ring
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16, // FIX: reduced from 18
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2), // FIX: reduced from 4
                      Text(
                        Formatters.formatCurrency(amount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate historical data for portfolio performance chart
  List<ChartDataPoint> _generateHistoricalData(double currentValue) {
    final dataPoints = <ChartDataPoint>[];
    final now = DateTime.now();
    int days;

    switch (_selectedPeriod) {
      case '1W':
        days = 7;
        break;
      case '1M':
        days = 30;
        break;
      case '3M':
        days = 90;
        break;
      case '6M':
        days = 180;
        break;
      case '1Y':
        days = 365;
        break;
      case 'All':
        days = 730; // 2 years
        break;
      default:
        days = 30;
    }

    // Generate realistic trending data
    final random = math.Random(42); // Fixed seed for consistency
    final startValue =
        currentValue * (0.7 + random.nextDouble() * 0.3); // 70-100% of current
    final trend = (currentValue - startValue) / days;

    for (int i = 0; i <= days; i++) {
      final date = now.subtract(Duration(days: days - i));
      final trendValue = startValue + (trend * i);

      // Add some random volatility (±5%)
      final volatility = trendValue * 0.05 * (random.nextDouble() * 2 - 1);
      final value = trendValue + volatility;

      dataPoints.add(ChartDataPoint(date, value));
    }

    return dataPoints;
  }

  /// Calculate asset allocation by type
  Map<String, AllocationData> _calculateAssetAllocation(List<Asset> assets) {
    final Map<String, double> allocation = {};
    double totalValue = 0;

    for (final asset in assets) {
      final value = asset.quantity * asset.currentPrice;
      final type = asset.assetType.toLowerCase();
      allocation[type] = (allocation[type] ?? 0) + value;
      totalValue += value;
    }

    final Map<String, AllocationData> result = {};
    allocation.forEach((type, value) {
      final percentage = totalValue > 0
          ? ((value / totalValue) * 100).toDouble()
          : 0.0;
      result[_capitalizeAssetType(type)] = AllocationData(
        value: value,
        percentage: percentage,
        color: _getAssetTypeColor(type),
        icon: _getAssetTypeIcon(type),
      );
    });

    return result;
  }

  /// Get top 5 holdings by value
  List<Asset> _getTopHoldings(List<Asset> assets) {
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) {
      final valueA = a.quantity * a.currentPrice;
      final valueB = b.quantity * b.currentPrice;
      return valueB.compareTo(valueA);
    });
    return sorted.take(5).toList();
  }

  /// Calculate performance by asset type
  Map<String, double> _calculateTypePerformance(List<Asset> assets) {
    final Map<String, double> totalGain = {};
    final Map<String, double> totalCost = {};

    for (final asset in assets) {
      final type = _capitalizeAssetType(asset.assetType);
      final currentValue = asset.quantity * asset.currentPrice;
      final costBasis = asset.quantity * asset.averageCost;
      final gain = currentValue - costBasis;

      totalGain[type] = (totalGain[type] ?? 0) + gain;
      totalCost[type] = (totalCost[type] ?? 0) + costBasis;
    }

    final Map<String, double> performance = {};
    totalGain.forEach((type, gain) {
      final cost = totalCost[type] ?? 1;
      performance[type] = cost > 0 ? (gain / cost) * 100 : 0;
    });

    return performance;
  }

  /// Calculate realized gains from sell transactions
  double _calculateRealizedGains(List transactions) {
    double realizedGain = 0;

    for (final transaction in transactions) {
      if (transaction.type.toLowerCase() == 'sell') {
        // For sell transactions, we'd ideally need the original purchase price
        // For now, estimate based on transaction data
        // In a real app, you'd track cost basis properly
        realizedGain +=
            transaction.quantity *
            transaction.pricePerUnit *
            0.15; // Assume 15% gain
      }
    }

    return realizedGain;
  }

  /// Get color for asset type
  Color _getAssetTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'stock':
        return Colors.blue;
      case 'crypto':
        return Colors.orange;
      case 'etf':
        return Colors.green;
      case 'bond':
        return Colors.purple;
      case 'commodity':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for asset type
  IconData _getAssetTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'stock':
        return Icons.trending_up;
      case 'crypto':
        return Icons.currency_bitcoin;
      case 'etf':
        return Icons.pie_chart;
      case 'bond':
        return Icons.account_balance;
      case 'commodity':
        return Icons.gas_meter;
      default:
        return Icons.attach_money;
    }
  }

  /// Capitalize asset type for display
  String _capitalizeAssetType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  /// Format date based on selected period
  String _formatDateForPeriod(DateTime date) {
    switch (_selectedPeriod) {
      case '1W':
        return '${date.month}/${date.day}';
      case '1M':
      case '3M':
        return '${date.month}/${date.day}';
      case '6M':
      case '1Y':
      case 'All':
        return '${date.month}/${date.year % 100}';
      default:
        return '${date.month}/${date.day}';
    }
  }
}

/// Chart data point model
class ChartDataPoint {
  final DateTime date;
  final double value;

  ChartDataPoint(this.date, this.value);
}

/// Allocation data model
class AllocationData {
  final double value;
  final double percentage;
  final Color color;
  final IconData icon;

  AllocationData({
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}












// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:math' as math;
// import '../models/asset.dart';
// import '../services/portfolio_provider.dart';
// import '../widgets/app_drawer.dart';
// import '../utils/formatters.dart';

// /// Analytics and Charts Screen
// ///
// /// Displays comprehensive portfolio analytics with multiple interactive charts:
// /// - Portfolio performance over time
// /// - Asset allocation pie chart
// /// - Top holdings bar chart
// /// - Performance comparison by asset type
// /// - Gains/losses breakdown
// class ChartsScreen extends StatefulWidget {
//   const ChartsScreen({super.key});

//   @override
//   State<ChartsScreen> createState() => _ChartsScreenState();
// }

// class _ChartsScreenState extends State<ChartsScreen>
//     with SingleTickerProviderStateMixin {
//   /// Selected time period for charts
//   String _selectedPeriod = '1M';

//   /// Available time periods
//   final List<String> _periods = ['1W', '1M', '3M', '6M', '1Y', 'All'];

//   /// Animation controller for chart animations
//   late AnimationController _animationController;

//   /// Touched section index for pie chart
//   int _touchedPieIndex = -1;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   /// Refresh data from database
//   Future<void> _refreshData() async {
//     final provider = Provider.of<PortfolioProvider>(context, listen: false);
//     await provider.refresh();
//     _animationController.reset();
//     _animationController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       drawer: AppDrawer(currentRoute: '/charts'),
//       body: _buildBody(),
//     );
//   }

//   /// Build app bar with time period selector
//   PreferredSizeWidget _buildAppBar() {
//     final theme = Theme.of(context);

//     return AppBar(
//       leading: Builder(
//         builder: (context) => IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () => Scaffold.of(context).openDrawer(),
//           tooltip: 'Open menu',
//         ),
//       ),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Analytics'),
//           DropdownButton<String>(
//             value: _selectedPeriod,
//             isDense: true,
//             underline: Container(),
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withOpacity(0.7),
//             ),
//             items: _periods.map((String period) {
//               return DropdownMenuItem<String>(
//                 value: period,
//                 child: Text(period),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               if (newValue != null) {
//                 setState(() {
//                   _selectedPeriod = newValue;
//                 });
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build main body with all charts
//   Widget _buildBody() {
//     return Consumer<PortfolioProvider>(
//       builder: (context, provider, child) {
//         if (provider.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!provider.hasAssets) {
//           return _buildEmptyState();
//         }

//         return RefreshIndicator(
//           onRefresh: _refreshData,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Portfolio Performance Chart
//                 _buildPortfolioPerformanceChart(provider),
//                 const SizedBox(height: 32),

//                 // Asset Allocation Pie Chart
//                 _buildAssetAllocationSection(provider),
//                 const SizedBox(height: 32),

//                 // Top Holdings Bar Chart
//                 _buildTopHoldingsSection(provider),
//                 const SizedBox(height: 32),

//                 // Performance Comparison
//                 _buildPerformanceComparison(provider),
//                 const SizedBox(height: 32),

//                 // Gains/Losses Breakdown
//                 _buildGainsLossesBreakdown(provider),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   /// Build empty state
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.insert_chart_outlined,
//               size: 80,
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No Data Available',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Add some assets to your portfolio to see analytics',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build portfolio performance chart
//   Widget _buildPortfolioPerformanceChart(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final currentValue = provider.summary?.totalValue ?? 0;
//     final historicalData = _generateHistoricalData(currentValue);

//     final isPositive = historicalData.last.value >= historicalData.first.value;
//     final primaryColor = isPositive ? Colors.green : Colors.red;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Portfolio Performance',
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       Formatters.formatCurrency(currentValue),
//                       style: theme.textTheme.headlineSmall?.copyWith(
//                         color: primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 _buildPerformanceBadge(historicalData, primaryColor),
//               ],
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 200,
//               child: FadeTransition(
//                 opacity: _animationController,
//                 child: LineChart(
//                   _createLineChartData(historicalData, primaryColor),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build performance badge
//   Widget _buildPerformanceBadge(List<ChartDataPoint> data, Color color) {
//     final changePercent =
//         ((data.last.value - data.first.value) / data.first.value) * 100;
//     final isPositive = changePercent >= 0;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isPositive ? Icons.trending_up : Icons.trending_down,
//             color: color,
//             size: 18,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Create line chart data
//   LineChartData _createLineChartData(
//     List<ChartDataPoint> data,
//     Color primaryColor,
//   ) {
//     final spots = data.asMap().entries.map((entry) {
//       return FlSpot(entry.key.toDouble(), entry.value.value);
//     }).toList();

//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         horizontalInterval:
//             (data.map((d) => d.value).reduce(math.max) -
//                 data.map((d) => d.value).reduce(math.min)) /
//             4,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//             strokeWidth: 1,
//           );
//         },
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: (data.length / 5).ceilToDouble(),
//             getTitlesWidget: (value, meta) {
//               if (value.toInt() >= data.length) return const SizedBox();
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(
//                   _formatDateForPeriod(data[value.toInt()].date),
//                   style: const TextStyle(fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 Formatters.formatCompactCurrency(value),
//                 style: const TextStyle(fontSize: 10),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       minX: 0,
//       maxX: (data.length - 1).toDouble(),
//       minY: data.map((d) => d.value).reduce(math.min) * 0.95,
//       maxY: data.map((d) => d.value).reduce(math.max) * 1.05,
//       lineBarsData: [
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           curveSmoothness: 0.35,
//           color: primaryColor,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 primaryColor.withOpacity(0.3),
//                 primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipColor: (touchedSpot) =>
//               Theme.of(context).colorScheme.surface,
//           getTooltipItems: (List<LineBarSpot> touchedSpots) {
//             return touchedSpots.map((spot) {
//               return LineTooltipItem(
//                 '${Formatters.formatCurrency(spot.y)}\n${_formatDateForPeriod(data[spot.x.toInt()].date)}',
//                 TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//         handleBuiltInTouches: true,
//         getTouchedSpotIndicator:
//             (LineChartBarData barData, List<int> spotIndexes) {
//               return spotIndexes.map((spotIndex) {
//                 return TouchedSpotIndicatorData(
//                   FlLine(color: primaryColor, strokeWidth: 2),
//                   FlDotData(
//                     getDotPainter: (spot, percent, barData, index) {
//                       return FlDotCirclePainter(
//                         radius: 6,
//                         color: primaryColor,
//                         strokeWidth: 2,
//                         strokeColor: Theme.of(context).colorScheme.surface,
//                       );
//                     },
//                   ),
//                 );
//               }).toList();
//             },
//       ),
//     );
//   }

//   /// Build asset allocation section
//   /// FIX: Wrapped the Row in a LayoutBuilder so the PieChart gets an
//   /// explicit width constraint.  Also removed the badge widget that was
//   /// pushed 120 % outside the pie radius (the main cause of the 191 px
//   /// right overflow).
//   Widget _buildAssetAllocationSection(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final allocation = _calculateAssetAllocation(provider.assets);

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Asset Allocation',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             // FIX: LayoutBuilder gives the Row a known width so Expanded
//             // children can share it properly and the PieChart cannot
//             // overflow horizontally.
//             LayoutBuilder(
//               builder: (context, constraints) {
//                 return SizedBox(
//                   height: 200,
//                   width: constraints.maxWidth,
//                   child: FadeTransition(
//                     opacity: _animationController,
//                     child: Row(
//                       children: [
//                         // FIX: give PieChart a fixed width instead of
//                         // relying on Expanded inside a height-only box
//                         SizedBox(
//                           width: constraints.maxWidth * 0.6,
//                           child: PieChart(_createPieChartData(allocation)),
//                         ),
//                         const SizedBox(width: 8),
//                         // Legend fills the remaining space
//                         Expanded(child: _buildPieChartLegend(allocation)),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Create pie chart data
//   /// FIX: Removed badgeWidget entirely — it was rendered at
//   /// badgePositionPercentageOffset: 1.2 (i.e. 120 % of the radius)
//   /// which pushed content far outside the chart bounds and caused the
//   /// 191 px right overflow.  The touched-section effect is kept via
//   /// the larger radius alone.
//   PieChartData _createPieChartData(Map<String, AllocationData> allocation) {
//     final sections = allocation.entries.map((entry) {
//       final index = allocation.keys.toList().indexOf(entry.key);
//       final isTouched = index == _touchedPieIndex;
//       final radius = isTouched ? 65.0 : 52.0;

//       return PieChartSectionData(
//         color: entry.value.color,
//         value: entry.value.value,
//         title: '${entry.value.percentage.toStringAsFixed(1)}%',
//         radius: radius,
//         titleStyle: TextStyle(
//           fontSize: isTouched ? 16 : 13,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//         // FIX: badge removed – it was the source of the overflow.
//       );
//     }).toList();

//     return PieChartData(
//       pieTouchData: PieTouchData(
//         touchCallback: (FlTouchEvent event, pieTouchResponse) {
//           setState(() {
//             if (!event.isInterestedForInteractions ||
//                 pieTouchResponse == null ||
//                 pieTouchResponse.touchedSection == null) {
//               _touchedPieIndex = -1;
//               return;
//             }
//             _touchedPieIndex =
//                 pieTouchResponse.touchedSection!.touchedSectionIndex;
//           });
//         },
//       ),
//       borderData: FlBorderData(show: false),
//       sectionsSpace: 2,
//       centerSpaceRadius: 0,
//       sections: sections,
//     );
//   }

//   /// Build pie chart legend
//   Widget _buildPieChartLegend(Map<String, AllocationData> allocation) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: allocation.entries.map((entry) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             children: [
//               Container(
//                 width: 16,
//                 height: 16,
//                 decoration: BoxDecoration(
//                   color: entry.value.color,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       entry.key,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       Formatters.formatCurrency(entry.value.value),
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   /// Build top holdings section
//   Widget _buildTopHoldingsSection(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final topHoldings = _getTopHoldings(provider.assets);
//     final totalValue = provider.summary?.totalValue ?? 1;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Top 5 Holdings',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 300,
//               child: FadeTransition(
//                 opacity: _animationController,
//                 child: BarChart(_createBarChartData(topHoldings, totalValue)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Create bar chart data
//   BarChartData _createBarChartData(List<Asset> assets, double totalValue) {
//     final barGroups = assets.asMap().entries.map((entry) {
//       final asset = entry.value;
//       final value = asset.quantity * asset.currentPrice;
//       final color = _getAssetTypeColor(asset.assetType);

//       return BarChartGroupData(
//         x: entry.key,
//         barRods: [
//           BarChartRodData(
//             toY: value,
//             color: color,
//             width: 20,
//             borderRadius: const BorderRadius.only(
//               topRight: Radius.circular(6),
//               bottomRight: Radius.circular(6),
//             ),
//             backDrawRodData: BackgroundBarChartRodData(
//               show: true,
//               toY: assets
//                   .map((a) => a.quantity * a.currentPrice)
//                   .reduce(math.max),
//               color: Theme.of(
//                 context,
//               ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
//             ),
//           ),
//         ],
//         showingTooltipIndicators: [0],
//       );
//     }).toList();

//     return BarChartData(
//       alignment: BarChartAlignment.spaceAround,
//       maxY: assets.isEmpty
//           ? 100
//           : assets.map((a) => a.quantity * a.currentPrice).reduce(math.max) *
//                 1.1,
//       barTouchData: BarTouchData(
//         enabled: true,
//         touchTooltipData: BarTouchTooltipData(
//           getTooltipColor: (group) => Theme.of(context).colorScheme.surface,
//           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//             final asset = assets[groupIndex];
//             final value = asset.quantity * asset.currentPrice;
//             final percentage = (value / totalValue) * 100;
//             return BarTooltipItem(
//               '${asset.symbol}\n${Formatters.formatCurrency(value)}\n${percentage.toStringAsFixed(1)}%',
//               TextStyle(
//                 color: _getAssetTypeColor(asset.assetType),
//                 fontWeight: FontWeight.bold,
//               ),
//             );
//           },
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             getTitlesWidget: (value, meta) {
//               if (value.toInt() >= assets.length) return const SizedBox();
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(
//                   assets[value.toInt()].symbol,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               );
//             },
//             reservedSize: 32,
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 Formatters.formatCompactCurrency(value),
//                 style: const TextStyle(fontSize: 10),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       barGroups: barGroups,
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//             strokeWidth: 1,
//           );
//         },
//       ),
//     );
//   }

//   /// Build performance comparison section
//   Widget _buildPerformanceComparison(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final performance = _calculateTypePerformance(provider.assets);

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Performance by Asset Type',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...performance.entries.map((entry) {
//               return _buildPerformanceCard(
//                 entry.key,
//                 entry.value,
//                 _getAssetTypeColor(entry.key.toLowerCase()),
//                 _getAssetTypeIcon(entry.key.toLowerCase()),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build individual performance card
//   Widget _buildPerformanceCard(
//     String type,
//     double gainPercent,
//     Color color,
//     IconData icon,
//   ) {
//     final isPositive = gainPercent >= 0;
//     final displayColor = isPositive ? Colors.green : Colors.red;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3), width: 1),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   type,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Return',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(
//                       context,
//                     ).colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Row(
//             children: [
//               Icon(
//                 isPositive ? Icons.trending_up : Icons.trending_down,
//                 color: displayColor,
//                 size: 20,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 '${isPositive ? '+' : ''}${gainPercent.toStringAsFixed(2)}%',
//                 style: TextStyle(
//                   color: displayColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build gains/losses breakdown section
//   Widget _buildGainsLossesBreakdown(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final unrealizedGain = provider.summary?.totalGain ?? 0;
//     final unrealizedPercent = provider.summary?.totalGainPercent ?? 0;

//     // Calculate realized gains from transaction history
//     final realizedGain = _calculateRealizedGains(provider.transactions);
//     final totalInvested = provider.summary?.totalCost ?? 1;
//     final realizedPercent = totalInvested > 0
//         ? ((realizedGain / totalInvested) * 100).toDouble()
//         : 0.0;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Gains & Losses',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildGainLossGauge(
//                     'Unrealized',
//                     unrealizedGain,
//                     unrealizedPercent,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildGainLossGauge(
//                     'Realized',
//                     realizedGain,
//                     realizedPercent,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build gain/loss gauge widget
//   /// FIX: The outer Column previously overflowed 16 px at the bottom.
//   /// Root causes:
//   ///   1. CircularProgressIndicator with strokeWidth 12 bleeds a few px
//   ///      outside its nominal size.  Wrapped it in a Padding to absorb
//   ///      that bleed.
//   ///   2. The inner text Column added height that pushed past the
//   ///      120 px SizedBox.  Reduced font sizes slightly and tightened
//   ///      the inner spacing so everything fits inside 120 px.
//   Widget _buildGainLossGauge(String label, double amount, double percent) {
//     final theme = Theme.of(context);
//     final isPositive = amount >= 0;
//     final color = isPositive ? Colors.green : Colors.red;

//     // Normalize percent to 0-1 range for gauge (cap at ±100%)
//     final normalizedPercent = (percent.abs().clamp(0, 100) / 100);

//     return FadeTransition(
//       opacity: _animationController,
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // FIX: don't stretch the column
//         children: [
//           Text(
//             label,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12), // FIX: reduced from 16
//           // FIX: use a single SizedBox for the gauge area.  Add 6 px
//           // padding on each side to absorb the strokeWidth bleed of
//           // CircularProgressIndicator.
//           SizedBox(
//             height: 120,
//             width: 120,
//             child: Padding(
//               padding: const EdgeInsets.all(6), // FIX: absorbs stroke bleed
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   // The indicator now lives inside the padded area so its
//                   // stroke cannot escape the outer SizedBox.
//                   Positioned.fill(
//                     child: CircularProgressIndicator(
//                       value: normalizedPercent,
//                       strokeWidth: 10, // FIX: reduced from 12
//                       backgroundColor:
//                           theme.colorScheme.surfaceContainerHighest,
//                       valueColor: AlwaysStoppedAnimation<Color>(color),
//                     ),
//                   ),
//                   // Centre text — kept small so it fits inside the ring
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           fontSize: 16, // FIX: reduced from 18
//                           fontWeight: FontWeight.bold,
//                           color: color,
//                         ),
//                       ),
//                       const SizedBox(height: 2), // FIX: reduced from 4
//                       Text(
//                         Formatters.formatCurrency(amount),
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: color,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Generate historical data for portfolio performance chart
//   List<ChartDataPoint> _generateHistoricalData(double currentValue) {
//     final dataPoints = <ChartDataPoint>[];
//     final now = DateTime.now();
//     int days;

//     switch (_selectedPeriod) {
//       case '1W':
//         days = 7;
//         break;
//       case '1M':
//         days = 30;
//         break;
//       case '3M':
//         days = 90;
//         break;
//       case '6M':
//         days = 180;
//         break;
//       case '1Y':
//         days = 365;
//         break;
//       case 'All':
//         days = 730; // 2 years
//         break;
//       default:
//         days = 30;
//     }

//     // Generate realistic trending data
//     final random = math.Random(42); // Fixed seed for consistency
//     final startValue =
//         currentValue * (0.7 + random.nextDouble() * 0.3); // 70-100% of current
//     final trend = (currentValue - startValue) / days;

//     for (int i = 0; i <= days; i++) {
//       final date = now.subtract(Duration(days: days - i));
//       final trendValue = startValue + (trend * i);

//       // Add some random volatility (±5%)
//       final volatility = trendValue * 0.05 * (random.nextDouble() * 2 - 1);
//       final value = trendValue + volatility;

//       dataPoints.add(ChartDataPoint(date, value));
//     }

//     return dataPoints;
//   }

//   /// Calculate asset allocation by type
//   Map<String, AllocationData> _calculateAssetAllocation(List<Asset> assets) {
//     final Map<String, double> allocation = {};
//     double totalValue = 0;

//     for (final asset in assets) {
//       final value = asset.quantity * asset.currentPrice;
//       final type = asset.assetType.toLowerCase();
//       allocation[type] = (allocation[type] ?? 0) + value;
//       totalValue += value;
//     }

//     final Map<String, AllocationData> result = {};
//     allocation.forEach((type, value) {
//       final percentage = totalValue > 0
//           ? ((value / totalValue) * 100).toDouble()
//           : 0.0;
//       result[_capitalizeAssetType(type)] = AllocationData(
//         value: value,
//         percentage: percentage,
//         color: _getAssetTypeColor(type),
//         icon: _getAssetTypeIcon(type),
//       );
//     });

//     return result;
//   }

//   /// Get top 5 holdings by value
//   List<Asset> _getTopHoldings(List<Asset> assets) {
//     final sorted = List<Asset>.from(assets);
//     sorted.sort((a, b) {
//       final valueA = a.quantity * a.currentPrice;
//       final valueB = b.quantity * b.currentPrice;
//       return valueB.compareTo(valueA);
//     });
//     return sorted.take(5).toList();
//   }

//   /// Calculate performance by asset type
//   Map<String, double> _calculateTypePerformance(List<Asset> assets) {
//     final Map<String, double> totalGain = {};
//     final Map<String, double> totalCost = {};

//     for (final asset in assets) {
//       final type = _capitalizeAssetType(asset.assetType);
//       final currentValue = asset.quantity * asset.currentPrice;
//       final costBasis = asset.quantity * asset.averageCost;
//       final gain = currentValue - costBasis;

//       totalGain[type] = (totalGain[type] ?? 0) + gain;
//       totalCost[type] = (totalCost[type] ?? 0) + costBasis;
//     }

//     final Map<String, double> performance = {};
//     totalGain.forEach((type, gain) {
//       final cost = totalCost[type] ?? 1;
//       performance[type] = cost > 0 ? (gain / cost) * 100 : 0;
//     });

//     return performance;
//   }

//   /// Calculate realized gains from sell transactions
//   double _calculateRealizedGains(List transactions) {
//     double realizedGain = 0;

//     for (final transaction in transactions) {
//       if (transaction.type.toLowerCase() == 'sell') {
//         // For sell transactions, we'd ideally need the original purchase price
//         // For now, estimate based on transaction data
//         // In a real app, you'd track cost basis properly
//         realizedGain +=
//             transaction.quantity *
//             transaction.pricePerUnit *
//             0.15; // Assume 15% gain
//       }
//     }

//     return realizedGain;
//   }

//   /// Get color for asset type
//   Color _getAssetTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'stock':
//         return Colors.blue;
//       case 'crypto':
//         return Colors.orange;
//       case 'etf':
//         return Colors.green;
//       case 'bond':
//         return Colors.purple;
//       case 'commodity':
//         return Colors.amber;
//       default:
//         return Colors.grey;
//     }
//   }

//   /// Get icon for asset type
//   IconData _getAssetTypeIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'stock':
//         return Icons.trending_up;
//       case 'crypto':
//         return Icons.currency_bitcoin;
//       case 'etf':
//         return Icons.pie_chart;
//       case 'bond':
//         return Icons.account_balance;
//       case 'commodity':
//         return Icons.gas_meter;
//       default:
//         return Icons.attach_money;
//     }
//   }

//   /// Capitalize asset type for display
//   String _capitalizeAssetType(String type) {
//     if (type.isEmpty) return type;
//     return type[0].toUpperCase() + type.substring(1);
//   }

//   /// Format date based on selected period
//   String _formatDateForPeriod(DateTime date) {
//     switch (_selectedPeriod) {
//       case '1W':
//         return '${date.month}/${date.day}';
//       case '1M':
//       case '3M':
//         return '${date.month}/${date.day}';
//       case '6M':
//       case '1Y':
//       case 'All':
//         return '${date.month}/${date.year % 100}';
//       default:
//         return '${date.month}/${date.day}';
//     }
//   }
// }

// /// Chart data point model
// class ChartDataPoint {
//   final DateTime date;
//   final double value;

//   ChartDataPoint(this.date, this.value);
// }

// /// Allocation data model
// class AllocationData {
//   final double value;
//   final double percentage;
//   final Color color;
//   final IconData icon;

//   AllocationData({
//     required this.value,
//     required this.percentage,
//     required this.color,
//     required this.icon,
//   });
// }



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:math' as math;
// import '../models/asset.dart';
// import '../services/portfolio_provider.dart';
// import '../widgets/app_drawer.dart';
// import '../utils/formatters.dart';

// /// Analytics and Charts Screen
// /// 
// /// Displays comprehensive portfolio analytics with multiple interactive charts:
// /// - Portfolio performance over time
// /// - Asset allocation pie chart
// /// - Top holdings bar chart
// /// - Performance comparison by asset type
// /// - Gains/losses breakdown
// class ChartsScreen extends StatefulWidget {
//   const ChartsScreen({super.key});

//   @override
//   State<ChartsScreen> createState() => _ChartsScreenState();
// }

// class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
//   /// Selected time period for charts
//   String _selectedPeriod = '1M';
  
//   /// Available time periods
//   final List<String> _periods = ['1W', '1M', '3M', '6M', '1Y', 'All'];
  
//   /// Animation controller for chart animations
//   late AnimationController _animationController;
  
//   /// Touched section index for pie chart
//   int _touchedPieIndex = -1;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   /// Refresh data from database
//   Future<void> _refreshData() async {
//     final provider = Provider.of<PortfolioProvider>(context, listen: false);
//     await provider.refresh();
//     _animationController.reset();
//     _animationController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       drawer: AppDrawer(currentRoute: '/charts'),
//       body: _buildBody(),
//     );
//   }

//   /// Build app bar with time period selector
//   PreferredSizeWidget _buildAppBar() {
//     final theme = Theme.of(context);
    
//     return AppBar(
//       leading: Builder(
//         builder: (context) => IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () => Scaffold.of(context).openDrawer(),
//           tooltip: 'Open menu',
//         ),
//       ),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Analytics'),
//           DropdownButton<String>(
//             value: _selectedPeriod,
//             isDense: true,
//             underline: Container(),
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withOpacity(0.7),
//             ),
//             items: _periods.map((String period) {
//               return DropdownMenuItem<String>(
//                 value: period,
//                 child: Text(period),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               if (newValue != null) {
//                 setState(() {
//                   _selectedPeriod = newValue;
//                 });
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build main body with all charts
//   Widget _buildBody() {
//     return Consumer<PortfolioProvider>(
//       builder: (context, provider, child) {
//         if (provider.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!provider.hasAssets) {
//           return _buildEmptyState();
//         }

//         return RefreshIndicator(
//           onRefresh: _refreshData,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Portfolio Performance Chart
//                 _buildPortfolioPerformanceChart(provider),
//                 const SizedBox(height: 32),
                
//                 // Asset Allocation Pie Chart
//                 _buildAssetAllocationSection(provider),
//                 const SizedBox(height: 32),
                
//                 // Top Holdings Bar Chart
//                 _buildTopHoldingsSection(provider),
//                 const SizedBox(height: 32),
                
//                 // Performance Comparison
//                 _buildPerformanceComparison(provider),
//                 const SizedBox(height: 32),
                
//                 // Gains/Losses Breakdown
//                 _buildGainsLossesBreakdown(provider),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   /// Build empty state
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.insert_chart_outlined,
//               size: 80,
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No Data Available',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Add some assets to your portfolio to see analytics',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build portfolio performance chart
//   Widget _buildPortfolioPerformanceChart(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final currentValue = provider.summary?.totalValue ?? 0;
//     final historicalData = _generateHistoricalData(currentValue);
    
//     final isPositive = historicalData.last.value >= historicalData.first.value;
//     final primaryColor = isPositive ? Colors.green : Colors.red;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Portfolio Performance',
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       Formatters.formatCurrency(currentValue),
//                       style: theme.textTheme.headlineSmall?.copyWith(
//                         color: primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 _buildPerformanceBadge(historicalData, primaryColor),
//               ],
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 200,
//               child: FadeTransition(
//                 opacity: _animationController,
//                 child: LineChart(
//                   _createLineChartData(historicalData, primaryColor),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build performance badge
//   Widget _buildPerformanceBadge(List<ChartDataPoint> data, Color color) {
//     final changePercent = ((data.last.value - data.first.value) / data.first.value) * 100;
//     final isPositive = changePercent >= 0;
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isPositive ? Icons.trending_up : Icons.trending_down,
//             color: color,
//             size: 18,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Create line chart data
//   LineChartData _createLineChartData(List<ChartDataPoint> data, Color primaryColor) {
//     final spots = data.asMap().entries.map((entry) {
//       return FlSpot(entry.key.toDouble(), entry.value.value);
//     }).toList();

//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         horizontalInterval: (data.map((d) => d.value).reduce(math.max) - 
//                            data.map((d) => d.value).reduce(math.min)) / 4,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//             strokeWidth: 1,
//           );
//         },
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: (data.length / 5).ceilToDouble(),
//             getTitlesWidget: (value, meta) {
//               if (value.toInt() >= data.length) return const SizedBox();
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(
//                   _formatDateForPeriod(data[value.toInt()].date),
//                   style: const TextStyle(fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 Formatters.formatCompactCurrency(value),
//                 style: const TextStyle(fontSize: 10),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       minX: 0,
//       maxX: (data.length - 1).toDouble(),
//       minY: data.map((d) => d.value).reduce(math.min) * 0.95,
//       maxY: data.map((d) => d.value).reduce(math.max) * 1.05,
//       lineBarsData: [
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           curveSmoothness: 0.35,
//           color: primaryColor,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 primaryColor.withOpacity(0.3),
//                 primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
//           getTooltipItems: (List<LineBarSpot> touchedSpots) {
//             return touchedSpots.map((spot) {
//               return LineTooltipItem(
//                 '${Formatters.formatCurrency(spot.y)}\n${_formatDateForPeriod(data[spot.x.toInt()].date)}',
//                 TextStyle(
//                   color: primaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               );
//             }).toList();
//           },
//         ),
//         handleBuiltInTouches: true,
//         getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
//           return spotIndexes.map((spotIndex) {
//             return TouchedSpotIndicatorData(
//               FlLine(color: primaryColor, strokeWidth: 2),
//               FlDotData(
//                 getDotPainter: (spot, percent, barData, index) {
//                   return FlDotCirclePainter(
//                     radius: 6,
//                     color: primaryColor,
//                     strokeWidth: 2,
//                     strokeColor: Theme.of(context).colorScheme.surface,
//                   );
//                 },
//               ),
//             );
//           }).toList();
//         },
//       ),
//     );
//   }

//   /// Build asset allocation section
//   Widget _buildAssetAllocationSection(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final allocation = _calculateAssetAllocation(provider.assets);

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Asset Allocation',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 200,
//               child: FadeTransition(
//                 opacity: _animationController,
//                 child: Row(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: PieChart(
//                         _createPieChartData(allocation),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildPieChartLegend(allocation),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Create pie chart data
//   PieChartData _createPieChartData(Map<String, AllocationData> allocation) {
//     final sections = allocation.entries.map((entry) {
//       final index = allocation.keys.toList().indexOf(entry.key);
//       final isTouched = index == _touchedPieIndex;
//       final radius = isTouched ? 60.0 : 50.0;

//       return PieChartSectionData(
//         color: entry.value.color,
//         value: entry.value.value,
//         title: '${entry.value.percentage.toStringAsFixed(1)}%',
//         radius: radius,
//         titleStyle: TextStyle(
//           fontSize: isTouched ? 18 : 14,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//         badgeWidget: isTouched
//             ? Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: entry.value.color,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//                 child: Icon(
//                   entry.value.icon,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//               )
//             : null,
//         badgePositionPercentageOffset: 1.2,
//       );
//     }).toList();

//     return PieChartData(
//       pieTouchData: PieTouchData(
//         touchCallback: (FlTouchEvent event, pieTouchResponse) {
//           setState(() {
//             if (!event.isInterestedForInteractions ||
//                 pieTouchResponse == null ||
//                 pieTouchResponse.touchedSection == null) {
//               _touchedPieIndex = -1;
//               return;
//             }
//             _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
//           });
//         },
//       ),
//       borderData: FlBorderData(show: false),
//       sectionsSpace: 2,
//       centerSpaceRadius: 0,
//       sections: sections,
//     );
//   }

//   /// Build pie chart legend
//   Widget _buildPieChartLegend(Map<String, AllocationData> allocation) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: allocation.entries.map((entry) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             children: [
//               Container(
//                 width: 16,
//                 height: 16,
//                 decoration: BoxDecoration(
//                   color: entry.value.color,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       entry.key,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       Formatters.formatCurrency(entry.value.value),
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   /// Build top holdings section
//   Widget _buildTopHoldingsSection(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final topHoldings = _getTopHoldings(provider.assets);
//     final totalValue = provider.summary?.totalValue ?? 1;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Top 5 Holdings',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 300,
//               child: FadeTransition(
//                 opacity: _animationController,
//                 child: BarChart(
//                   _createBarChartData(topHoldings, totalValue),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Create bar chart data
//   BarChartData _createBarChartData(List<Asset> assets, double totalValue) {
//     final barGroups = assets.asMap().entries.map((entry) {
//       final asset = entry.value;
//       final value = asset.quantity * asset.currentPrice;
//       final color = _getAssetTypeColor(asset.assetType);

//       return BarChartGroupData(
//         x: entry.key,
//         barRods: [
//           BarChartRodData(
//             toY: value,
//             color: color,
//             width: 20,
//             borderRadius: const BorderRadius.only(
//               topRight: Radius.circular(6),
//               bottomRight: Radius.circular(6),
//             ),
//             backDrawRodData: BackgroundBarChartRodData(
//               show: true,
//               toY: assets.map((a) => a.quantity * a.currentPrice).reduce(math.max),
//               color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
//             ),
//           ),
//         ],
//         showingTooltipIndicators: [0],
//       );
//     }).toList();

//     return BarChartData(
//       alignment: BarChartAlignment.spaceAround,
//       maxY: assets.isEmpty ? 100 : assets.map((a) => a.quantity * a.currentPrice).reduce(math.max) * 1.1,
//       barTouchData: BarTouchData(
//         enabled: true,
//         touchTooltipData: BarTouchTooltipData(
//           getTooltipColor: (group) => Theme.of(context).colorScheme.surface,
//           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//             final asset = assets[groupIndex];
//             final value = asset.quantity * asset.currentPrice;
//             final percentage = (value / totalValue) * 100;
//             return BarTooltipItem(
//               '${asset.symbol}\n${Formatters.formatCurrency(value)}\n${percentage.toStringAsFixed(1)}%',
//               TextStyle(
//                 color: _getAssetTypeColor(asset.assetType),
//                 fontWeight: FontWeight.bold,
//               ),
//             );
//           },
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             getTitlesWidget: (value, meta) {
//               if (value.toInt() >= assets.length) return const SizedBox();
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(
//                   assets[value.toInt()].symbol,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               );
//             },
//             reservedSize: 32,
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 Formatters.formatCompactCurrency(value),
//                 style: const TextStyle(fontSize: 10),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       barGroups: barGroups,
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//             strokeWidth: 1,
//           );
//         },
//       ),
//     );
//   }

//   /// Build performance comparison section
//   Widget _buildPerformanceComparison(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final performance = _calculateTypePerformance(provider.assets);

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Performance by Asset Type',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...performance.entries.map((entry) {
//               return _buildPerformanceCard(
//                 entry.key,
//                 entry.value,
//                 _getAssetTypeColor(entry.key.toLowerCase()),
//                 _getAssetTypeIcon(entry.key.toLowerCase()),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build individual performance card
//   Widget _buildPerformanceCard(String type, double gainPercent, Color color, IconData icon) {
//     final isPositive = gainPercent >= 0;
//     final displayColor = isPositive ? Colors.green : Colors.red;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   type,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Return',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Row(
//             children: [
//               Icon(
//                 isPositive ? Icons.trending_up : Icons.trending_down,
//                 color: displayColor,
//                 size: 20,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 '${isPositive ? '+' : ''}${gainPercent.toStringAsFixed(2)}%',
//                 style: TextStyle(
//                   color: displayColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build gains/losses breakdown section
//   Widget _buildGainsLossesBreakdown(PortfolioProvider provider) {
//     final theme = Theme.of(context);
//     final unrealizedGain = provider.summary?.totalGain ?? 0;
//     final unrealizedPercent = provider.summary?.totalGainPercent ?? 0;
    
//     // Calculate realized gains from transaction history
//     final realizedGain = _calculateRealizedGains(provider.transactions);
//     final totalInvested = provider.summary?.totalCost ?? 1;
//     final realizedPercent = totalInvested > 0 ? ((realizedGain / totalInvested) * 100).toDouble() : 0.0;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Gains & Losses',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildGainLossGauge(
//                     'Unrealized',
//                     unrealizedGain,
//                     unrealizedPercent,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildGainLossGauge(
//                     'Realized',
//                     realizedGain,
//                     realizedPercent,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build gain/loss gauge widget
//   Widget _buildGainLossGauge(String label, double amount, double percent) {
//     final theme = Theme.of(context);
//     final isPositive = amount >= 0;
//     final color = isPositive ? Colors.green : Colors.red;
    
//     // Normalize percent to 0-1 range for gauge (cap at ±100%)
//     final normalizedPercent = (percent.abs().clamp(0, 100) / 100);

//     return FadeTransition(
//       opacity: _animationController,
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 120,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 SizedBox(
//                   height: 120,
//                   width: 120,
//                   child: CircularProgressIndicator(
//                     value: normalizedPercent,
//                     strokeWidth: 12,
//                     backgroundColor: theme.colorScheme.surfaceContainerHighest,
//                     valueColor: AlwaysStoppedAnimation<Color>(color),
//                   ),
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       Formatters.formatCurrency(amount),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Generate historical data for portfolio performance chart
//   List<ChartDataPoint> _generateHistoricalData(double currentValue) {
//     final dataPoints = <ChartDataPoint>[];
//     final now = DateTime.now();
//     int days;

//     switch (_selectedPeriod) {
//       case '1W':
//         days = 7;
//         break;
//       case '1M':
//         days = 30;
//         break;
//       case '3M':
//         days = 90;
//         break;
//       case '6M':
//         days = 180;
//         break;
//       case '1Y':
//         days = 365;
//         break;
//       case 'All':
//         days = 730; // 2 years
//         break;
//       default:
//         days = 30;
//     }

//     // Generate realistic trending data
//     final random = math.Random(42); // Fixed seed for consistency
//     final startValue = currentValue * (0.7 + random.nextDouble() * 0.3); // 70-100% of current
//     final trend = (currentValue - startValue) / days;
    
//     for (int i = 0; i <= days; i++) {
//       final date = now.subtract(Duration(days: days - i));
//       final trendValue = startValue + (trend * i);
      
//       // Add some random volatility (±5%)
//       final volatility = trendValue * 0.05 * (random.nextDouble() * 2 - 1);
//       final value = trendValue + volatility;
      
//       dataPoints.add(ChartDataPoint(date, value));
//     }

//     return dataPoints;
//   }

//   /// Calculate asset allocation by type
//   Map<String, AllocationData> _calculateAssetAllocation(List<Asset> assets) {
//     final Map<String, double> allocation = {};
//     double totalValue = 0;

//     for (final asset in assets) {
//       final value = asset.quantity * asset.currentPrice;
//       final type = asset.assetType.toLowerCase();
//       allocation[type] = (allocation[type] ?? 0) + value;
//       totalValue += value;
//     }

//     final Map<String, AllocationData> result = {};
//     allocation.forEach((type, value) {
//       final percentage = totalValue > 0 ? ((value / totalValue) * 100).toDouble() : 0.0;
//       result[_capitalizeAssetType(type)] = AllocationData(
//         value: value,
//         percentage: percentage,
//         color: _getAssetTypeColor(type),
//         icon: _getAssetTypeIcon(type),
//       );
//     });

//     return result;
//   }

//   /// Get top 5 holdings by value
//   List<Asset> _getTopHoldings(List<Asset> assets) {
//     final sorted = List<Asset>.from(assets);
//     sorted.sort((a, b) {
//       final valueA = a.quantity * a.currentPrice;
//       final valueB = b.quantity * b.currentPrice;
//       return valueB.compareTo(valueA);
//     });
//     return sorted.take(5).toList();
//   }

//   /// Calculate performance by asset type
//   Map<String, double> _calculateTypePerformance(List<Asset> assets) {
//     final Map<String, double> totalGain = {};
//     final Map<String, double> totalCost = {};

//     for (final asset in assets) {
//       final type = _capitalizeAssetType(asset.assetType);
//       final currentValue = asset.quantity * asset.currentPrice;
//       final costBasis = asset.quantity * asset.averageCost;
//       final gain = currentValue - costBasis;

//       totalGain[type] = (totalGain[type] ?? 0) + gain;
//       totalCost[type] = (totalCost[type] ?? 0) + costBasis;
//     }

//     final Map<String, double> performance = {};
//     totalGain.forEach((type, gain) {
//       final cost = totalCost[type] ?? 1;
//       performance[type] = cost > 0 ? (gain / cost) * 100 : 0;
//     });

//     return performance;
//   }

//   /// Calculate realized gains from sell transactions
//   double _calculateRealizedGains(List transactions) {
//     double realizedGain = 0;

//     for (final transaction in transactions) {
//       if (transaction.type.toLowerCase() == 'sell') {
//         // For sell transactions, we'd ideally need the original purchase price
//         // For now, estimate based on transaction data
//         // In a real app, you'd track cost basis properly
//         realizedGain += transaction.quantity * transaction.pricePerUnit * 0.15; // Assume 15% gain
//       }
//     }

//     return realizedGain;
//   }

//   /// Get color for asset type
//   Color _getAssetTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'stock':
//         return Colors.blue;
//       case 'crypto':
//         return Colors.orange;
//       case 'etf':
//         return Colors.green;
//       case 'bond':
//         return Colors.purple;
//       case 'commodity':
//         return Colors.amber;
//       default:
//         return Colors.grey;
//     }
//   }

//   /// Get icon for asset type
//   IconData _getAssetTypeIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'stock':
//         return Icons.trending_up;
//       case 'crypto':
//         return Icons.currency_bitcoin;
//       case 'etf':
//         return Icons.pie_chart;
//       case 'bond':
//         return Icons.account_balance;
//       case 'commodity':
//         return Icons.gas_meter;
//       default:
//         return Icons.attach_money;
//     }
//   }

//   /// Capitalize asset type for display
//   String _capitalizeAssetType(String type) {
//     if (type.isEmpty) return type;
//     return type[0].toUpperCase() + type.substring(1);
//   }

//   /// Format date based on selected period
//   String _formatDateForPeriod(DateTime date) {
//     switch (_selectedPeriod) {
//       case '1W':
//         return '${date.month}/${date.day}';
//       case '1M':
//       case '3M':
//         return '${date.month}/${date.day}';
//       case '6M':
//       case '1Y':
//       case 'All':
//         return '${date.month}/${date.year % 100}';
//       default:
//         return '${date.month}/${date.day}';
//     }
//   }
// }

// /// Chart data point model
// class ChartDataPoint {
//   final DateTime date;
//   final double value;

//   ChartDataPoint(this.date, this.value);
// }

// /// Allocation data model
// class AllocationData {
//   final double value;
//   final double percentage;
//   final Color color;
//   final IconData icon;

//   AllocationData({
//     required this.value,
//     required this.percentage,
//     required this.color,
//     required this.icon,
//   });
// }