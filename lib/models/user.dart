/// User model representing a portfolio tracker user
/// 
/// This class handles user data including authentication details,
/// profile information, and activity timestamps.
class User {
  /// Unique identifier for the user (SQLite primary key)
  final int id;

  /// Unique username for login
  final String username;

  /// User's email address
  final String email;

  /// User's full display name
  final String fullName;

  /// Timestamp when the user account was created
  final DateTime createdAt;

  /// Timestamp of the user's last login
  final DateTime lastLoginAt;

  /// Creates a new User instance
  /// 
  /// All parameters are required and must not be null
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Converts the User object to a Map for SQLite storage
  /// 
  /// DateTime objects are converted to milliseconds since epoch
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a User object from a SQLite Map
  /// 
  /// Converts millisecond timestamps back to DateTime objects
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: map['fullName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int),
    );
  }

  /// Creates a copy of this User with the given fields replaced
  /// 
  /// Any null parameters will use the current value
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Validates an email address format
  /// 
  /// Returns true if the email matches a basic email pattern
  /// Returns false for invalid formats
  static bool validateEmail(String email) {
    if (email.isEmpty) return false;
    
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email);
  }

  /// Validates a username
  /// 
  /// Rules:
  /// - Must be at least 3 characters long
  /// - Must be no more than 20 characters long
  /// - Can only contain letters, numbers, underscores, and hyphens
  /// - Must start with a letter or number
  /// 
  /// Returns true if valid, false otherwise
  static bool validateUsername(String username) {
    if (username.isEmpty) return false;
    if (username.length < 3 || username.length > 20) return false;
    
    // Username validation: alphanumeric, underscore, hyphen, starts with alphanumeric
    final usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$');
    
    return usernameRegex.hasMatch(username);
  }

  /// Validates the full name
  /// 
  /// Rules:
  /// - Must be at least 2 characters long
  /// - Must be no more than 50 characters long
  /// - Can contain letters, spaces, hyphens, and apostrophes
  /// 
  /// Returns true if valid, false otherwise
  static bool validateFullName(String fullName) {
    if (fullName.isEmpty) return false;
    if (fullName.length < 2 || fullName.length > 50) return false;
    
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    
    return nameRegex.hasMatch(fullName.trim());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.fullName == fullName &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      email,
      fullName,
      createdAt,
      lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fullName: $fullName, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }
}