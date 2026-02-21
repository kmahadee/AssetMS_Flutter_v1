/// Portfolio summary model representing aggregated portfolio metrics
/// 
/// This is a computed model that is not stored in the database.
/// It aggregates data from assets and transactions to provide
/// a complete overview of the user's portfolio performance.
class PortfolioSummary {
  /// Total current market value of all assets
  final double totalValue;

  /// Total cost basis of all assets (total amount invested)
  final double totalCost;

  /// Total unrealized profit/loss in currency units
  /// 
  /// Calculated as: totalValue - totalCost
  final double totalGain;

  /// Total unrealized profit/loss as a percentage
  /// 
  /// Calculated as: (totalGain / totalCost) * 100
  final double totalGainPercent;

  /// Total change in portfolio value from previous close
  /// Also accessible via dayGain for backwards compatibility
  final double dayChange;

  /// Total change in portfolio value from previous close as a percentage
  /// Also accessible via dayGainPercent for backwards compatibility
  final double dayChangePercent;

  /// Total current value of all stock holdings
  final double stocksValue;

  /// Total current value of all cryptocurrency holdings
  final double cryptoValue;

  /// Total current value of all ETF holdings
  final double etfValue;

  /// Number of unique assets in the portfolio
  final int assetCount;

  /// Total number of transactions recorded
  final int transactionCount;

  /// Creates a new PortfolioSummary instance
  /// 
  /// All parameters are required and represent the current state
  /// of the portfolio at the time of calculation
  const PortfolioSummary({
    required this.totalValue,
    required this.totalCost,
    required this.totalGain,
    required this.totalGainPercent,
    required this.dayChange,
    required this.dayChangePercent,
    required this.stocksValue,
    required this.cryptoValue,
    required this.etfValue,
    required this.assetCount,
    required this.transactionCount,
  });

  // Getter aliases for backwards compatibility with home screen
  
  /// Alias for dayChange - today's gain/loss amount
  double get dayGain => dayChange;
  
  /// Alias for dayChangePercent - today's gain/loss percentage
  double get dayGainPercent => dayChangePercent;
  
  /// Alias for totalCost - total amount invested
  double get totalInvested => totalCost;

  /// Creates an empty PortfolioSummary with all values set to zero
  /// 
  /// Useful for initializing state or representing an empty portfolio
  factory PortfolioSummary.empty() {
    return const PortfolioSummary(
      totalValue: 0,
      totalCost: 0,
      totalGain: 0,
      totalGainPercent: 0,
      dayChange: 0,
      dayChangePercent: 0,
      stocksValue: 0,
      cryptoValue: 0,
      etfValue: 0,
      assetCount: 0,
      transactionCount: 0,
    );
  }

  /// Creates a PortfolioSummary from a list of assets
  /// 
  /// This factory constructor computes all summary metrics from the
  /// provided assets. Transaction count must be provided separately.
  /// 
  /// Parameters:
  /// - [assets]: List of Asset objects to summarize
  /// - [transactionCount]: Total number of transactions (optional, defaults to 0)
  factory PortfolioSummary.fromAssets({
    required List<dynamic> assets,
    int transactionCount = 0,
  }) {
    if (assets.isEmpty) {
      return PortfolioSummary.empty().copyWith(
        transactionCount: transactionCount,
      );
    }

    double totalValue = 0;
    double totalCost = 0;
    double dayChange = 0;
    double stocksValue = 0;
    double cryptoValue = 0;
    double etfValue = 0;

    // Aggregate metrics from all assets
    for (var asset in assets) {
      // Assuming asset has these getters: currentValue, totalCost, dayChange
      totalValue += asset.currentValue;
      totalCost += asset.totalCost;
      dayChange += asset.dayChange;

      // Categorize by asset type
      switch (asset.assetType.toLowerCase()) {
        case 'stock':
          stocksValue += asset.currentValue;
          break;
        case 'crypto':
          cryptoValue += asset.currentValue;
          break;
        case 'etf':
          etfValue += asset.currentValue;
          break;
      }
    }

    // Calculate percentages
    final totalGain = totalValue - totalCost;
    final totalGainPercent = totalCost > 0 ? (totalGain / totalCost) * 100 : 0.0;
    
    // Calculate day change percentage
    final previousValue = totalValue - dayChange;
    final dayChangePercent = previousValue > 0 ? (dayChange / previousValue) * 100 : 0.0;

    return PortfolioSummary(
      totalValue: totalValue,
      totalCost: totalCost,
      totalGain: totalGain,
      totalGainPercent: totalGainPercent,
      dayChange: dayChange,
      dayChangePercent: dayChangePercent,
      stocksValue: stocksValue,
      cryptoValue: cryptoValue,
      etfValue: etfValue,
      assetCount: assets.length,
      transactionCount: transactionCount,
    );
  }

  /// Creates a copy of this PortfolioSummary with the given fields replaced
  /// 
  /// Any null parameters will use the current value
  PortfolioSummary copyWith({
    double? totalValue,
    double? totalCost,
    double? totalGain,
    double? totalGainPercent,
    double? dayChange,
    double? dayChangePercent,
    double? stocksValue,
    double? cryptoValue,
    double? etfValue,
    int? assetCount,
    int? transactionCount,
  }) {
    return PortfolioSummary(
      totalValue: totalValue ?? this.totalValue,
      totalCost: totalCost ?? this.totalCost,
      totalGain: totalGain ?? this.totalGain,
      totalGainPercent: totalGainPercent ?? this.totalGainPercent,
      dayChange: dayChange ?? this.dayChange,
      dayChangePercent: dayChangePercent ?? this.dayChangePercent,
      stocksValue: stocksValue ?? this.stocksValue,
      cryptoValue: cryptoValue ?? this.cryptoValue,
      etfValue: etfValue ?? this.etfValue,
      assetCount: assetCount ?? this.assetCount,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  /// Returns true if the portfolio is profitable (positive total gain)
  bool get isProfitable => totalGain > 0;

  /// Returns true if the portfolio is up for the day (positive day change)
  bool get isUpToday => dayChange > 0;

  /// Returns true if the portfolio has any assets
  bool get hasAssets => assetCount > 0;

  /// Returns true if the portfolio has any transactions
  bool get hasTransactions => transactionCount > 0;

  /// Percentage of portfolio value in stocks (0-100)
  double get stocksPercentage {
    if (totalValue == 0) return 0;
    return (stocksValue / totalValue) * 100;
  }

  /// Percentage of portfolio value in crypto (0-100)
  double get cryptoPercentage {
    if (totalValue == 0) return 0;
    return (cryptoValue / totalValue) * 100;
  }

  /// Percentage of portfolio value in ETFs (0-100)
  double get etfPercentage {
    if (totalValue == 0) return 0;
    return (etfValue / totalValue) * 100;
  }

  /// Returns a Map representation of this summary
  /// 
  /// Useful for serialization or debugging
  Map<String, dynamic> toMap() {
    return {
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGain': totalGain,
      'totalGainPercent': totalGainPercent,
      'dayChange': dayChange,
      'dayChangePercent': dayChangePercent,
      'stocksValue': stocksValue,
      'cryptoValue': cryptoValue,
      'etfValue': etfValue,
      'assetCount': assetCount,
      'transactionCount': transactionCount,
    };
  }

  /// Creates a PortfolioSummary from a Map
  /// 
  /// Useful for deserialization
  factory PortfolioSummary.fromMap(Map<String, dynamic> map) {
    return PortfolioSummary(
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      totalGain: (map['totalGain'] as num?)?.toDouble() ?? 0.0,
      totalGainPercent: (map['totalGainPercent'] as num?)?.toDouble() ?? 0.0,
      dayChange: (map['dayChange'] as num?)?.toDouble() ?? 0.0,
      dayChangePercent: (map['dayChangePercent'] as num?)?.toDouble() ?? 0.0,
      stocksValue: (map['stocksValue'] as num?)?.toDouble() ?? 0.0,
      cryptoValue: (map['cryptoValue'] as num?)?.toDouble() ?? 0.0,
      etfValue: (map['etfValue'] as num?)?.toDouble() ?? 0.0,
      assetCount: (map['assetCount'] as num?)?.toInt() ?? 0,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PortfolioSummary &&
        other.totalValue == totalValue &&
        other.totalCost == totalCost &&
        other.totalGain == totalGain &&
        other.totalGainPercent == totalGainPercent &&
        other.dayChange == dayChange &&
        other.dayChangePercent == dayChangePercent &&
        other.stocksValue == stocksValue &&
        other.cryptoValue == cryptoValue &&
        other.etfValue == etfValue &&
        other.assetCount == assetCount &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalValue,
      totalCost,
      totalGain,
      totalGainPercent,
      dayChange,
      dayChangePercent,
      stocksValue,
      cryptoValue,
      etfValue,
      assetCount,
      transactionCount,
    );
  }

  @override
  String toString() {
    return 'PortfolioSummary(totalValue: $totalValue, totalCost: $totalCost, totalGain: $totalGain, totalGainPercent: $totalGainPercent, dayChange: $dayChange, dayChangePercent: $dayChangePercent, stocksValue: $stocksValue, cryptoValue: $cryptoValue, etfValue: $etfValue, assetCount: $assetCount, transactionCount: $transactionCount)';
  }
}



// /// Portfolio summary model representing aggregated portfolio metrics
// /// 
// /// This is a computed model that is not stored in the database.
// /// It aggregates data from assets and transactions to provide
// /// a complete overview of the user's portfolio performance.
// class PortfolioSummary {
//   /// Total current market value of all assets
//   final double totalValue;

//   /// Total cost basis of all assets (total amount invested)
//   final double totalCost;

//   /// Total unrealized profit/loss in currency units
//   /// 
//   /// Calculated as: totalValue - totalCost
//   final double totalGain;

//   /// Total unrealized profit/loss as a percentage
//   /// 
//   /// Calculated as: (totalGain / totalCost) * 100
//   final double totalGainPercent;

//   /// Total change in portfolio value from previous close
//   final double dayChange;

//   /// Total change in portfolio value from previous close as a percentage
//   final double dayChangePercent;

//   /// Total current value of all stock holdings
//   final double stocksValue;

//   /// Total current value of all cryptocurrency holdings
//   final double cryptoValue;

//   /// Total current value of all ETF holdings
//   final double etfValue;

//   /// Number of unique assets in the portfolio
//   final int assetCount;

//   /// Total number of transactions recorded
//   final int transactionCount;

//   /// Creates a new PortfolioSummary instance
//   /// 
//   /// All parameters are required and represent the current state
//   /// of the portfolio at the time of calculation
//   const PortfolioSummary({
//     required this.totalValue,
//     required this.totalCost,
//     required this.totalGain,
//     required this.totalGainPercent,
//     required this.dayChange,
//     required this.dayChangePercent,
//     required this.stocksValue,
//     required this.cryptoValue,
//     required this.etfValue,
//     required this.assetCount,
//     required this.transactionCount,
//   });

//   /// Creates an empty PortfolioSummary with all values set to zero
//   /// 
//   /// Useful for initializing state or representing an empty portfolio
//   factory PortfolioSummary.empty() {
//     return const PortfolioSummary(
//       totalValue: 0,
//       totalCost: 0,
//       totalGain: 0,
//       totalGainPercent: 0,
//       dayChange: 0,
//       dayChangePercent: 0,
//       stocksValue: 0,
//       cryptoValue: 0,
//       etfValue: 0,
//       assetCount: 0,
//       transactionCount: 0,
//     );
//   }

//   /// Creates a PortfolioSummary from a list of assets
//   /// 
//   /// This factory constructor computes all summary metrics from the
//   /// provided assets. Transaction count must be provided separately.
//   /// 
//   /// Parameters:
//   /// - [assets]: List of Asset objects to summarize
//   /// - [transactionCount]: Total number of transactions (optional, defaults to 0)
//   factory PortfolioSummary.fromAssets({
//     required List<dynamic> assets,
//     int transactionCount = 0,
//   }) {
//     if (assets.isEmpty) {
//       return PortfolioSummary.empty().copyWith(
//         transactionCount: transactionCount,
//       );
//     }

//     double totalValue = 0;
//     double totalCost = 0;
//     double dayChange = 0;
//     double stocksValue = 0;
//     double cryptoValue = 0;
//     double etfValue = 0;

//     // Aggregate metrics from all assets
//     for (var asset in assets) {
//       // Assuming asset has these getters: currentValue, totalCost, dayChange
//       totalValue += asset.currentValue;
//       totalCost += asset.totalCost;
//       dayChange += asset.dayChange;

//       // Categorize by asset type
//       switch (asset.assetType.toLowerCase()) {
//         case 'stock':
//           stocksValue += asset.currentValue;
//           break;
//         case 'crypto':
//           cryptoValue += asset.currentValue;
//           break;
//         case 'etf':
//           etfValue += asset.currentValue;
//           break;
//       }
//     }

//     // Calculate percentages
//     final totalGain = totalValue - totalCost;
//     final totalGainPercent = totalCost > 0 ? (totalGain / totalCost) * 100 : 0.0;
    
//     // Calculate day change percentage
//     final previousValue = totalValue - dayChange;
//     final dayChangePercent = previousValue > 0 ? (dayChange / previousValue) * 100 : 0.0;

//     return PortfolioSummary(
//       totalValue: totalValue,
//       totalCost: totalCost,
//       totalGain: totalGain,
//       totalGainPercent: totalGainPercent,
//       dayChange: dayChange,
//       dayChangePercent: dayChangePercent,
//       stocksValue: stocksValue,
//       cryptoValue: cryptoValue,
//       etfValue: etfValue,
//       assetCount: assets.length,
//       transactionCount: transactionCount,
//     );
//   }

//   /// Creates a copy of this PortfolioSummary with the given fields replaced
//   /// 
//   /// Any null parameters will use the current value
//   PortfolioSummary copyWith({
//     double? totalValue,
//     double? totalCost,
//     double? totalGain,
//     double? totalGainPercent,
//     double? dayChange,
//     double? dayChangePercent,
//     double? stocksValue,
//     double? cryptoValue,
//     double? etfValue,
//     int? assetCount,
//     int? transactionCount,
//   }) {
//     return PortfolioSummary(
//       totalValue: totalValue ?? this.totalValue,
//       totalCost: totalCost ?? this.totalCost,
//       totalGain: totalGain ?? this.totalGain,
//       totalGainPercent: totalGainPercent ?? this.totalGainPercent,
//       dayChange: dayChange ?? this.dayChange,
//       dayChangePercent: dayChangePercent ?? this.dayChangePercent,
//       stocksValue: stocksValue ?? this.stocksValue,
//       cryptoValue: cryptoValue ?? this.cryptoValue,
//       etfValue: etfValue ?? this.etfValue,
//       assetCount: assetCount ?? this.assetCount,
//       transactionCount: transactionCount ?? this.transactionCount,
//     );
//   }

//   /// Returns true if the portfolio is profitable (positive total gain)
//   bool get isProfitable => totalGain > 0;

//   /// Returns true if the portfolio is up for the day (positive day change)
//   bool get isUpToday => dayChange > 0;

//   /// Returns true if the portfolio has any assets
//   bool get hasAssets => assetCount > 0;

//   /// Returns true if the portfolio has any transactions
//   bool get hasTransactions => transactionCount > 0;

//   /// Percentage of portfolio value in stocks (0-100)
//   double get stocksPercentage {
//     if (totalValue == 0) return 0;
//     return (stocksValue / totalValue) * 100;
//   }

//   /// Percentage of portfolio value in crypto (0-100)
//   double get cryptoPercentage {
//     if (totalValue == 0) return 0;
//     return (cryptoValue / totalValue) * 100;
//   }

//   /// Percentage of portfolio value in ETFs (0-100)
//   double get etfPercentage {
//     if (totalValue == 0) return 0;
//     return (etfValue / totalValue) * 100;
//   }

//   /// Returns a Map representation of this summary
//   /// 
//   /// Useful for serialization or debugging
//   Map<String, dynamic> toMap() {
//     return {
//       'totalValue': totalValue,
//       'totalCost': totalCost,
//       'totalGain': totalGain,
//       'totalGainPercent': totalGainPercent,
//       'dayChange': dayChange,
//       'dayChangePercent': dayChangePercent,
//       'stocksValue': stocksValue,
//       'cryptoValue': cryptoValue,
//       'etfValue': etfValue,
//       'assetCount': assetCount,
//       'transactionCount': transactionCount,
//     };
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
    
//     return other is PortfolioSummary &&
//         other.totalValue == totalValue &&
//         other.totalCost == totalCost &&
//         other.totalGain == totalGain &&
//         other.totalGainPercent == totalGainPercent &&
//         other.dayChange == dayChange &&
//         other.dayChangePercent == dayChangePercent &&
//         other.stocksValue == stocksValue &&
//         other.cryptoValue == cryptoValue &&
//         other.etfValue == etfValue &&
//         other.assetCount == assetCount &&
//         other.transactionCount == transactionCount;
//   }

//   @override
//   int get hashCode {
//     return Object.hash(
//       totalValue,
//       totalCost,
//       totalGain,
//       totalGainPercent,
//       dayChange,
//       dayChangePercent,
//       stocksValue,
//       cryptoValue,
//       etfValue,
//       assetCount,
//       transactionCount,
//     );
//   }

//   @override
//   String toString() {
//     return 'PortfolioSummary(totalValue: $totalValue, totalCost: $totalCost, totalGain: $totalGain, totalGainPercent: $totalGainPercent, dayChange: $dayChange, dayChangePercent: $dayChangePercent, stocksValue: $stocksValue, cryptoValue: $cryptoValue, etfValue: $etfValue, assetCount: $assetCount, transactionCount: $transactionCount)';
//   }
// }