import '../models/asset.dart';
import '../models/portfolio_summary.dart';

/// Static calculation methods for portfolio metrics
/// 
/// This class contains pure calculation functions that don't interact
/// with the database. All methods accept pre-filtered asset lists.
class PortfolioCalculator {
  /// Calculate total portfolio value
  /// 
  /// Sums the current value of all assets
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Total current value
  static double calculateTotalValue(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    return assets.fold(0.0, (sum, asset) => sum + asset.currentValue);
  }

  /// Calculate total cost basis
  /// 
  /// Sums the total cost of all assets
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Total cost basis
  static double calculateTotalCost(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    return assets.fold(0.0, (sum, asset) => sum + asset.totalCost);
  }

  /// Calculate total unrealized gain/loss
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Total unrealized gain (negative for loss)
  static double calculateTotalGain(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    return assets.fold(0.0, (sum, asset) => sum + asset.unrealizedGain);
  }

  /// Calculate total unrealized gain/loss percentage
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Total unrealized gain percentage
  static double calculateTotalGainPercent(List<Asset> assets) {
    final totalCost = calculateTotalCost(assets);
    if (totalCost == 0) return 0.0;
    
    final totalGain = calculateTotalGain(assets);
    return (totalGain / totalCost) * 100;
  }

  /// Calculate total day change in value
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Total change from previous close
  static double calculateDayChange(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    return assets.fold(0.0, (sum, asset) => sum + asset.dayChange);
  }

  /// Calculate total day change percentage
  /// 
  /// Parameters:
  /// - [assets]: List of assets to calculate total for
  /// 
  /// Returns: Percentage change from previous close
  static double calculateDayChangePercent(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    final currentValue = calculateTotalValue(assets);
    final dayChange = calculateDayChange(assets);
    final previousValue = currentValue - dayChange;
    
    if (previousValue == 0) return 0.0;
    
    return (dayChange / previousValue) * 100;
  }

  /// Calculate total value by asset type
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [assetType]: Type to filter by ('stock', 'crypto', 'etf')
  /// 
  /// Returns: Total value of assets matching the type
  static double calculateValueByType(List<Asset> assets, String assetType) {
    if (assets.isEmpty) return 0.0;
    
    return assets
        .where((asset) => asset.assetType.toLowerCase() == assetType.toLowerCase())
        .fold(0.0, (sum, asset) => sum + asset.currentValue);
  }

  /// Calculate portfolio allocation percentages
  /// 
  /// Returns a map of asset types to their percentage of total portfolio
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Map of asset type to percentage
  static Map<String, double> calculateAllocation(List<Asset> assets) {
    final totalValue = calculateTotalValue(assets);
    
    if (totalValue == 0) {
      return {'stock': 0.0, 'crypto': 0.0, 'etf': 0.0};
    }

    final stockValue = calculateValueByType(assets, 'stock');
    final cryptoValue = calculateValueByType(assets, 'crypto');
    final etfValue = calculateValueByType(assets, 'etf');

    return {
      'stock': (stockValue / totalValue) * 100,
      'crypto': (cryptoValue / totalValue) * 100,
      'etf': (etfValue / totalValue) * 100,
    };
  }

  /// Calculate portfolio diversity score
  /// 
  /// Returns a score from 0-100 based on:
  /// - Number of assets
  /// - Distribution across asset types
  /// - Distribution of value across assets
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Diversity score (0-100)
  static double calculateDiversityScore(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    if (assets.length == 1) return 20.0;

    // Score component 1: Number of assets (max 30 points)
    final countScore = (assets.length * 3).clamp(0, 30).toDouble();

    // Score component 2: Type distribution (max 30 points)
    final types = assets.map((a) => a.assetType).toSet();
    final typeScore = (types.length * 10).toDouble();

    // Score component 3: Value distribution (max 40 points)
    final totalValue = calculateTotalValue(assets);
    final values = assets.map((a) => a.currentValue / totalValue).toList();
    
    // Calculate Herfindahl index (lower is more diverse)
    final herfindahl = values.fold(0.0, (sum, share) => sum + (share * share));
    
    // Convert to diversity score (invert and scale)
    final distributionScore = (1 - herfindahl) * 40;

    return countScore + typeScore + distributionScore;
  }

  /// Get top performing assets
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [limit]: Number of top assets to return
  /// 
  /// Returns: List of top performing assets by gain percentage
  static List<Asset> getTopPerformers(List<Asset> assets, {int limit = 5}) {
    if (assets.isEmpty) return [];
    
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) => b.unrealizedGainPercent.compareTo(a.unrealizedGainPercent));
    
    return sorted.take(limit).toList();
  }

  /// Get worst performing assets
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [limit]: Number of worst assets to return
  /// 
  /// Returns: List of worst performing assets by gain percentage
  static List<Asset> getWorstPerformers(List<Asset> assets, {int limit = 5}) {
    if (assets.isEmpty) return [];
    
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) => a.unrealizedGainPercent.compareTo(b.unrealizedGainPercent));
    
    return sorted.take(limit).toList();
  }

  /// Get assets sorted by value
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [descending]: If true, sort from highest to lowest value
  /// 
  /// Returns: Sorted list of assets
  static List<Asset> getAssetsByValue(
    List<Asset> assets, {
    bool descending = true,
  }) {
    if (assets.isEmpty) return [];
    
    final sorted = List<Asset>.from(assets);
    sorted.sort((a, b) {
      return descending
          ? b.currentValue.compareTo(a.currentValue)
          : a.currentValue.compareTo(b.currentValue);
    });
    
    return sorted;
  }

  /// Calculate weighted average cost of entire portfolio
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Weighted average cost per dollar invested
  static double calculateWeightedAverageCost(List<Asset> assets) {
    if (assets.isEmpty) return 0.0;
    
    final totalCost = calculateTotalCost(assets);
    if (totalCost == 0) return 0.0;
    
    return totalCost / assets.fold(0.0, (sum, asset) => sum + asset.quantity);
  }

  /// Calculate portfolio summary
  /// 
  /// Convenience method to generate a complete PortfolioSummary object
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [transactionCount]: Total number of transactions (optional)
  /// 
  /// Returns: Complete PortfolioSummary object
  static PortfolioSummary calculateSummary(
    List<Asset> assets, {
    int transactionCount = 0,
  }) {
    return PortfolioSummary(
      totalValue: calculateTotalValue(assets),
      totalCost: calculateTotalCost(assets),
      totalGain: calculateTotalGain(assets),
      totalGainPercent: calculateTotalGainPercent(assets),
      dayChange: calculateDayChange(assets),
      dayChangePercent: calculateDayChangePercent(assets),
      stocksValue: calculateValueByType(assets, 'stock'),
      cryptoValue: calculateValueByType(assets, 'crypto'),
      etfValue: calculateValueByType(assets, 'etf'),
      assetCount: assets.length,
      transactionCount: transactionCount,
    );
  }

  /// Calculate return on investment (ROI)
  /// 
  /// Same as total gain percentage, provided for clarity
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: ROI percentage
  static double calculateROI(List<Asset> assets) {
    return calculateTotalGainPercent(assets);
  }

  /// Calculate compound annual growth rate (CAGR)
  /// 
  /// NOTE: This is a simplified calculation assuming equal time periods
  /// For accurate CAGR, you need transaction dates which aren't in Asset model
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// - [years]: Number of years invested (default 1)
  /// 
  /// Returns: Estimated CAGR percentage
  static double calculateCAGR(List<Asset> assets, {double years = 1.0}) {
    if (years <= 0) return 0.0;
    
    final totalCost = calculateTotalCost(assets);
    final totalValue = calculateTotalValue(assets);
    
    if (totalCost == 0) return 0.0;
    
    // CAGR = (Ending Value / Beginning Value)^(1/years) - 1
    final ratio = totalValue / totalCost;
    final cagr = (pow(ratio, 1 / years) - 1) * 100;
    
    return cagr;
  }

  /// Helper function for power calculation
  static double pow(double base, double exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base;
    
    double result = 1.0;
    double currentBase = base;
    int exp = exponent.abs().toInt();
    
    while (exp > 0) {
      if (exp % 2 == 1) {
        result *= currentBase;
      }
      currentBase *= currentBase;
      exp ~/= 2;
    }
    
    return exponent < 0 ? 1 / result : result;
  }

  /// Get asset with highest value
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Asset with highest current value, or null if list is empty
  static Asset? getLargestHolding(List<Asset> assets) {
    if (assets.isEmpty) return null;
    
    return assets.reduce((a, b) => 
      a.currentValue > b.currentValue ? a : b
    );
  }

  /// Get asset with lowest value
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Asset with lowest current value, or null if list is empty
  static Asset? getSmallestHolding(List<Asset> assets) {
    if (assets.isEmpty) return null;
    
    return assets.reduce((a, b) => 
      a.currentValue < b.currentValue ? a : b
    );
  }

  /// Calculate total number of assets by type
  /// 
  /// Parameters:
  /// - [assets]: List of assets
  /// 
  /// Returns: Map of asset type to count
  static Map<String, int> getAssetCountByType(List<Asset> assets) {
    return {
      'stock': assets.where((a) => a.assetType == 'stock').length,
      'crypto': assets.where((a) => a.assetType == 'crypto').length,
      'etf': assets.where((a) => a.assetType == 'etf').length,
    };
  }
}