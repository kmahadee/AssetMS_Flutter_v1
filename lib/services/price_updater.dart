import 'dart:async';
import 'dart:math';
import 'package:portfolio_tracker/database/asset_service.dart';

import '../models/asset.dart';


/// Service for simulating real-time price updates for user's assets
/// 
/// Updates asset prices periodically and persists changes to the database.
/// Each instance is user-specific and manages only that user's assets.
class PriceUpdater {
  final AssetService _assetService = AssetService();
  final Random _random = Random();
  
  Timer? _updateTimer;
  int? _userId;
  List<Asset> _assets = [];
  Function(List<Asset>)? _onUpdate;
  
  /// Duration between price updates
  static const Duration updateInterval = Duration(seconds: 5);
  
  /// Maximum price change percentage per update
  static const double maxChangePercent = 0.02; // ±2%

  /// Start price updates for a specific user's assets
  /// 
  /// Parameters:
  /// - [userId]: User ID whose assets to update
  /// - [assets]: Initial list of assets to update
  /// - [onUpdate]: Callback function called with updated assets
  void start(int userId, List<Asset> assets, Function(List<Asset>) onUpdate) {
    // Stop any existing updates
    stop();
    
    _userId = userId;
    _assets = List.from(assets);
    _onUpdate = onUpdate;
    
    // Start periodic updates
    _updateTimer = Timer.periodic(updateInterval, (_) {
      _updatePrices();
    });
  }

  /// Stop price updates and cleanup
  void stop() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _userId = null;
    _assets = [];
    _onUpdate = null;
  }

  /// Update prices for all tracked assets
  Future<void> _updatePrices() async {
    if (_userId == null || _assets.isEmpty || _onUpdate == null) {
      return;
    }

    final updatedAssets = <Asset>[];

    for (final asset in _assets) {
      // Calculate price change
      final changePercent = (_random.nextDouble() * 2 - 1) * maxChangePercent;
      final priceChange = asset.currentPrice * changePercent;
      final newPrice = (asset.currentPrice + priceChange).clamp(0.01, double.infinity);

      // Update previous close to current price
      final previousClose = asset.currentPrice;

      // Create updated asset
      final updatedAsset = asset.copyWith(
        currentPrice: newPrice,
        previousClose: previousClose,
        updatedAt: DateTime.now(),
      );

      updatedAssets.add(updatedAsset);

      // Save to database
      try {
        await _assetService.updateAsset(updatedAsset);
      } catch (e) {
        // Log error but continue updating other assets
        print('Error updating asset ${asset.symbol}: $e');
      }
    }

    // Update local list
    _assets = updatedAssets;

    // Notify callback
    _onUpdate?.call(updatedAssets);
  }

  /// Update the asset list (when assets are added/removed)
  /// 
  /// Call this when the user's portfolio changes to ensure
  /// the updater tracks the correct assets.
  void updateAssetList(List<Asset> assets) {
    _assets = List.from(assets);
  }

  /// Check if updater is currently running
  bool get isRunning => _updateTimer != null && _updateTimer!.isActive;

  /// Get current user ID
  int? get userId => _userId;

  /// Get number of assets being tracked
  int get assetCount => _assets.length;

  /// Manually trigger a price update (useful for testing)
  Future<void> triggerUpdate() async {
    await _updatePrices();
  }

  /// Simulate a specific price change for an asset
  /// 
  /// Useful for testing specific scenarios
  Future<void> simulatePriceChange(
    int assetId,
    double newPrice, {
    bool updateDatabase = true,
  }) async {
    if (_userId == null) return;

    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index == -1) return;

    final asset = _assets[index];
    final updatedAsset = asset.copyWith(
      currentPrice: newPrice,
      previousClose: asset.currentPrice,
      updatedAt: DateTime.now(),
    );

    _assets[index] = updatedAsset;

    if (updateDatabase) {
      try {
        await _assetService.updateAsset(updatedAsset);
      } catch (e) {
        print('Error updating asset price: $e');
      }
    }

    _onUpdate?.call(_assets);
  }

  /// Simulate market crash (all prices drop significantly)
  /// 
  /// For testing/demo purposes
  Future<void> simulateMarketCrash({double crashPercent = 0.10}) async {
    if (_userId == null || _assets.isEmpty) return;

    final updatedAssets = <Asset>[];

    for (final asset in _assets) {
      final newPrice = asset.currentPrice * (1 - crashPercent);
      final updatedAsset = asset.copyWith(
        currentPrice: newPrice,
        previousClose: asset.currentPrice,
        updatedAt: DateTime.now(),
      );

      updatedAssets.add(updatedAsset);

      try {
        await _assetService.updateAsset(updatedAsset);
      } catch (e) {
        print('Error updating asset during crash: $e');
      }
    }

    _assets = updatedAssets;
    _onUpdate?.call(updatedAssets);
  }

  /// Simulate market rally (all prices rise significantly)
  /// 
  /// For testing/demo purposes
  Future<void> simulateMarketRally({double rallyPercent = 0.10}) async {
    if (_userId == null || _assets.isEmpty) return;

    final updatedAssets = <Asset>[];

    for (final asset in _assets) {
      final newPrice = asset.currentPrice * (1 + rallyPercent);
      final updatedAsset = asset.copyWith(
        currentPrice: newPrice,
        previousClose: asset.currentPrice,
        updatedAt: DateTime.now(),
      );

      updatedAssets.add(updatedAsset);

      try {
        await _assetService.updateAsset(updatedAsset);
      } catch (e) {
        print('Error updating asset during rally: $e');
      }
    }

    _assets = updatedAssets;
    _onUpdate?.call(updatedAssets);
  }
}