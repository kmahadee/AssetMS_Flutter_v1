import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_tracker/database/asset_service.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/database/transaction_service.dart';
import 'package:portfolio_tracker/widgets/asset_search_delegate.dart';
import '../../models/asset.dart';
import '../../models/transaction.dart';

/// Screen for adding a new transaction
/// 
/// Provides transaction type selection, asset selection, and impact preview.
class AddTransactionScreen extends StatefulWidget {
  final Asset? preselectedAsset;

  const AddTransactionScreen({
    super.key,
    this.preselectedAsset,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final _assetService = AssetService();
  final _transactionService = TransactionService();
  final _authService = AuthService();

  String _transactionType = 'buy';
  Asset? _selectedAsset;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  int? _currentUserId;
  List<Asset> _userAssets = [];

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.preselectedAsset;
    _loadUserData();
    _quantityController.addListener(_updateCalculations);
    _priceController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    setState(() {
      _currentUserId = userId;
    });

    final assets = await _assetService.getAllAssets(userId);
    setState(() {
      _userAssets = assets;
    });

    // Set default price if asset is selected
    if (_selectedAsset != null) {
      _priceController.text = _selectedAsset!.currentPrice.toStringAsFixed(2);
    }
  }

  void _updateCalculations() {
    setState(() {}); // Trigger rebuild
  }

  double? get _totalAmount {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    if (quantity == null || price == null) return null;
    return quantity * price;
  }

  double? get _newQuantity {
    if (_selectedAsset == null) return null;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    return _transactionType == 'buy'
        ? _selectedAsset!.quantity + quantity
        : _selectedAsset!.quantity - quantity;
  }

  double? get _newAverageCost {
    if (_selectedAsset == null) return null;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (_transactionType == 'buy') {
      final totalCost = (_selectedAsset!.quantity * _selectedAsset!.averageCost) +
          (quantity * price);
      final totalQuantity = _selectedAsset!.quantity + quantity;
      return totalQuantity > 0 ? totalCost / totalQuantity : 0;
    }
    
    return _selectedAsset!.averageCost; // Doesn't change on sell
  }

  double? get _realizedGain {
    if (_selectedAsset == null || _transactionType != 'sell') return null;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return (price - _selectedAsset!.averageCost) * quantity;
  }

  bool get _isFormValid {
    if (_selectedAsset == null) return false;
    if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
      return false;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (quantity <= 0 || price <= 0) return false;

    // For sells, check if quantity is available
    if (_transactionType == 'sell' && quantity > _selectedAsset!.quantity) {
      return false;
    }

    return true;
  }

  String? get _quantityError {
    if (_quantityController.text.isEmpty) return null;
    
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (_transactionType == 'sell' &&
        _selectedAsset != null &&
        quantity > _selectedAsset!.quantity) {
      return 'Cannot sell more than you own (${_selectedAsset!.quantity})';
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (_currentUserId == null || _selectedAsset == null) return;
    if (!_isFormValid) {
      _showErrorSnackBar('Please fill all fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        userId: _currentUserId!,
        assetId: _selectedAsset!.id!,
        type: _transactionType,
        quantity: double.parse(_quantityController.text),
        pricePerUnit: double.parse(_priceController.text),
        date: transactionDateTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _transactionService.insertTransaction(transaction);

      // Update asset quantity and average cost
      await _transactionService.updateAssetQuantityAndCost(
        _currentUserId!,
        _selectedAsset!.id!,
      );

      if (!mounted) return;

      // Show success message
      final message = _transactionType == 'buy'
          ? 'Purchase recorded'
          : _realizedGain != null
              ? 'Sale recorded - ${_realizedGain! >= 0 ? 'Gain' : 'Loss'}: \$${_realizedGain!.abs().toStringAsFixed(2)}'
              : 'Sale recorded';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
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
        _isLoading = false;
      });
      _showErrorSnackBar('Error saving transaction: ${e.toString()}');
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
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
            _buildTransactionTypeSection(),
            const SizedBox(height: 24),
            _buildAssetSelectionSection(),
            if (_selectedAsset != null) ...[
              const SizedBox(height: 24),
              _buildTransactionDetailsSection(),
              const SizedBox(height: 24),
              _buildImpactPreviewSection(),
            ],
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'buy',
              label: Text('BUY'),
              icon: Icon(Icons.add_shopping_cart),
            ),
            ButtonSegment(
              value: 'sell',
              label: Text('SELL'),
              icon: Icon(Icons.sell),
            ),
          ],
          selected: {_transactionType},
          onSelectionChanged: (Set<String> selected) {
            setState(() {
              _transactionType = selected.first;
            });
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: _transactionType == 'buy'
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            selectedForegroundColor:
                _transactionType == 'buy' ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedAsset != null)
          Card(
            child: ListTile(
              leading: _buildAssetIcon(_selectedAsset!.assetType),
              title: Text(
                _selectedAsset!.symbol,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_selectedAsset!.name),
              trailing: widget.preselectedAsset == null
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _selectAsset,
                    )
                  : Text(
                      '\$${_selectedAsset!.currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _selectAsset,
            icon: const Icon(Icons.search),
            label: const Text('Select Asset'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Date and Time
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Date'),
                subtitle: Text(_formatDate(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListTile(
                title: const Text('Time'),
                subtitle: Text(_selectedTime.format(context)),
                leading: const Icon(Icons.access_time),
                onTap: _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Quick date shortcuts
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDateShortcut('Today', DateTime.now()),
              const SizedBox(width: 8),
              _buildDateShortcut(
                'Yesterday',
                DateTime.now().subtract(const Duration(days: 1)),
              ),
              const SizedBox(width: 8),
              _buildDateShortcut(
                'Last Week',
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Quantity
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: 'Quantity *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.numbers),
            errorText: _quantityError,
            suffixIcon: _quantityError == null &&
                    _quantityController.text.isNotEmpty
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
          ],
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        
        // Price
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Price per Unit *',
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
        
        // Total amount display
        if (_totalAmount != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _transactionType == 'buy'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _transactionType == 'buy'
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${_totalAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _transactionType == 'buy'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Notes
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
    );
  }

  Widget _buildImpactPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Impact Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildImpactRow(
            'Current Holdings',
            '${_selectedAsset!.quantity} units',
          ),
          if (_newQuantity != null) ...[
            const SizedBox(height: 8),
            _buildImpactRow(
              'After Transaction',
              '${_newQuantity!.toStringAsFixed(8)} units',
            ),
          ],
          if (_transactionType == 'buy' && _newAverageCost != null) ...[
            const SizedBox(height: 8),
            _buildImpactRow(
              'New Average Cost',
              '\$${_newAverageCost!.toStringAsFixed(2)}',
            ),
          ],
          if (_transactionType == 'sell' && _realizedGain != null) ...[
            const SizedBox(height: 8),
            _buildImpactRow(
              'Realized ${_realizedGain! >= 0 ? 'Gain' : 'Loss'}',
              '\$${_realizedGain!.abs().toStringAsFixed(2)}',
              color: _realizedGain! >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDateShortcut(String label, DateTime date) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedDate = date;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
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
                'Save Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
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

  Future<void> _selectAsset() async {
    final result = await showSearch(
      context: context,
      delegate: AssetSearchDelegate(
        assets: _userAssets,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAsset = result;
        _priceController.text = result.currentPrice.toStringAsFixed(2);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}