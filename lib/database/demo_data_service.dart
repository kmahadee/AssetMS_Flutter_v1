import 'dart:math';
import '../models/asset.dart';
import '../models/transaction.dart';
import 'asset_service.dart';
import 'transaction_service.dart';

/// Service for generating demo/sample data for new users
/// 
/// Creates realistic portfolio data with various assets and transactions
/// to help users understand the app functionality.
class DemoDataService {
  final AssetService _assetService = AssetService();
  final TransactionService _transactionService = TransactionService();
  final Random _random = Random();

  /// Demo asset data with realistic prices
  final List<Map<String, dynamic>> _demoAssets = [
    // Stocks
    {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'type': 'stock',
      'price': 178.50,
      'previousClose': 176.80,
    },
    {
      'symbol': 'MSFT',
      'name': 'Microsoft Corporation',
      'type': 'stock',
      'price': 415.20,
      'previousClose': 412.90,
    },
    {
      'symbol': 'GOOGL',
      'name': 'Alphabet Inc.',
      'type': 'stock',
      'price': 142.30,
      'previousClose': 140.75,
    },
    {
      'symbol': 'TSLA',
      'name': 'Tesla, Inc.',
      'type': 'stock',
      'price': 242.80,
      'previousClose': 245.60,
    },
    {
      'symbol': 'AMZN',
      'name': 'Amazon.com Inc.',
      'type': 'stock',
      'price': 178.90,
      'previousClose': 176.40,
    },
    // Cryptocurrencies
    {
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'type': 'crypto',
      'price': 67500.00,
      'previousClose': 66800.00,
    },
    {
      'symbol': 'ETH',
      'name': 'Ethereum',
      'type': 'crypto',
      'price': 3450.00,
      'previousClose': 3380.00,
    },
    {
      'symbol': 'SOL',
      'name': 'Solana',
      'type': 'crypto',
      'price': 145.80,
      'previousClose': 142.30,
    },
    // ETFs
    {
      'symbol': 'SPY',
      'name': 'SPDR S&P 500 ETF Trust',
      'type': 'etf',
      'price': 512.30,
      'previousClose': 510.80,
    },
    {
      'symbol': 'QQQ',
      'name': 'Invesco QQQ Trust',
      'type': 'etf',
      'price': 478.90,
      'previousClose': 476.50,
    },
  ];

  /// Seed demo data for a user
  /// 
  /// Creates a realistic portfolio with multiple assets and transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to create demo data for
  Future<void> seedDemoDataForUser(int userId) async {
    // Check if user already has data
    final hasData = await userHasData(userId);
    if (hasData) {
      throw Exception('User already has data. Clear data first.');
    }

    final now = DateTime.now();

    // Create assets and transactions for each demo asset
    for (final demoAsset in _demoAssets) {
      // Random initial quantity (different ranges for different types)
      double quantity;
      if (demoAsset['type'] == 'crypto') {
        quantity = _randomDouble(0.1, 2.0); // Smaller quantities for crypto
      } else if (demoAsset['type'] == 'stock') {
        quantity = _randomDouble(5, 50).roundToDouble(); // Whole shares
      } else {
        quantity = _randomDouble(10, 100).roundToDouble(); // ETF shares
      }

      // Calculate average cost (slightly below or above current price)
      final currentPrice = demoAsset['price'] as double;
      final priceVariation = currentPrice * 0.15; // ±15%
      final averageCost = currentPrice - priceVariation + (_random.nextDouble() * priceVariation * 2);

      // Create the asset
      final asset = Asset(
        userId: userId,
        symbol: demoAsset['symbol'] as String,
        name: demoAsset['name'] as String,
        assetType: demoAsset['type'] as String,
        currentPrice: currentPrice,
        previousClose: demoAsset['previousClose'] as double,
        quantity: quantity,
        averageCost: averageCost,
        createdAt: now.subtract(Duration(days: _random.nextInt(60) + 30)),
        updatedAt: now,
      );

      final assetId = await _assetService.insertAsset(asset);

      // Generate 2-4 transactions for this asset over past 30 days
      final transactionCount = 2 + _random.nextInt(3); // 2-4 transactions
      
      double remainingQuantity = quantity;
      
      for (int i = 0; i < transactionCount; i++) {
        final daysAgo = _random.nextInt(30) + 1;
        final transactionDate = now.subtract(Duration(days: daysAgo));
        
        // Most transactions are buys, occasional sells
        final isBuy = i < transactionCount - 1 || _random.nextDouble() > 0.3;
        
        double txnQuantity;
        double txnPrice;
        
        if (isBuy) {
          // Buy transaction
          if (i == 0) {
            // First transaction buys most of the position
            txnQuantity = remainingQuantity * (0.5 + _random.nextDouble() * 0.3);
          } else {
            // Subsequent buys add to position
            txnQuantity = remainingQuantity * (0.2 + _random.nextDouble() * 0.3);
          }
          
          // Price varies around average cost
          txnPrice = averageCost * (0.85 + _random.nextDouble() * 0.30);
        } else {
          // Sell transaction (small portion)
          txnQuantity = remainingQuantity * (0.1 + _random.nextDouble() * 0.2);
          
          // Sell price usually higher than average cost
          txnPrice = averageCost * (1.0 + _random.nextDouble() * 0.20);
        }

        // Round based on asset type
        if (demoAsset['type'] != 'crypto') {
          txnQuantity = txnQuantity.roundToDouble();
        }

        final transaction = Transaction(
          userId: userId,
          assetId: assetId,
          type: isBuy ? 'buy' : 'sell',
          quantity: txnQuantity,
          pricePerUnit: txnPrice,
          date: transactionDate,
          notes: _generateTransactionNote(isBuy, demoAsset['symbol'] as String),
          createdAt: transactionDate,
        );

        await _transactionService.insertTransaction(transaction);
      }

      // Recalculate asset quantity and average cost based on transactions
      await _transactionService.updateAssetQuantityAndCost(userId, assetId);
    }
  }

  /// Check if user has any data
  /// 
  /// Parameters:
  /// - [userId]: User ID to check
  /// 
  /// Returns: true if user has assets, false otherwise
  Future<bool> userHasData(int userId) async {
    final assetCount = await _assetService.getAssetCount(userId);
    return assetCount > 0;
  }

  /// Clear all data for a user
  /// 
  /// Deletes all assets and transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to clear data for
  Future<void> clearUserData(int userId) async {
    final assets = await _assetService.getAllAssets(userId);
    
    for (final asset in assets) {
      if (asset.id != null) {
        // Delete asset (transactions will cascade delete due to foreign key)
        await _assetService.deleteAsset(asset.id!, userId);
      }
    }
  }

  /// Generate a random double between min and max
  double _randomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generate a realistic transaction note
  String? _generateTransactionNote(bool isBuy, String symbol) {
    final notes = [
      null, // Some transactions have no notes
      null,
      isBuy ? 'Initial position' : 'Taking profits',
      isBuy ? 'Adding to position' : 'Partial exit',
      isBuy ? 'Dollar cost averaging' : 'Rebalancing portfolio',
      isBuy ? 'Market dip opportunity' : 'Profit taking',
      'Regular investment',
      null,
    ];
    
    return notes[_random.nextInt(notes.length)];
  }

  /// Create minimal demo data (fewer assets)
  /// 
  /// Creates a smaller portfolio for users who want less initial data
  /// 
  /// Parameters:
  /// - [userId]: User ID to create demo data for
  Future<void> seedMinimalDemoData(int userId) async {
    final hasData = await userHasData(userId);
    if (hasData) {
      throw Exception('User already has data. Clear data first.');
    }

    // Only create 3-4 assets
    final minimalAssets = [
      _demoAssets[0], // AAPL
      _demoAssets[5], // BTC
      _demoAssets[8], // SPY
    ];

    final now = DateTime.now();

    for (final demoAsset in minimalAssets) {
      double quantity;
      if (demoAsset['type'] == 'crypto') {
        quantity = _randomDouble(0.5, 1.5);
      } else {
        quantity = _randomDouble(10, 30).roundToDouble();
      }

      final currentPrice = demoAsset['price'] as double;
      final averageCost = currentPrice * (0.90 + _random.nextDouble() * 0.20);

      final asset = Asset(
        userId: userId,
        symbol: demoAsset['symbol'] as String,
        name: demoAsset['name'] as String,
        assetType: demoAsset['type'] as String,
        currentPrice: currentPrice,
        previousClose: demoAsset['previousClose'] as double,
        quantity: quantity,
        averageCost: averageCost,
        createdAt: now.subtract(Duration(days: 30)),
        updatedAt: now,
      );

      final assetId = await _assetService.insertAsset(asset);

      // Create just one buy transaction per asset
      final transaction = Transaction(
        userId: userId,
        assetId: assetId,
        type: 'buy',
        quantity: quantity,
        pricePerUnit: averageCost,
        date: now.subtract(Duration(days: 15)),
        notes: 'Initial purchase',
        createdAt: now.subtract(Duration(days: 15)),
      );

      await _transactionService.insertTransaction(transaction);
    }
  }

  /// Get sample asset data for reference
  /// 
  /// Returns the demo asset template data without creating database records
  List<Map<String, dynamic>> getSampleAssetData() {
    return List.from(_demoAssets);
  }
}