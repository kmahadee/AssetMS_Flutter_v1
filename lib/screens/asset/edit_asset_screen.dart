import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_tracker/database/asset_service.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/database/transaction_service.dart';
import 'package:portfolio_tracker/dialogs/confirmation_dialog.dart';
import '../../models/asset.dart';

/// Screen for editing an existing asset
/// 
/// Allows modification of asset details and deletion with cascade.
class EditAssetScreen extends StatefulWidget {
  final int assetId;

  const EditAssetScreen({
    super.key,
    required this.assetId,
  });

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _previousCloseController = TextEditingController();
  final _quantityController = TextEditingController();
  final _averageCostController = TextEditingController();

  final _assetService = AssetService();
  final _transactionService = TransactionService();
  final _authService = AuthService();

  Asset? _originalAsset;
  int? _currentUserId;
  bool _isLoading = true;
  bool _isSaving = false;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAsset();
    _currentPriceController.addListener(_updateCalculations);
    _quantityController.addListener(_updateCalculations);
    _averageCostController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPriceController.dispose();
    _previousCloseController.dispose();
    _quantityController.dispose();
    _averageCostController.dispose();
    super.dispose();
  }

  Future<void> _loadAsset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final asset = await _assetService.getAssetById(widget.assetId, userId);
      if (asset == null) {
        throw Exception('Asset not found');
      }

      final transactionCount = await _transactionService
          .getTransactionsByAssetId(userId, widget.assetId);

      setState(() {
        _currentUserId = userId;
        _originalAsset = asset;
        _transactionCount = transactionCount.length;
        
        _nameController.text = asset.name;
        _currentPriceController.text = asset.currentPrice.toStringAsFixed(2);
        _previousCloseController.text = asset.previousClose.toStringAsFixed(2);
        _quantityController.text = asset.quantity.toString();
        _averageCostController.text = asset.averageCost.toStringAsFixed(2);
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error loading asset: ${e.toString()}');
      Navigator.of(context).pop();
    }
  }

  void _updateCalculations() {
    setState(() {}); // Trigger rebuild
  }

  double? get _totalInvestment {
    final quantity = double.tryParse(_quantityController.text);
    final avgCost = double.tryParse(_averageCostController.text);
    if (quantity == null || avgCost == null) return null;
    return quantity * avgCost;
  }

  double? get _currentValue {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_currentPriceController.text);
    if (quantity == null || price == null) return null;
    return quantity * price;
  }

  double? get _unrealizedGain {
    final investment = _totalInvestment;
    final value = _currentValue;
    if (investment == null || value == null) return null;
    return value - investment;
  }

  bool get _hasChanges {
    if (_originalAsset == null) return false;
    
    return _nameController.text != _originalAsset!.name ||
        _currentPriceController.text != _originalAsset!.currentPrice.toStringAsFixed(2) ||
        _previousCloseController.text != _originalAsset!.previousClose.toStringAsFixed(2) ||
        _quantityController.text != _originalAsset!.quantity.toString() ||
        _averageCostController.text != _originalAsset!.averageCost.toStringAsFixed(2);
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _currentPriceController.text.isNotEmpty &&
        _previousCloseController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _averageCostController.text.isNotEmpty &&
        (double.tryParse(_currentPriceController.text) ?? 0) > 0 &&
        (double.tryParse(_previousCloseController.text) ?? 0) > 0 &&
        (double.tryParse(_quantityController.text) ?? 0) >= 0 &&
        (double.tryParse(_averageCostController.text) ?? 0) > 0;
  }

  Future<void> _handleSave() async {
    if (_currentUserId == null || _originalAsset == null) return;
    if (!_isFormValid) {
      _showErrorSnackBar('Please fill all fields correctly');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedAsset = _originalAsset!.copyWith(
        name: _nameController.text.trim(),
        currentPrice: double.parse(_currentPriceController.text),
        previousClose: double.parse(_previousCloseController.text),
        quantity: double.parse(_quantityController.text),
        averageCost: double.parse(_averageCostController.text),
        updatedAt: DateTime.now(),
      );

      await _assetService.updateAsset(updatedAsset);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${updatedAsset.symbol} updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Error updating asset: ${e.toString()}');
    }
  }

  Future<void> _handleDelete() async {
    if (_currentUserId == null || _originalAsset == null) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete ${_originalAsset!.symbol}?',
      message: 'This will also delete $_transactionCount associated transaction(s). This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _assetService.deleteAsset(widget.assetId, _currentUserId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${_originalAsset!.symbol} deleted'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Error deleting asset: ${e.toString()}');
    }
  }

  Future<void> _handleRecalculate() async {
    if (_currentUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recalculate from Transactions?'),
        content: const Text(
          'This will recalculate the quantity and average cost based on all transactions. Current values will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _transactionService.updateAssetQuantityAndCost(
        _currentUserId!,
        widget.assetId,
      );

      // Reload asset to get updated values
      await _loadAsset();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully recalculated from transactions'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Error recalculating: ${e.toString()}');
    }
  }

  Future<bool> _handleWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Asset')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit ${_originalAsset?.symbol ?? 'Asset'}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isSaving ? null : _handleDelete,
            ),
            TextButton(
              onPressed: _isSaving || !_isFormValid || !_hasChanges
                  ? null
                  : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAssetInfoCard(),
              const SizedBox(height: 24),
              _buildPriceSection(),
              const SizedBox(height: 24),
              _buildHoldingsSection(),
              const SizedBox(height: 24),
              _buildCalculatedSection(),
              const SizedBox(height: 24),
              if (_transactionCount > 0) _buildRecalculateButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetInfoCard() {
    if (_originalAsset == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAssetTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _originalAsset!.symbol,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _originalAsset!.assetType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Date Added', _formatDate(_originalAsset!.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow('Transactions', '$_transactionCount'),
            const SizedBox(height: 8),
            _buildInfoRow('Last Updated', _formatDate(_originalAsset!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTypeIcon() {
    IconData icon;
    Color color;

    switch (_originalAsset!.assetType.toLowerCase()) {
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Asset Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          enabled: !_isSaving,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _currentPriceController,
          decoration: const InputDecoration(
            labelText: 'Current Price *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isSaving,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _previousCloseController,
          decoration: const InputDecoration(
            labelText: 'Previous Close *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.history),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isSaving,
        ),
      ],
    );
  }

  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Holdings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantity *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
          ],
          enabled: !_isSaving,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _averageCostController,
          decoration: const InputDecoration(
            labelText: 'Average Cost *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isSaving,
        ),
      ],
    );
  }

  Widget _buildCalculatedSection() {
    final investment = _totalInvestment;
    final value = _currentValue;
    final gain = _unrealizedGain;

    if (investment == null || value == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculated Values',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalculatedRow('Total Investment', investment, Colors.black87),
          const SizedBox(height: 8),
          _buildCalculatedRow('Current Value', value, Colors.black87),
          const SizedBox(height: 8),
          _buildCalculatedRow(
            'Unrealized Gain/Loss',
            gain!,
            gain >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecalculateButton() {
    return OutlinedButton.icon(
      onPressed: _isSaving ? null : _handleRecalculate,
      icon: const Icon(Icons.refresh),
      label: const Text('Recalculate from Transactions'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}