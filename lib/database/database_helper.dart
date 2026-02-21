import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Singleton DatabaseHelper for managing the SQLite database
/// 
/// Handles database creation, versioning, and lifecycle management
/// for the portfolio tracker application with multi-user support.
/// Supports mobile, web, and desktop platforms.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _isInitialized = false;

  /// Database name
  static const String _databaseName = 'portfolio_tracker.db';
  
  /// Database version
  static const int _databaseVersion = 1;

  /// Private constructor for singleton pattern
  DatabaseHelper._internal();

  /// Factory constructor returns singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  /// Initialize the database factory for the current platform
  /// 
  /// This must be called before any database operations.
  /// It's safe to call multiple times.
  static void initializeDatabaseFactory() {
    if (_isInitialized) return;

    // Initialize database factory for desktop/web platforms
    if (kIsWeb) {
      // For web, use the FFI implementation
      databaseFactory = databaseFactoryFfi;
    } else if (!Platform.isAndroid && !Platform.isIOS) {
      // For desktop platforms (Windows, Linux, macOS)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // For Android and iOS, the default sqflite factory is already set

    _isInitialized = true;
  }

  /// Get database instance with lazy initialization
  /// 
  /// Creates the database on first access and returns
  /// the existing instance on subsequent calls
  Future<Database> get database async {
    // Ensure database factory is initialized
    initializeDatabaseFactory();

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  /// 
  /// Creates database file and sets up configuration
  Future<Database> _initDatabase() async {
    String path;
    
    if (kIsWeb) {
      // For web, use a simple path
      path = _databaseName;
    } else {
      // For mobile and desktop, use the standard databases path
      final databasePath = await getDatabasesPath();
      path = join(databasePath, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings
  /// 
  /// Enables foreign key constraints for referential integrity
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database schema
  /// 
  /// Creates all tables and indexes for the application
  Future<void> _onCreate(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        full_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_login_at INTEGER NOT NULL
      )
    ''');

    // Create Assets table
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        symbol TEXT NOT NULL,
        name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        current_price REAL NOT NULL,
        previous_close REAL NOT NULL,
        quantity REAL NOT NULL,
        average_cost REAL NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        asset_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('buy', 'sell')),
        quantity REAL NOT NULL,
        price_per_unit REAL NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');

    // Create App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, setting_key)
      )
    ''');

    // Create indexes for performance optimization
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_assets_user_id ON assets(user_id)');
    await db.execute('CREATE INDEX idx_assets_symbol ON assets(symbol)');
    await db.execute('CREATE INDEX idx_assets_type ON assets(asset_type)');
    await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
    await db.execute('CREATE INDEX idx_transactions_asset_id ON transactions(asset_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_settings_user_id ON app_settings(user_id)');
  }

  /// Close the database connection
  /// 
  /// Should be called when the app is closing to properly
  /// release database resources
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete the entire database
  /// 
  /// WARNING: This will delete all user data permanently.
  /// Use with caution, typically only for testing or app reset.
  Future<void> deleteDatabase() async {
    String path;
    
    if (kIsWeb) {
      path = _databaseName;
    } else {
      final databasePath = await getDatabasesPath();
      path = join(databasePath, _databaseName);
    }
    
    // Close existing connection first
    await close();
    
    // Delete the database file
    await databaseFactory.deleteDatabase(path);
  }

  /// Clear all data for a specific user
  /// 
  /// Deletes the user and all associated data (cascading).
  /// This includes assets, transactions, and settings.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose data should be deleted
  Future<void> clearUserData(int userId) async {
    final db = await database;
    
    // Use transaction to ensure atomicity
    await db.transaction((txn) async {
      // Delete user (will cascade to assets, transactions, and settings)
      await txn.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
  }

  /// Reset database to initial state
  /// 
  /// Deletes and recreates the database from scratch.
  /// All data will be lost.
  Future<void> resetDatabase() async {
    await deleteDatabase();
    _database = await _initDatabase();
  }

  /// Get database statistics
  /// 
  /// Returns count of records in each table
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final userCount = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final assetCount = await db.rawQuery('SELECT COUNT(*) as count FROM assets');
    final transactionCount = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
    final settingsCount = await db.rawQuery('SELECT COUNT(*) as count FROM app_settings');

    return {
      'users': userCount.first['count'] as int,
      'assets': assetCount.first['count'] as int,
      'transactions': transactionCount.first['count'] as int,
      'settings': settingsCount.first['count'] as int,
    };
  }
}





// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// /// Singleton DatabaseHelper for managing the SQLite database
// /// 
// /// Handles database creation, versioning, and lifecycle management
// /// for the portfolio tracker application with multi-user support.
// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   static Database? _database;

//   /// Database name
//   static const String _databaseName = 'portfolio_tracker.db';
  
//   /// Database version
//   static const int _databaseVersion = 1;

//   /// Private constructor for singleton pattern
//   DatabaseHelper._internal();

//   /// Factory constructor returns singleton instance
//   factory DatabaseHelper() {
//     return _instance;
//   }

//   /// Get database instance with lazy initialization
//   /// 
//   /// Creates the database on first access and returns
//   /// the existing instance on subsequent calls
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   /// Initialize the database
//   /// 
//   /// Creates database file and sets up configuration
//   Future<Database> _initDatabase() async {
//     final databasePath = await getDatabasesPath();
//     final path = join(databasePath, _databaseName);

//     return await openDatabase(
//       path,
//       version: _databaseVersion,
//       onCreate: _onCreate,
//       onConfigure: _onConfigure,
//     );
//   }

//   /// Configure database settings
//   /// 
//   /// Enables foreign key constraints for referential integrity
//   Future<void> _onConfigure(Database db) async {
//     await db.execute('PRAGMA foreign_keys = ON');
//   }

//   /// Create database schema
//   /// 
//   /// Creates all tables and indexes for the application
//   Future<void> _onCreate(Database db, int version) async {
//     // Create Users table
//     await db.execute('''
//       CREATE TABLE users (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         username TEXT NOT NULL UNIQUE,
//         email TEXT NOT NULL,
//         full_name TEXT NOT NULL,
//         password_hash TEXT NOT NULL,
//         created_at INTEGER NOT NULL,
//         last_login_at INTEGER NOT NULL
//       )
//     ''');

//     // Create Assets table
//     await db.execute('''
//       CREATE TABLE assets (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         user_id INTEGER NOT NULL,
//         symbol TEXT NOT NULL,
//         name TEXT NOT NULL,
//         asset_type TEXT NOT NULL,
//         current_price REAL NOT NULL,
//         previous_close REAL NOT NULL,
//         quantity REAL NOT NULL,
//         average_cost REAL NOT NULL,
//         created_at INTEGER NOT NULL,
//         updated_at INTEGER NOT NULL,
//         FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
//       )
//     ''');

//     // Create Transactions table
//     await db.execute('''
//       CREATE TABLE transactions (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         user_id INTEGER NOT NULL,
//         asset_id INTEGER NOT NULL,
//         type TEXT NOT NULL CHECK(type IN ('buy', 'sell')),
//         quantity REAL NOT NULL,
//         price_per_unit REAL NOT NULL,
//         date INTEGER NOT NULL,
//         notes TEXT,
//         created_at INTEGER NOT NULL,
//         FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
//         FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
//       )
//     ''');

//     // Create App Settings table
//     await db.execute('''
//       CREATE TABLE app_settings (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         user_id INTEGER NOT NULL,
//         setting_key TEXT NOT NULL,
//         setting_value TEXT NOT NULL,
//         updated_at INTEGER NOT NULL,
//         FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
//         UNIQUE(user_id, setting_key)
//       )
//     ''');

//     // Create indexes for performance optimization
//     await db.execute('CREATE INDEX idx_users_username ON users(username)');
//     await db.execute('CREATE INDEX idx_assets_user_id ON assets(user_id)');
//     await db.execute('CREATE INDEX idx_assets_symbol ON assets(symbol)');
//     await db.execute('CREATE INDEX idx_assets_type ON assets(asset_type)');
//     await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
//     await db.execute('CREATE INDEX idx_transactions_asset_id ON transactions(asset_id)');
//     await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
//     await db.execute('CREATE INDEX idx_settings_user_id ON app_settings(user_id)');
//   }

//   /// Close the database connection
//   /// 
//   /// Should be called when the app is closing to properly
//   /// release database resources
//   Future<void> close() async {
//     if (_database != null) {
//       await _database!.close();
//       _database = null;
//     }
//   }

//   /// Delete the entire database
//   /// 
//   /// WARNING: This will delete all user data permanently.
//   /// Use with caution, typically only for testing or app reset.
//   Future<void> deleteDatabase() async {
//     final databasePath = await getDatabasesPath();
//     final path = join(databasePath, _databaseName);
    
//     // Close existing connection first
//     await close();
    
//     // Delete the database file
//     await databaseFactory.deleteDatabase(path);
//   }

//   /// Clear all data for a specific user
//   /// 
//   /// Deletes the user and all associated data (cascading).
//   /// This includes assets, transactions, and settings.
//   /// 
//   /// Parameters:
//   /// - [userId]: ID of the user whose data should be deleted
//   Future<void> clearUserData(int userId) async {
//     final db = await database;
    
//     // Use transaction to ensure atomicity
//     await db.transaction((txn) async {
//       // Delete user (cascades to assets, transactions, and settings)
//       await txn.delete(
//         'users',
//         where: 'id = ?',
//         whereArgs: [userId],
//       );
//     });
//   }

//   /// Get database statistics for a user
//   /// 
//   /// Returns a map with counts of assets, transactions, and settings
//   /// Useful for debugging or displaying user data summary
//   Future<Map<String, int>> getUserStats(int userId) async {
//     final db = await database;
    
//     final assetCount = Sqflite.firstIntValue(
//       await db.rawQuery(
//         'SELECT COUNT(*) FROM assets WHERE user_id = ?',
//         [userId],
//       ),
//     ) ?? 0;
    
//     final transactionCount = Sqflite.firstIntValue(
//       await db.rawQuery(
//         'SELECT COUNT(*) FROM transactions WHERE user_id = ?',
//         [userId],
//       ),
//     ) ?? 0;
    
//     final settingCount = Sqflite.firstIntValue(
//       await db.rawQuery(
//         'SELECT COUNT(*) FROM app_settings WHERE user_id = ?',
//         [userId],
//       ),
//     ) ?? 0;
    
//     return {
//       'assets': assetCount,
//       'transactions': transactionCount,
//       'settings': settingCount,
//     };
//   }

//   /// Verify database integrity
//   /// 
//   /// Runs SQLite integrity check
//   /// Returns true if database is valid, false otherwise
//   Future<bool> checkIntegrity() async {
//     final db = await database;
//     final result = await db.rawQuery('PRAGMA integrity_check');
//     return result.isNotEmpty && result.first['integrity_check'] == 'ok';
//   }
// }