import 'package:flutter/foundation.dart';
import 'package:portfolio_tracker/database/asset_service.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/database/portfolio_calculator.dart';
import 'package:portfolio_tracker/database/transaction_service.dart';
import '../models/user.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../models/portfolio_summary.dart';
import '../services/price_updater.dart';

/// Central state management for portfolio data with user authentication
/// 
/// Manages all portfolio data, price updates, and database operations
/// for the currently logged-in user.
class PortfolioProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AssetService _assetService = AssetService();
  final TransactionService _transactionService = TransactionService();
  final PriceUpdater _priceUpdater = PriceUpdater();

  // State
  User? _currentUser;
  List<Asset> _assets = [];
  List<Transaction> _transactions = [];
  PortfolioSummary? _summary;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  // Getters
  User? get currentUser => _currentUser;
  List<Asset> get assets => List.unmodifiable(_assets);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  PortfolioSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get hasUser => _currentUser != null;
  bool get hasAssets => _assets.isNotEmpty;
  bool get hasTransactions => _transactions.isNotEmpty;
  bool get isPriceUpdatesActive => _priceUpdater.isRunning;

  /// Set the current user and load their portfolio data
  /// 
  /// This should be called after successful login or registration.
  Future<void> setUser(User user) async {
    _currentUser = user;
    _error = null;
    
    // Don't call notifyListeners here - let loadUserData handle it
    await loadUserData();
  }

  /// Load all portfolio data for the current user
  /// 
  /// Fetches assets, transactions, and calculates portfolio summary.
  Future<void> loadUserData() async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      // Load assets
      final assets = await _assetService.getAllAssets(_currentUser!.id);
      
      // Load transactions
      final transactions = await _transactionService.getAllTransactions(_currentUser!.id);
      
      // Get transaction count
      final transactionCount = transactions.length;

      // Calculate summary
      final summary = PortfolioCalculator.calculateSummary(
        assets,
        transactionCount: transactionCount,
      );

      _assets = assets;
      _transactions = transactions;
      _summary = summary;
      _lastUpdate = DateTime.now();
      _error = null;

      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load portfolio data: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Refresh asset prices from database
  /// 
  /// Reloads all assets to get latest prices without reloading transactions.
  Future<void> refreshPrices() async {
    if (_currentUser == null) return;

    try {
      final assets = await _assetService.getAllAssets(_currentUser!.id);
      _assets = assets;
      _recalculateSummary();
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh prices: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Start real-time price updates for current user's assets
  /// 
  /// Begins simulating price changes for all assets in the portfolio.
  void startPriceUpdates() {
    if (_currentUser == null || _assets.isEmpty) return;

    _priceUpdater.start(
      _currentUser!.id,
      _assets,
      _handlePriceUpdate,
    );
  }

  /// Stop real-time price updates
  void stopPriceUpdates() {
    _priceUpdater.stop();
  }

  /// Handle price updates from the updater
  void _handlePriceUpdate(List<Asset> updatedAssets) {
    _assets = updatedAssets;
    _recalculateSummary();
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  /// Add a new asset to the portfolio
  /// 
  /// Inserts the asset into the database and updates the provider state.
  Future<void> addAsset(Asset asset) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final assetId = await _assetService.insertAsset(asset);
      final insertedAsset = asset.copyWith(id: assetId);
      
      _assets.add(insertedAsset);
      _recalculateSummary();
      
      // Update price updater if running
      if (_priceUpdater.isRunning) {
        _priceUpdater.updateAssetList(_assets);
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add asset: ${e.toString()}');
    }
  }

  /// Update an existing asset
  /// 
  /// Updates the asset in the database and provider state.
  Future<void> updateAsset(Asset asset) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await _assetService.updateAsset(asset);
      
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        _assets[index] = asset;
        _recalculateSummary();
        
        // Update price updater if running
        if (_priceUpdater.isRunning) {
          _priceUpdater.updateAssetList(_assets);
        }
        
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update asset: ${e.toString()}');
    }
  }

  /// Delete an asset from the portfolio
  /// 
  /// Removes the asset and its transactions from the database.
  Future<void> deleteAsset(int assetId) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await _assetService.deleteAsset(assetId, _currentUser!.id);
      
      _assets.removeWhere((a) => a.id == assetId);
      _transactions.removeWhere((t) => t.assetId == assetId);
      _recalculateSummary();
      
      // Update price updater if running
      if (_priceUpdater.isRunning) {
        _priceUpdater.updateAssetList(_assets);
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete asset: ${e.toString()}');
    }
  }

  /// Add a new transaction
  /// 
  /// Inserts the transaction and recalculates asset holdings.
  Future<void> addTransaction(Transaction transaction) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final transactionId = await _transactionService.insertTransaction(transaction);
      final insertedTransaction = transaction.copyWith(id: transactionId);
      
      // Recalculate asset quantity and cost
      await _transactionService.updateAssetQuantityAndCost(
        _currentUser!.id,
        transaction.assetId,
      );
      
      // Reload the affected asset
      final updatedAsset = await _assetService.getAssetById(
        transaction.assetId,
        _currentUser!.id,
      );
      
      if (updatedAsset != null) {
        final index = _assets.indexWhere((a) => a.id == transaction.assetId);
        if (index != -1) {
          _assets[index] = updatedAsset;
        }
      }
      
      _transactions.add(insertedTransaction);
      _recalculateSummary();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add transaction: ${e.toString()}');
    }
  }

  /// Update an existing transaction
  /// 
  /// Updates the transaction and recalculates asset holdings.
  Future<void> updateTransaction(Transaction transaction) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await _transactionService.updateTransaction(transaction);
      
      // Recalculate asset quantity and cost
      await _transactionService.updateAssetQuantityAndCost(
        _currentUser!.id,
        transaction.assetId,
      );
      
      // Reload the affected asset
      final updatedAsset = await _assetService.getAssetById(
        transaction.assetId,
        _currentUser!.id,
      );
      
      if (updatedAsset != null) {
        final index = _assets.indexWhere((a) => a.id == transaction.assetId);
        if (index != -1) {
          _assets[index] = updatedAsset;
        }
      }
      
      final transactionIndex = _transactions.indexWhere((t) => t.id == transaction.id);
      if (transactionIndex != -1) {
        _transactions[transactionIndex] = transaction;
      }
      
      _recalculateSummary();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update transaction: ${e.toString()}');
    }
  }

  /// Delete a transaction
  /// 
  /// Removes the transaction and recalculates asset holdings.
  Future<void> deleteTransaction(int transactionId) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Find the transaction to get assetId
    final transaction = _transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    try {
      await _transactionService.deleteTransaction(transactionId, _currentUser!.id);
      
      // Recalculate asset quantity and cost
      await _transactionService.updateAssetQuantityAndCost(
        _currentUser!.id,
        transaction.assetId,
      );
      
      // Reload the affected asset
      final updatedAsset = await _assetService.getAssetById(
        transaction.assetId,
        _currentUser!.id,
      );
      
      if (updatedAsset != null) {
        final index = _assets.indexWhere((a) => a.id == transaction.assetId);
        if (index != -1) {
          _assets[index] = updatedAsset;
        }
      }
      
      _transactions.removeWhere((t) => t.id == transactionId);
      _recalculateSummary();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  /// Get all transactions for a specific asset
  /// 
  /// Returns a filtered list from the loaded transactions.
  List<Transaction> getAssetTransactions(int assetId) {
    return _transactions.where((t) => t.assetId == assetId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get an asset by ID from the loaded list
  /// 
  /// Returns null if asset not found.
  Asset? getAssetById(int id) {
    try {
      return _assets.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get assets filtered by type
  List<Asset> getAssetsByType(String assetType) {
    return _assets.where((a) => a.assetType == assetType).toList();
  }

  /// Get top performing assets
  List<Asset> getTopPerformers({int limit = 5}) {
    return PortfolioCalculator.getTopPerformers(_assets, limit: limit);
  }

  /// Get worst performing assets
  List<Asset> getWorstPerformers({int limit = 5}) {
    return PortfolioCalculator.getWorstPerformers(_assets, limit: limit);
  }

  /// Get recent transactions
  List<Transaction> getRecentTransactions({int limit = 10}) {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Clear all data for the current user
  /// 
  /// Deletes all assets and transactions from the database.
  Future<void> clearUserData() async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      // Stop price updates
      stopPriceUpdates();
      
      // Delete all assets (transactions cascade delete)
      for (final asset in _assets) {
        if (asset.id != null) {
          await _assetService.deleteAsset(asset.id!, _currentUser!.id);
        }
      }
      
      _assets.clear();
      _transactions.clear();
      _summary = PortfolioSummary.empty();
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to clear user data: ${e.toString()}');
    }
  }

  /// Logout the current user
  /// 
  /// Stops updates, clears all data, and resets the provider state.
  Future<void> logout() async {
    // Stop price updates
    stopPriceUpdates();
    
    // Clear auth session
    await _authService.logoutUser();
    
    // Clear state
    _currentUser = null;
    _assets.clear();
    _transactions.clear();
    _summary = null;
    _error = null;
    _lastUpdate = null;
    
    notifyListeners();
  }

  /// Initialize provider by checking for existing user session
  /// 
  /// Call this when app starts to restore user session.
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        await setUser(user);
      } else {
        _setLoading(false);
      }
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Recalculate portfolio summary from current assets and transactions
  void _recalculateSummary() {
    _summary = PortfolioCalculator.calculateSummary(
      _assets,
      transactionCount: _transactions.length,
    );
  }

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Manually trigger a data refresh
  /// 
  /// Reloads all data from the database.
  Future<void> refresh() async {
    await loadUserData();
  }

  /// Check if a symbol already exists in the portfolio
  Future<bool> symbolExists(String symbol) async {
    if (_currentUser == null) return false;
    return await _assetService.symbolExists(_currentUser!.id, symbol);
  }

  @override
  void dispose() {
    stopPriceUpdates();
    super.dispose();
  }
}