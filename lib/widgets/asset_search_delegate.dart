import 'package:flutter/material.dart';
import '../models/asset.dart';

/// Searchable asset picker for selecting assets from user's portfolio
/// 
/// Provides search functionality by symbol or name with real-time filtering.
class AssetSearchDelegate extends SearchDelegate<Asset?> {
  final List<Asset> assets;
  final VoidCallback? onAddNew;

  AssetSearchDelegate({
    required this.assets,
    this.onAddNew,
  }) : super(
          searchFieldLabel: 'Search by symbol or name',
          searchFieldStyle: const TextStyle(fontSize: 16),
        );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredAssets = _filterAssets();

    if (filteredAssets.isEmpty && query.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search,
        title: 'Search for an asset',
        subtitle: 'Enter a symbol or name to find an asset',
      );
    }

    if (filteredAssets.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off,
        title: 'No assets found',
        subtitle: 'Try a different search term',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: filteredAssets.length,
            itemBuilder: (context, index) {
              final asset = filteredAssets[index];
              return _buildAssetTile(context, asset);
            },
          ),
        ),
        if (onAddNew != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.blue),
              title: const Text(
                'Add New Asset',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                close(context, null);
                onAddNew?.call();
              },
            ),
          ),
      ],
    );
  }

  List<Asset> _filterAssets() {
    if (query.isEmpty) {
      return assets;
    }

    final lowerQuery = query.toLowerCase();
    return assets.where((asset) {
      return asset.symbol.toLowerCase().contains(lowerQuery) ||
          asset.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Widget _buildAssetTile(BuildContext context, Asset asset) {
    return ListTile(
      leading: _buildAssetIcon(asset.assetType),
      title: Row(
        children: [
          Text(
            asset.symbol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              asset.name,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '\$${asset.currentPrice.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        close(context, asset);
      },
    );
  }

  Widget _buildAssetIcon(String assetType) {
    IconData icon;
    Color color;

    switch (assetType.toLowerCase()) {
      case 'stock':
        icon = Icons.show_chart;
        color = Colors.blue;
        break;
      case 'crypto':
        icon = Icons.currency_bitcoin;
        color = Colors.orange;
        break;
      case 'etf':
        icon = Icons.pie_chart;
        color = Colors.green;
        break;
      default:
        icon = Icons.attach_money;
        color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}