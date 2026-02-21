import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_tracker/database/asset_service.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/database/transaction_service.dart';
import 'package:portfolio_tracker/dialogs/confirmation_dialog.dart';
import '../../models/transaction.dart';
import '../../models/asset.dart';

/// Screen for editing an existing transaction
/// 
/// Allows modification of transaction details and deletion.
class EditTransactionScreen extends StatefulWidget {
  final int transactionId;

  const EditTransactionScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final _transactionService = TransactionService();
  final _assetService = AssetService();
  final _authService = AuthService();

  Transaction? _originalTransaction;
  Asset? _asset;
  String _transactionType = 'buy';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;
  bool _isSaving = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final transaction = await _transactionService.getTransactionById(
        widget.transactionId,
        userId,
      );
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      final asset = await _assetService.getAssetById(
        transaction.assetId,
        userId,
      );

      setState(() {
        _currentUserId = userId;
        _originalTransaction = transaction;
        _asset = asset;
        _transactionType = transaction.type;
        _selectedDate = transaction.date;
        _selectedTime = TimeOfDay.fromDateTime(transaction.date);
        
        _quantityController.text = transaction.quantity.toString();
        _priceController.text = transaction.pricePerUnit.toStringAsFixed(2);
        _notesController.text = transaction.notes ?? '';
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error loading transaction: ${e.toString()}');
      Navigator.of(context).pop();
    }
  }

  double? get _totalAmount {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    if (quantity == null || price == null) return null;
    return quantity * price;
  }

  bool get _hasChanges {
    if (_originalTransaction == null) return false;
    
    return _transactionType != _originalTransaction!.type ||
        _quantityController.text != _originalTransaction!.quantity.toString() ||
        _priceController.text != _originalTransaction!.pricePerUnit.toStringAsFixed(2) ||
        _notesController.text != (_originalTransaction!.notes ?? '') ||
        !_isSameDay(_selectedDate, _originalTransaction!.date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _isFormValid {
    if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
      return false;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    return quantity > 0 && price > 0;
  }

  Future<void> _handleSave() async {
    if (_currentUserId == null || _originalTransaction == null) return;
    if (!_isFormValid) {
      _showErrorSnackBar('Please fill all fields correctly');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transactionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedTransaction = _originalTransaction!.copyWith(
        type: _transactionType,
        quantity: double.parse(_quantityController.text),
        pricePerUnit: double.parse(_priceController.text),
        date: transactionDateTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _transactionService.updateTransaction(updatedTransaction);

      // Recalculate asset holdings
      await _transactionService.updateAssetQuantityAndCost(
        _currentUserId!,
        _originalTransaction!.assetId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Transaction updated successfully'),
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
      _showErrorSnackBar('Error updating transaction: ${e.toString()}');
    }
  }

  Future<void> _handleDelete() async {
    if (_currentUserId == null || _originalTransaction == null || _asset == null) {
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Transaction?',
      message: 'This transaction will be permanently deleted. The asset holdings will be recalculated.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _transactionService.deleteTransaction(
        widget.transactionId,
        _currentUserId!,
      );

      // Recalculate asset holdings
      await _transactionService.updateAssetQuantityAndCost(
        _currentUserId!,
        _originalTransaction!.assetId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Transaction deleted'),
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
      _showErrorSnackBar('Error deleting transaction: ${e.toString()}');
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
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Transaction'),
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
              if (_asset != null) _buildAssetCard(),
              const SizedBox(height: 24),
              _buildTransactionTypeSection(),
              const SizedBox(height: 24),
              _buildDetailsSection(),
              const SizedBox(height: 24),
              if (_totalAmount != null) _buildTotalAmountCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard() {
    return Card(
      child: ListTile(
        leading: _buildAssetIcon(_asset!.assetType),
        title: Text(
          _asset!.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_asset!.name),
        trailing: Text(
          '\$${_asset!.currentPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
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
          onSelectionChanged: _isSaving
              ? null
              : (Set<String> selected) {
                  setState(() {
                    _transactionType = selected.first;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Date'),
                subtitle: Text(_formatDate(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                onTap: _isSaving ? null : _selectDate,
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
                onTap: _isSaving ? null : _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
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
          enabled: !_isSaving,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          maxLength: 500,
          enabled: !_isSaving,
        ),
      ],
    );
  }

  Widget _buildTotalAmountCard() {
    return Container(
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
              color: _transactionType == 'buy' ? Colors.green : Colors.red,
            ),
          ),
        ],
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