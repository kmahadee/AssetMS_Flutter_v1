/// Asset model representing a financial asset in a user's portfolio
///
/// This class handles individual assets including stocks, cryptocurrencies,
/// and ETFs with their pricing, quantity, and performance metrics.
class Asset {
  /// Unique identifier for the asset (SQLite primary key)
  /// Null for new assets that haven't been saved to the database yet
  final int? id;

  /// Foreign key reference to the user who owns this asset
  final int userId;

  /// Trading symbol or ticker (e.g., 'AAPL', 'BTC', 'SPY')
  final String symbol;

  /// Full name of the asset (e.g., 'Apple Inc.', 'Bitcoin', 'S&P 500 ETF')
  final String name;

  /// Type of asset: 'stock', 'crypto', or 'etf'
  final String assetType;

  /// Current market price per unit
  final double currentPrice;

  /// Previous day's closing price
  final double previousClose;

  /// Number of units/shares owned
  final double quantity;

  /// Average cost per unit (weighted average purchase price)
  final double averageCost;

  /// Timestamp when the asset was first added to the portfolio
  final DateTime createdAt;

  /// Timestamp of the last update to this asset
  final DateTime updatedAt;

  /// Creates a new Asset instance
  ///
  /// [id] is nullable for new assets not yet saved to database
  /// All other parameters are required
  const Asset({
    this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.assetType,
    required this.currentPrice,
    required this.previousClose,
    required this.quantity,
    required this.averageCost,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Current total value of this asset holding
  ///
  /// Calculated as: currentPrice * quantity
  double get currentValue => currentPrice * quantity;

  /// Total cost basis of this asset holding
  ///
  /// Calculated as: averageCost * quantity
  double get totalCost => averageCost * quantity;

  /// Unrealized profit/loss in currency units
  ///
  /// Calculated as: currentValue - totalCost
  /// Positive values indicate profit, negative values indicate loss
  double get unrealizedGain => currentValue - totalCost;

  /// Unrealized profit/loss as a percentage
  ///
  /// Calculated as: (unrealizedGain / totalCost) * 100
  /// Returns 0 if totalCost is 0 to avoid division by zero
  double get unrealizedGainPercent {
    if (totalCost == 0) return 0;
    return (unrealizedGain / totalCost) * 100;
  }

  /// Change in value from previous close in currency units
  ///
  /// Calculated as: (currentPrice - previousClose) * quantity
  double get dayChange => (currentPrice - previousClose) * quantity;

  /// Change in value from previous close as a percentage
  ///
  /// Calculated as: ((currentPrice - previousClose) / previousClose) * 100
  /// Returns 0 if previousClose is 0 to avoid division by zero
  double get dayChangePercent {
    if (previousClose == 0) return 0;
    return ((currentPrice - previousClose) / previousClose) * 100;
  }

  /// Converts the Asset object to a Map for SQLite storage
  ///
  /// DateTime objects are converted to milliseconds since epoch
  /// Excludes id if it's null (for INSERT operations)
  // Map<String, dynamic> toMap() {
  //   final map = <String, dynamic>{
  //     'userId': userId,
  //     'symbol': symbol,
  //     'name': name,
  //     'assetType': assetType,
  //     'currentPrice': currentPrice,
  //     'previousClose': previousClose,
  //     'quantity': quantity,
  //     'averageCost': averageCost,
  //     'createdAt': createdAt.millisecondsSinceEpoch,
  //     'updatedAt': updatedAt.millisecondsSinceEpoch,
  //   };

  //   if (id != null) {
  //     map['id'] = id;
  //   }

  //   return map;
  // }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId, // CHANGED: was 'userId'
      'symbol': symbol,
      'name': name,
      'asset_type': assetType, // CHANGED: was 'assetType'
      'current_price': currentPrice, // CHANGED: was 'currentPrice'
      'previous_close': previousClose, // CHANGED: was 'previousClose'
      'quantity': quantity,
      'average_cost': averageCost, // CHANGED: was 'averageCost'
      'created_at':
          createdAt.millisecondsSinceEpoch, // CHANGED: was 'createdAt'
      'updated_at':
          updatedAt.millisecondsSinceEpoch, // CHANGED: was 'updatedAt'
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates an Asset object from a SQLite Map
  ///
  /// Converts millisecond timestamps back to DateTime objects
  // factory Asset.fromMap(Map<String, dynamic> map) {
  //   return Asset(
  //     id: map['id'] as int?,
  //     userId: map['userId'] as int,
  //     symbol: map['symbol'] as String,
  //     name: map['name'] as String,
  //     assetType: map['assetType'] as String,
  //     currentPrice: (map['currentPrice'] as num).toDouble(),
  //     previousClose: (map['previousClose'] as num).toDouble(),
  //     quantity: (map['quantity'] as num).toDouble(),
  //     averageCost: (map['averageCost'] as num).toDouble(),
  //     createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  //     updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
  //   );
  // }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      userId: map['user_id'] as int, // CHANGED: was 'userId'
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      assetType: map['asset_type'] as String, // CHANGED: was 'assetType'
      currentPrice: (map['current_price'] as num)
          .toDouble(), // CHANGED: was 'currentPrice'
      previousClose: (map['previous_close'] as num)
          .toDouble(), // CHANGED: was 'previousClose'
      quantity: (map['quantity'] as num).toDouble(),
      averageCost: (map['average_cost'] as num)
          .toDouble(), // CHANGED: was 'averageCost'
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ), // CHANGED: was 'createdAt'
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int,
      ), // CHANGED: was 'updatedAt'
    );
  }

  /// Creates a copy of this Asset with the given fields replaced
  ///
  /// Any null parameters will use the current value
  Asset copyWith({
    int? id,
    int? userId,
    String? symbol,
    String? name,
    String? assetType,
    double? currentPrice,
    double? previousClose,
    double? quantity,
    double? averageCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      assetType: assetType ?? this.assetType,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClose: previousClose ?? this.previousClose,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates the asset type
  ///
  /// Valid types are: 'stock', 'crypto', 'etf'
  /// Returns true if valid, false otherwise
  static bool validateAssetType(String assetType) {
    const validTypes = ['stock', 'crypto', 'etf'];
    return validTypes.contains(assetType.toLowerCase());
  }

  /// Validates a symbol format
  ///
  /// Rules:
  /// - Must be 1-10 characters long
  /// - Can only contain uppercase letters, numbers, and hyphens
  /// - Must start with a letter
  ///
  /// Returns true if valid, false otherwise
  static bool validateSymbol(String symbol) {
    if (symbol.isEmpty || symbol.length > 10) return false;

    final symbolRegex = RegExp(r'^[A-Z][A-Z0-9-]*$');

    return symbolRegex.hasMatch(symbol.toUpperCase());
  }

  /// Validates that a numeric value is positive
  ///
  /// Returns true if value is greater than 0
  static bool validatePositiveValue(double value) {
    return value > 0;
  }

  /// Validates that a quantity is non-negative
  ///
  /// Returns true if quantity is 0 or positive
  static bool validateQuantity(double quantity) {
    return quantity >= 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Asset &&
        other.id == id &&
        other.userId == userId &&
        other.symbol == symbol &&
        other.name == name &&
        other.assetType == assetType &&
        other.currentPrice == currentPrice &&
        other.previousClose == previousClose &&
        other.quantity == quantity &&
        other.averageCost == averageCost &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      symbol,
      name,
      assetType,
      currentPrice,
      previousClose,
      quantity,
      averageCost,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Asset(id: $id, userId: $userId, symbol: $symbol, name: $name, assetType: $assetType, currentPrice: $currentPrice, previousClose: $previousClose, quantity: $quantity, averageCost: $averageCost, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
