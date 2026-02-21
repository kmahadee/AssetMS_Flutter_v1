import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_tracker/database/asset_service.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/database/transaction_service.dart';
import '../../models/asset.dart';
import '../../models/transaction.dart';

/// Screen for adding a new asset to the portfolio
/// 
/// Provides comprehensive form validation, real-time calculations,
/// and optional initial transaction creation.
class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _previousCloseController = TextEditingController();
  final _quantityController = TextEditingController();
  final _averageCostController = TextEditingController();
  final _notesController = TextEditingController();

  final _assetService = AssetService();
  final _transactionService = TransactionService();
  final _authService = AuthService();

  String _selectedAssetType = 'stock';
  bool _addInitialTransaction = false;
  DateTime _transactionDate = DateTime.now();
  bool _isLoading = false;
  bool _symbolExists = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _symbolController.addListener(_checkSymbolDuplicate);
    _currentPriceController.addListener(_updateCalculations);
    _quantityController.addListener(_updateCalculations);
    _averageCostController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _currentPriceController.dispose();
    _previousCloseController.dispose();
    _quantityController.dispose();
    _averageCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _checkSymbolDuplicate() async {
    if (_currentUserId == null || _symbolController.text.length < 2) {
      setState(() {
        _symbolExists = false;
      });
      return;
    }

    final exists = await _assetService.symbolExists(
      _currentUserId!,
      _symbolController.text,
    );
    setState(() {
      _symbolExists = exists;
    });
  }

  void _updateCalculations() {
    setState(() {}); // Trigger rebuild to update calculations
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

  bool get _isFormValid {
    return _symbolController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _currentPriceController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _averageCostController.text.isNotEmpty &&
        !_symbolExists &&
        (double.tryParse(_currentPriceController.text) ?? 0) > 0 &&
        (double.tryParse(_quantityController.text) ?? 0) > 0 &&
        (double.tryParse(_averageCostController.text) ?? 0) > 0;
  }

  Future<void> _handleSave() async {
    if (_currentUserId == null) {
      _showErrorSnackBar('User not logged in');
      return;
    }

    if (!_isFormValid) {
      _showErrorSnackBar('Please fill all required fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final currentPrice = double.parse(_currentPriceController.text);
      final previousClose = _previousCloseController.text.isEmpty
          ? currentPrice
          : double.parse(_previousCloseController.text);

      // Create asset
      final asset = Asset(
        userId: _currentUserId!,
        symbol: _symbolController.text.toUpperCase().trim(),
        name: _nameController.text.trim(),
        assetType: _selectedAssetType,
        currentPrice: currentPrice,
        previousClose: previousClose,
        quantity: double.parse(_quantityController.text),
        averageCost: double.parse(_averageCostController.text),
        createdAt: now,
        updatedAt: now,
      );

      final assetId = await _assetService.insertAsset(asset);

      // Create initial transaction if enabled
      if (_addInitialTransaction) {
        final transaction = Transaction(
          userId: _currentUserId!,
          assetId: assetId,
          type: 'buy',
          quantity: double.parse(_quantityController.text),
          pricePerUnit: double.parse(_averageCostController.text),
          date: _transactionDate,
          notes: _notesController.text.trim().isEmpty
              ? 'Initial purchase'
              : _notesController.text.trim(),
          createdAt: now,
        );

        await _transactionService.insertTransaction(transaction);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${asset.symbol} added successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error saving asset: ${e.toString()}');
    }
  }

  Future<bool> _handleWillPop() async {
    // Check if form has any data
    if (_symbolController.text.isEmpty &&
        _nameController.text.isEmpty &&
        _currentPriceController.text.isEmpty &&
        _quantityController.text.isEmpty &&
        _averageCostController.text.isEmpty) {
      return true;
    }

    // Show confirmation dialog
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
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Asset'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _handleWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _isLoading || !_isFormValid ? null : _handleSave,
              child: _isLoading
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
              _buildAssetTypeSection(),
              const SizedBox(height: 24),
              _buildAssetInformationSection(),
              const SizedBox(height: 24),
              _buildHoldingsSection(),
              const SizedBox(height: 24),
              _buildCalculatedSection(),
              const SizedBox(height: 24),
              _buildInitialTransactionSection(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'stock',
              label: Text('Stock'),
              icon: Icon(Icons.show_chart),
            ),
            ButtonSegment(
              value: 'crypto',
              label: Text('Crypto'),
              icon: Icon(Icons.currency_bitcoin),
            ),
            ButtonSegment(
              value: 'etf',
              label: Text('ETF'),
              icon: Icon(Icons.pie_chart),
            ),
          ],
          selected: {_selectedAssetType},
          onSelectionChanged: (Set<String> selected) {
            setState(() {
              _selectedAssetType = selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAssetInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Symbol field
        TextFormField(
          controller: _symbolController,
          decoration: InputDecoration(
            labelText: 'Symbol *',
            hintText: 'e.g., AAPL',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.tag),
            errorText: _symbolExists ? 'Symbol already exists in portfolio' : null,
            suffixIcon: _symbolController.text.isNotEmpty && !_symbolExists
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
            LengthLimitingTextInputFormatter(10),
          ],
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        
        // Name field
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name *',
            hintText: 'e.g., Apple Inc.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            LengthLimitingTextInputFormatter(100),
          ],
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        
        // Current Price
        TextFormField(
          controller: _currentPriceController,
          decoration: const InputDecoration(
            labelText: 'Current Price *',
            hintText: '0.00',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        
        // Previous Close
        TextFormField(
          controller: _previousCloseController,
          decoration: const InputDecoration(
            labelText: 'Previous Close (Optional)',
            hintText: '0.00',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.history),
            helperText: 'Defaults to current price if empty',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Holdings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Quantity
        TextFormField(
          controller: _quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantity Owned *',
            hintText: '0',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
            helperText: 'Number of shares/units you own',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
          ],
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        
        // Average Cost
        TextFormField(
          controller: _averageCostController,
          decoration: const InputDecoration(
            labelText: 'Average Cost Basis *',
            hintText: '0.00',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            helperText: 'Your average purchase price per unit',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isLoading,
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

  Widget _buildInitialTransactionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _addInitialTransaction,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _addInitialTransaction = value;
                  });
                },
          title: const Text('Add initial purchase transaction'),
          subtitle: const Text('Record when you bought this asset'),
        ),
        if (_addInitialTransaction) ...[
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Purchase Date'),
            subtitle: Text(
              '${_transactionDate.year}-${_transactionDate.month.toString().padLeft(2, '0')}-${_transactionDate.day.toString().padLeft(2, '0')}',
            ),
            leading: const Icon(Icons.calendar_today),
            trailing: const Icon(Icons.edit),
            onTap: _isLoading ? null : _selectDate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add notes about this transaction...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            maxLength: 500,
            enabled: !_isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid ? null : _handleSave,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Asset',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }
}