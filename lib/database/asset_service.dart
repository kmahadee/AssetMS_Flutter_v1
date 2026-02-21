import '../database/database_helper.dart';
import '../models/asset.dart';

/// Service for asset database operations with user data isolation
/// 
/// All operations are scoped to a specific user to ensure data privacy
/// and security in a multi-user environment.
class AssetService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert a new asset
  /// 
  /// Parameters:
  /// - [asset]: Asset object to insert (id will be auto-generated)
  /// 
  /// Returns: The ID of the newly inserted asset
  Future<int> insertAsset(Asset asset) async {
    final db = await _dbHelper.database;
    return await db.insert('assets', asset.toMap());
  }

  /// Update an existing asset
  /// 
  /// Parameters:
  /// - [asset]: Asset object with updated values
  /// 
  /// Throws: Exception if asset doesn't exist
  Future<void> updateAsset(Asset asset) async {
    if (asset.id == null) {
      throw Exception('Cannot update asset without ID');
    }

    final db = await _dbHelper.database;
    
    final count = await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [asset.id, asset.userId],
    );

    if (count == 0) {
      throw Exception('Asset not found or unauthorized');
    }
  }

  /// Delete an asset
  /// 
  /// Parameters:
  /// - [id]: Asset ID to delete
  /// - [userId]: User ID for authorization verification
  /// 
  /// Returns: Number of rows deleted (0 if not found or unauthorized)
  Future<int> deleteAsset(int id, int userId) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'assets',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Get a single asset by ID
  /// 
  /// Parameters:
  /// - [id]: Asset ID
  /// - [userId]: User ID for authorization verification
  /// 
  /// Returns: Asset object if found, null otherwise
  Future<Asset?> getAssetById(int id, int userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'assets',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (results.isEmpty) {
      return null;
    }

    return Asset.fromMap(results.first);
  }

  /// Get all assets for a user
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// 
  /// Returns: List of all assets owned by the user
  Future<List<Asset>> getAllAssets(int userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'assets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'symbol ASC',
    );

    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// Get assets filtered by type
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [assetType]: Type of asset ('stock', 'crypto', or 'etf')
  /// 
  /// Returns: List of assets matching the specified type
  Future<List<Asset>> getAssetsByType(int userId, String assetType) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'assets',
      where: 'user_id = ? AND asset_type = ?',
      whereArgs: [userId, assetType],
      orderBy: 'symbol ASC',
    );

    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// Update the price of an asset
  /// 
  /// Parameters:
  /// - [id]: Asset ID
  /// - [userId]: User ID for authorization
  /// - [newPrice]: New current price
  /// - [newPreviousClose]: New previous close price
  Future<void> updateAssetPrice(
    int id,
    int userId,
    double newPrice,
    double newPreviousClose,
  ) async {
    final db = await _dbHelper.database;
    
    final count = await db.update(
      'assets',
      {
        'current_price': newPrice,
        'previous_close': newPreviousClose,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (count == 0) {
      throw Exception('Asset not found or unauthorized');
    }
  }

  /// Bulk update prices for multiple assets
  /// 
  /// Uses a database transaction for atomicity
  /// 
  /// Parameters:
  /// - [userId]: User ID for authorization
  /// - [assets]: List of assets with updated prices
  Future<void> bulkUpdatePrices(int userId, List<Asset> assets) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      for (final asset in assets) {
        if (asset.id == null) continue;
        
        await txn.update(
          'assets',
          {
            'current_price': asset.currentPrice,
            'previous_close': asset.previousClose,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ? AND user_id = ?',
          whereArgs: [asset.id, userId],
        );
      }
    });
  }

  /// Get count of assets for a user
  /// 
  /// Parameters:
  /// - [userId]: User ID to count assets for
  /// 
  /// Returns: Number of assets owned by the user
  Future<int> getAssetCount(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assets WHERE user_id = ?',
      [userId],
    );

    return result.first['count'] as int;
  }

  /// Calculate total portfolio value for a user
  /// 
  /// Sums up (current_price * quantity) for all assets
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate total for
  /// 
  /// Returns: Total portfolio value
  Future<double> getTotalValue(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT SUM(current_price * quantity) as total FROM assets WHERE user_id = ?',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Check if a symbol already exists for a user
  /// 
  /// Prevents duplicate asset entries
  /// 
  /// Parameters:
  /// - [userId]: User ID to check for
  /// - [symbol]: Asset symbol to check
  /// 
  /// Returns: true if symbol exists, false otherwise
  Future<bool> symbolExists(int userId, String symbol) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'assets',
      where: 'user_id = ? AND symbol = ?',
      whereArgs: [userId, symbol.toUpperCase()],
    );

    return results.isNotEmpty;
  }

  /// Get total cost basis for a user's portfolio
  /// 
  /// Sums up (average_cost * quantity) for all assets
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate total for
  /// 
  /// Returns: Total cost basis
  Future<double> getTotalCost(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT SUM(average_cost * quantity) as total FROM assets WHERE user_id = ?',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Get assets sorted by unrealized gain
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [descending]: If true, sort from highest to lowest gain
  /// 
  /// Returns: List of assets sorted by performance
  Future<List<Asset>> getAssetsByPerformance(
    int userId, {
    bool descending = true,
  }) async {
    final assets = await getAllAssets(userId);
    
    assets.sort((a, b) {
      final gainA = a.unrealizedGainPercent;
      final gainB = b.unrealizedGainPercent;
      return descending ? gainB.compareTo(gainA) : gainA.compareTo(gainB);
    });

    return assets;
  }

  /// Get top performing assets
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [limit]: Number of top assets to return
  /// 
  /// Returns: List of top performing assets
  Future<List<Asset>> getTopPerformers(int userId, {int limit = 5}) async {
    final assets = await getAssetsByPerformance(userId, descending: true);
    return assets.take(limit).toList();
  }

  /// Get worst performing assets
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [limit]: Number of bottom assets to return
  /// 
  /// Returns: List of worst performing assets
  Future<List<Asset>> getWorstPerformers(int userId, {int limit = 5}) async {
    final assets = await getAssetsByPerformance(userId, descending: false);
    return assets.take(limit).toList();
  }

  /// Search assets by symbol or name
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [query]: Search query (case-insensitive)
  /// 
  /// Returns: List of matching assets
  Future<List<Asset>> searchAssets(int userId, String query) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'assets',
      where: 'user_id = ? AND (symbol LIKE ? OR name LIKE ?)',
      whereArgs: [userId, '%${query.toUpperCase()}%', '%$query%'],
      orderBy: 'symbol ASC',
    );

    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// Update asset quantity and average cost
  /// 
  /// Typically called after adding/removing transactions
  /// 
  /// Parameters:
  /// - [assetId]: Asset ID to update
  /// - [userId]: User ID for authorization
  /// - [quantity]: New quantity
  /// - [averageCost]: New average cost
  Future<void> updateQuantityAndCost(
    int assetId,
    int userId,
    double quantity,
    double averageCost,
  ) async {
    final db = await _dbHelper.database;
    
    final count = await db.update(
      'assets',
      {
        'quantity': quantity,
        'average_cost': averageCost,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [assetId, userId],
    );

    if (count == 0) {
      throw Exception('Asset not found or unauthorized');
    }
  }
}