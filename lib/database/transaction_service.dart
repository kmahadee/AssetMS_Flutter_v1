import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'asset_service.dart';

/// Service for transaction database operations with user data isolation
/// 
/// All operations are scoped to a specific user to ensure data privacy.
/// Includes methods for recalculating asset quantities and costs based on transactions.
class TransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AssetService _assetService = AssetService();

  /// Insert a new transaction
  /// 
  /// Parameters:
  /// - [transaction]: Transaction object to insert (id will be auto-generated)
  /// 
  /// Returns: The ID of the newly inserted transaction
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  /// Update an existing transaction
  /// 
  /// Parameters:
  /// - [transaction]: Transaction object with updated values
  /// 
  /// Throws: Exception if transaction doesn't exist or is unauthorized
  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Cannot update transaction without ID');
    }

    final db = await _dbHelper.database;
    
    final count = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [transaction.id, transaction.userId],
    );

    if (count == 0) {
      throw Exception('Transaction not found or unauthorized');
    }
  }

  /// Delete a transaction
  /// 
  /// Parameters:
  /// - [id]: Transaction ID to delete
  /// - [userId]: User ID for authorization verification
  /// 
  /// Returns: Number of rows deleted (0 if not found or unauthorized)
  Future<int> deleteTransaction(int id, int userId) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Get a single transaction by ID
  /// 
  /// Parameters:
  /// - [id]: Transaction ID
  /// - [userId]: User ID for authorization verification
  /// 
  /// Returns: Transaction object if found, null otherwise
  Future<Transaction?> getTransactionById(int id, int userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (results.isEmpty) {
      return null;
    }

    return Transaction.fromMap(results.first);
  }

  /// Get all transactions for a user
  /// 
  /// Orders by date descending (most recent first)
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// 
  /// Returns: List of all transactions for the user
  Future<List<Transaction>> getAllTransactions(int userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions for a specific asset
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [assetId]: Asset ID to filter by
  /// 
  /// Returns: List of transactions for the specified asset
  Future<List<Transaction>> getTransactionsByAssetId(
    int userId,
    int assetId,
  ) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'transactions',
      where: 'user_id = ? AND asset_id = ?',
      whereArgs: [userId, assetId],
      orderBy: 'date DESC',
    );

    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions filtered by type
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [type]: Transaction type ('buy' or 'sell')
  /// 
  /// Returns: List of transactions matching the type
  Future<List<Transaction>> getTransactionsByType(
    int userId,
    String type,
  ) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'transactions',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'date DESC',
    );

    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions within a date range
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [start]: Start date (inclusive)
  /// - [end]: End date (inclusive)
  /// 
  /// Returns: List of transactions within the date range
  Future<List<Transaction>> getTransactionsByDateRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;
    
    final results = await db.query(
      'transactions',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startMillis, endMillis],
      orderBy: 'date DESC',
    );

    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get count of transactions for a user
  /// 
  /// Parameters:
  /// - [userId]: User ID to count transactions for
  /// 
  /// Returns: Number of transactions for the user
  Future<int> getTransactionCount(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE user_id = ?',
      [userId],
    );

    return result.first['count'] as int;
  }

  /// Calculate total buy volume for a user
  /// 
  /// Sums up (quantity * price_per_unit) for all buy transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate total for
  /// 
  /// Returns: Total amount spent on purchases
  Future<double> getTotalBuyVolume(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      '''
      SELECT SUM(quantity * price_per_unit) as total 
      FROM transactions 
      WHERE user_id = ? AND type = 'buy'
      ''',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Calculate total sell volume for a user
  /// 
  /// Sums up (quantity * price_per_unit) for all sell transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate total for
  /// 
  /// Returns: Total amount received from sales
  Future<double> getTotalSellVolume(int userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      '''
      SELECT SUM(quantity * price_per_unit) as total 
      FROM transactions 
      WHERE user_id = ? AND type = 'sell'
      ''',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Recalculate asset quantity and average cost from transactions
  /// 
  /// This method recalculates an asset's quantity and weighted average cost
  /// based on all its buy and sell transactions using FIFO accounting.
  /// 
  /// Parameters:
  /// - [userId]: User ID for authorization
  /// - [assetId]: Asset ID to recalculate
  Future<void> updateAssetQuantityAndCost(int userId, int assetId) async {
    final transactions = await getTransactionsByAssetId(userId, assetId);
    
    if (transactions.isEmpty) {
      // No transactions, set quantity and cost to 0
      await _assetService.updateQuantityAndCost(assetId, userId, 0, 0);
      return;
    }

    // Sort by date ascending for chronological processing
    transactions.sort((a, b) => a.date.compareTo(b.date));

    double totalQuantity = 0;
    double totalCost = 0;

    for (final transaction in transactions) {
      if (transaction.type.toLowerCase() == 'buy') {
        // Add to position
        totalCost += transaction.totalAmount;
        totalQuantity += transaction.quantity;
      } else if (transaction.type.toLowerCase() == 'sell') {
        // Reduce position
        if (totalQuantity > 0) {
          // Calculate proportion of position being sold
          final proportion = transaction.quantity / totalQuantity;
          
          // Reduce cost proportionally
          totalCost -= (totalCost * proportion);
          totalQuantity -= transaction.quantity;
        }
      }
    }

    // Calculate average cost
    final averageCost = totalQuantity > 0 ? totalCost / totalQuantity : 0.0;

    // Update the asset
    await _assetService.updateQuantityAndCost(
      assetId,
      userId,
      totalQuantity,
      averageCost,
    );
  }

  /// Get recent transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// - [limit]: Maximum number of transactions to return
  /// 
  /// Returns: List of most recent transactions
  Future<List<Transaction>> getRecentTransactions(
    int userId, {
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );

    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions for today
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// 
  /// Returns: List of today's transactions
  Future<List<Transaction>> getTodayTransactions(int userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getTransactionsByDateRange(userId, startOfDay, endOfDay);
  }

  /// Get transactions for current month
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// 
  /// Returns: List of this month's transactions
  Future<List<Transaction>> getMonthTransactions(int userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await getTransactionsByDateRange(userId, startOfMonth, endOfMonth);
  }

  /// Get transactions for current year
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter by
  /// 
  /// Returns: List of this year's transactions
  Future<List<Transaction>> getYearTransactions(int userId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return await getTransactionsByDateRange(userId, startOfYear, endOfYear);
  }

  /// Calculate realized gains/losses from sell transactions
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate for
  /// 
  /// Returns: Total realized gains (can be negative for losses)
  Future<double> getRealizedGains(int userId) async {
    final sellTransactions = await getTransactionsByType(userId, 'sell');
    
    double realizedGains = 0;

    for (final sell in sellTransactions) {
      // Get corresponding asset to find average cost
      final asset = await _assetService.getAssetById(sell.assetId, userId);
      
      if (asset != null) {
        // Calculate gain/loss: (sell price - average cost) * quantity
        final gainPerUnit = sell.pricePerUnit - asset.averageCost;
        realizedGains += gainPerUnit * sell.quantity;
      }
    }

    return realizedGains;
  }

  /// Delete all transactions for an asset
  /// 
  /// Useful when deleting an asset
  /// 
  /// Parameters:
  /// - [userId]: User ID for authorization
  /// - [assetId]: Asset ID
  /// 
  /// Returns: Number of transactions deleted
  Future<int> deleteAssetTransactions(int userId, int assetId) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'transactions',
      where: 'user_id = ? AND asset_id = ?',
      whereArgs: [userId, assetId],
    );
  }
}