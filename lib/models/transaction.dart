/// Transaction model representing a buy or sell transaction for an asset
///
/// This class records all portfolio transactions including purchases and sales
/// with complete details for tracking and reporting.
class Transaction {
  /// Unique identifier for the transaction (SQLite primary key)
  /// Null for new transactions that haven't been saved to the database yet
  final int? id;

  /// Foreign key reference to the user who made this transaction
  final int userId;

  /// Foreign key reference to the asset being transacted
  final int assetId;

  /// Type of transaction: 'buy' or 'sell'
  final String type;

  /// Number of units/shares transacted
  final double quantity;

  /// Price per unit at the time of transaction
  final double pricePerUnit;

  /// Date and time when the transaction occurred
  final DateTime date;

  /// Optional notes or comments about the transaction
  final String? notes;

  /// Timestamp when this transaction record was created
  final DateTime createdAt;

  /// Creates a new Transaction instance
  ///
  /// [id] is nullable for new transactions not yet saved to database
  /// [notes] is optional and can be null
  ///
  /// Validates that:
  /// - type is either 'buy' or 'sell'
  /// - quantity is positive
  /// - pricePerUnit is positive
  ///
  /// Throws [ArgumentError] if validation fails
  Transaction({
    this.id,
    required this.userId,
    required this.assetId,
    required this.type,
    required this.quantity,
    required this.pricePerUnit,
    required this.date,
    this.notes,
    required this.createdAt,
  }) {
    // Validate transaction type
    if (!validateTransactionType(type)) {
      throw ArgumentError(
        'Invalid transaction type: $type. Must be "buy" or "sell".',
      );
    }

    // Validate quantity is positive
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be positive, got: $quantity');
    }

    // Validate pricePerUnit is positive
    if (pricePerUnit <= 0) {
      throw ArgumentError(
        'Price per unit must be positive, got: $pricePerUnit',
      );
    }
  }

  /// Total monetary amount of this transaction
  ///
  /// Calculated as: quantity * pricePerUnit
  double get totalAmount => quantity * pricePerUnit;

  /// Converts the Transaction object to a Map for SQLite storage
  ///
  /// DateTime objects are converted to milliseconds since epoch
  /// Excludes id if it's null (for INSERT operations)
  // Map<String, dynamic> toMap() {
  //   final map = <String, dynamic>{
  //     'userId': userId,
  //     'assetId': assetId,
  //     'type': type,
  //     'quantity': quantity,
  //     'pricePerUnit': pricePerUnit,
  //     'date': date.millisecondsSinceEpoch,
  //     'notes': notes,
  //     'createdAt': createdAt.millisecondsSinceEpoch,
  //   };

  //   if (id != null) {
  //     map['id'] = id;
  //   }

  //   return map;
  // }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId, // CHANGED: was 'userId'
      'asset_id': assetId, // CHANGED: was 'assetId'
      'type': type,
      'quantity': quantity,
      'price_per_unit': pricePerUnit, // CHANGED: was 'pricePerUnit'
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at':
          createdAt.millisecondsSinceEpoch, // CHANGED: was 'createdAt'
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a Transaction object from a SQLite Map
  ///
  /// Converts millisecond timestamps back to DateTime objects
  // factory Transaction.fromMap(Map<String, dynamic> map) {
  //   return Transaction(
  //     id: map['id'] as int?,
  //     userId: map['userId'] as int,
  //     assetId: map['assetId'] as int,
  //     type: map['type'] as String,
  //     quantity: (map['quantity'] as num).toDouble(),
  //     pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
  //     date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
  //     notes: map['notes'] as String?,
  //     createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  //   );
  // }
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      userId: map['user_id'] as int, // CHANGED: was 'userId'
      assetId: map['asset_id'] as int, // CHANGED: was 'assetId'
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      pricePerUnit: (map['price_per_unit'] as num)
          .toDouble(), // CHANGED: was 'pricePerUnit'
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ), // CHANGED: was 'createdAt'
    );
  }

  /// Creates a copy of this Transaction with the given fields replaced
  ///
  /// Any null parameters will use the current value
  /// Note: Validation is performed in the constructor, so invalid
  /// values will throw ArgumentError
  Transaction copyWith({
    int? id,
    int? userId,
    int? assetId,
    String? type,
    double? quantity,
    double? pricePerUnit,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validates the transaction type
  ///
  /// Valid types are: 'buy' or 'sell' (case-insensitive)
  /// Returns true if valid, false otherwise
  static bool validateTransactionType(String type) {
    const validTypes = ['buy', 'sell'];
    return validTypes.contains(type.toLowerCase());
  }

  /// Validates that a quantity value is positive
  ///
  /// Returns true if quantity is greater than 0
  static bool validateQuantity(double quantity) {
    return quantity > 0;
  }

  /// Validates that a price is positive
  ///
  /// Returns true if price is greater than 0
  static bool validatePrice(double price) {
    return price > 0;
  }

  /// Validates that a date is not in the future
  ///
  /// Returns true if date is today or in the past
  static bool validateTransactionDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now) || date.isAtSameMomentAs(now);
  }

  /// Returns true if this is a buy transaction
  bool get isBuy => type.toLowerCase() == 'buy';

  /// Returns true if this is a sell transaction
  bool get isSell => type.toLowerCase() == 'sell';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Transaction &&
        other.id == id &&
        other.userId == userId &&
        other.assetId == assetId &&
        other.type == type &&
        other.quantity == quantity &&
        other.pricePerUnit == pricePerUnit &&
        other.date == date &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      assetId,
      type,
      quantity,
      pricePerUnit,
      date,
      notes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, assetId: $assetId, type: $type, quantity: $quantity, pricePerUnit: $pricePerUnit, date: $date, notes: $notes, createdAt: $createdAt)';
  }
}
