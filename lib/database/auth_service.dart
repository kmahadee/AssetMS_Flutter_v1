import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

/// Authentication service for user registration, login, and session management
/// 
/// Handles user authentication, password hashing, and session persistence
/// using SharedPreferences for maintaining logged-in state.
class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  /// SharedPreferences key for storing current user ID
  static const String _currentUserIdKey = 'current_user_id';
  
  /// SharedPreferences key for storing current username
  static const String _currentUsernameKey = 'current_username';

  /// Register a new user
  /// 
  /// Creates a new user account with hashed password.
  /// 
  /// Parameters:
  /// - [username]: Unique username for login
  /// - [email]: User's email address
  /// - [fullName]: User's full display name
  /// - [password]: Plain text password (will be hashed)
  /// 
  /// Returns: The new user's ID
  /// 
  /// Throws:
  /// - [Exception] if username already exists
  /// - [Exception] if validation fails
  Future<int> registerUser(
    String username,
    String email,
    String fullName,
    String password,
  ) async {
    // Validate inputs
    if (!User.validateUsername(username)) {
      throw Exception('Invalid username format');
    }
    
    if (!User.validateEmail(email)) {
      throw Exception('Invalid email format');
    }
    
    if (!User.validateFullName(fullName)) {
      throw Exception('Invalid full name format');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Check if username is available
    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      throw Exception('Username already exists');
    }

    // Hash the password
    final passwordHash = hashPassword(password);
    
    // Create user record
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _dbHelper.database;
    
    final userId = await db.insert('users', {
      'username': username,
      'email': email,
      'full_name': fullName,
      'password_hash': passwordHash,
      'created_at': now,
      'last_login_at': now,
    });

    return userId;
  }

  /// Authenticate user and create session
  /// 
  /// Verifies credentials and saves user session.
  /// 
  /// Parameters:
  /// - [username]: Username for login
  /// - [password]: Plain text password
  /// 
  /// Returns: User object if authentication successful, null otherwise
  Future<User?> loginUser(String username, String password) async {
    final db = await _dbHelper.database;
    
    // Query user by username
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isEmpty) {
      return null; // User not found
    }

    final userData = results.first;
    final storedHash = userData['password_hash'] as String;

    // Verify password
    if (!verifyPassword(password, storedHash)) {
      return null; // Invalid password
    }

    // Update last login timestamp
    await updateLastLogin(userData['id'] as int);

    // Create User object
    final user = User(
      id: userData['id'] as int,
      username: userData['username'] as String,
      email: userData['email'] as String,
      fullName: userData['full_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(userData['created_at'] as int),
      lastLoginAt: DateTime.now(), // Use current time for last login
    );

    // Save current user to session
    await saveCurrentUser(user);

    return user;
  }

  /// Logout current user
  /// 
  /// Clears the user session from SharedPreferences
  Future<void> logoutUser() async {
    await clearCurrentUser();
  }

  /// Get currently logged-in user from session
  /// 
  /// Retrieves user data from database using stored user ID
  /// 
  /// Returns: User object if session exists, null otherwise
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_currentUserIdKey);

    if (userId == null) {
      return null; // No active session
    }

    // Fetch user from database
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) {
      // User was deleted, clear session
      await clearCurrentUser();
      return null;
    }

    final userData = results.first;
    return User(
      id: userData['id'] as int,
      username: userData['username'] as String,
      email: userData['email'] as String,
      fullName: userData['full_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(userData['created_at'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(userData['last_login_at'] as int),
    );
  }

  /// Save current user session
  /// 
  /// Stores user ID and username in SharedPreferences
  Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentUserIdKey, user.id);
    await prefs.setString(_currentUsernameKey, user.username);
  }

  /// Clear current user session
  /// 
  /// Removes all session data from SharedPreferences
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUsernameKey);
  }

  /// Check if username is available for registration
  /// 
  /// Returns: true if username is available, false if taken
  Future<bool> isUsernameAvailable(String username) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    return results.isEmpty;
  }

  /// Update last login timestamp for a user
  /// 
  /// Called automatically during login
  Future<void> updateLastLogin(int userId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'users',
      {'last_login_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Hash a password using base64 encoding
  /// 
  /// NOTE: This is a simple implementation for demo purposes.
  /// In production, use proper password hashing like bcrypt or argon2.
  /// 
  /// Parameters:
  /// - [password]: Plain text password
  /// 
  /// Returns: Hashed password string
  String hashPassword(String password) {
    // Simple demo hashing - use proper hashing in production
    final bytes = utf8.encode(password);
    final base64Hash = base64.encode(bytes);
    
    // Add simple salt for basic security
    final salt = 'portfolio_tracker_salt';
    final saltedPassword = password + salt;
    final saltedBytes = utf8.encode(saltedPassword);
    
    return base64.encode(saltedBytes);
  }

  /// Verify a password against its hash
  /// 
  /// Parameters:
  /// - [password]: Plain text password to verify
  /// - [hash]: Stored password hash
  /// 
  /// Returns: true if password matches hash, false otherwise
  bool verifyPassword(String password, String hash) {
    final computedHash = hashPassword(password);
    return computedHash == hash;
  }

  /// Check if a user session exists
  /// 
  /// Returns: true if user is logged in, false otherwise
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentUserIdKey);
  }

  /// Get current user ID from session
  /// 
  /// Returns: User ID if logged in, null otherwise
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentUserIdKey);
  }

  /// Update user profile information
  /// 
  /// Parameters:
  /// - [userId]: User ID to update
  /// - [email]: New email (optional)
  /// - [fullName]: New full name (optional)
  /// 
  /// Throws: Exception if validation fails
  Future<void> updateUserProfile({
    required int userId,
    String? email,
    String? fullName,
  }) async {
    final updates = <String, dynamic>{};

    if (email != null) {
      if (!User.validateEmail(email)) {
        throw Exception('Invalid email format');
      }
      updates['email'] = email;
    }

    if (fullName != null) {
      if (!User.validateFullName(fullName)) {
        throw Exception('Invalid full name format');
      }
      updates['full_name'] = fullName;
    }

    if (updates.isEmpty) {
      return; // Nothing to update
    }

    final db = await _dbHelper.database;
    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Change user password
  /// 
  /// Parameters:
  /// - [userId]: User ID
  /// - [currentPassword]: Current password for verification
  /// - [newPassword]: New password to set
  /// 
  /// Throws: Exception if current password is wrong or new password is invalid
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    final db = await _dbHelper.database;
    
    // Get current password hash
    final results = await db.query(
      'users',
      columns: ['password_hash'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) {
      throw Exception('User not found');
    }

    final currentHash = results.first['password_hash'] as String;

    // Verify current password
    if (!verifyPassword(currentPassword, currentHash)) {
      throw Exception('Current password is incorrect');
    }

    // Hash and update new password
    final newHash = hashPassword(newPassword);
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}