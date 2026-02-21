import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../services/portfolio_provider.dart';
import '../database/database_helper.dart';
import '../database/asset_service.dart';
import '../database/transaction_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/formatters.dart';

/// Settings Screen
/// 
/// Provides app configuration, account management, and database operations:
/// - Account information and management
/// - Demo mode controls
/// - Appearance settings
/// - Price update configuration
/// - Database management
/// - Data export/import (future)
/// - Danger zone (clear data, logout)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AssetService _assetService = AssetService();
  final TransactionService _transactionService = TransactionService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  /// Theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  /// Auto update enabled
  bool _autoUpdateEnabled = true;
  
  /// Update frequency in seconds
  double _updateFrequency = 5.0;
  
  /// Database statistics
  int _assetCount = 0;
  int _transactionCount = 0;
  String _databasePath = '';
  double _databaseSize = 0.0;
  DateTime? _lastUpdate;
  
  /// Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDatabaseStats();
  }

  /// Load saved settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        final themeModeStr = prefs.getString('theme_mode') ?? 'system';
        _themeMode = _parseThemeMode(themeModeStr);
        _autoUpdateEnabled = prefs.getBool('auto_update_enabled') ?? true;
        _updateFrequency = prefs.getDouble('update_frequency') ?? 5.0;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  /// Load database statistics
  Future<void> _loadDatabaseStats() async {
    try {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      
      if (provider.currentUser != null) {
        // Get counts from database
        final assets = await _assetService.getAllAssets(provider.currentUser!.id);
        final transactions = await _transactionService.getAllTransactions(provider.currentUser!.id);
        
        // Get database path and size
        final databasesPath = await getDatabasesPath();
        final dbPath = path.join(databasesPath, 'portfolio_tracker.db');
        
        double dbSize = 0.0;
        if (await File(dbPath).exists()) {
          final file = File(dbPath);
          final bytes = await file.length();
          dbSize = bytes / (1024 * 1024); // Convert to MB
        }
        
        setState(() {
          _assetCount = assets.length;
          _transactionCount = transactions.length;
          _databasePath = dbPath;
          _databaseSize = dbSize;
          _lastUpdate = provider.lastUpdate;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading database stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save theme mode
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    setState(() {
      _themeMode = mode;
    });
  }

  /// Save auto update setting
  Future<void> _saveAutoUpdate(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update_enabled', enabled);
    
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    if (enabled) {
      provider.startPriceUpdates();
    } else {
      provider.stopPriceUpdates();
    }
    
    setState(() {
      _autoUpdateEnabled = enabled;
    });
  }

  /// Save update frequency
  Future<void> _saveUpdateFrequency(double frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('update_frequency', frequency);
    setState(() {
      _updateFrequency = frequency;
    });
  }

  /// Reset demo data
  Future<void> _resetDemoData() async {
    final confirmed = await _showConfirmationDialog(
      'Reset Demo Data',
      'This will clear all current assets and transactions and reload demo data. Continue?',
    );

    if (confirmed == true && mounted) {
      try {
        _showLoadingDialog();
        
        final provider = Provider.of<PortfolioProvider>(context, listen: false);
        
        // Clear current data
        await provider.clearUserData();
        
        // Note: In a real app, you would have DemoDataGenerator.clearAndReseed()
        // For now, we just clear the data
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          await _loadDatabaseStats();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo data has been reset'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset data: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Compact database (VACUUM)
  Future<void> _compactDatabase() async {
    final confirmed = await _showConfirmationDialog(
      'Compact Database',
      'This will optimize the database and reclaim unused space. Continue?',
    );

    if (confirmed == true && mounted) {
      try {
        _showLoadingDialog();
        
        final db = await _dbHelper.database;
        await db.execute('VACUUM');
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          await _loadDatabaseStats();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database compacted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to compact database: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Clear all assets
  Future<void> _clearAllAssets() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Assets',
      'This will delete all your assets and transactions but keep your account. This action cannot be undone. Continue?',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        _showLoadingDialog();
        
        final provider = Provider.of<PortfolioProvider>(context, listen: false);
        await provider.clearUserData();
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          await _loadDatabaseStats();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All assets cleared'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear assets: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Clear all data
  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Data',
      'This will permanently delete the entire database including all users, assets, and transactions. This action cannot be undone. Continue?',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        _showLoadingDialog();
        
        final provider = Provider.of<PortfolioProvider>(context, listen: false);
        
        // Delete the entire database
        await _dbHelper.deleteDatabase();
        
        // Logout the user
        await provider.logout();
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Logout
  Future<void> _logout() async {
    final confirmed = await _showConfirmationDialog(
      'Logout',
      'Are you sure you want to logout?',
    );

    if (confirmed == true && mounted) {
      try {
        final provider = Provider.of<PortfolioProvider>(context, listen: false);
        await provider.logout();
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmationDialog(
    String title,
    String message, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(currentRoute: '/settings'),
      body: _buildBody(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open menu',
        ),
      ),
      title: const Text('Settings'),
    );
  }

  /// Build body
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: _loadDatabaseStats,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Section
              if (provider.currentUser != null) ...[
                _buildAccountSection(provider),
                const SizedBox(height: 24),
              ],

              // Demo Mode Section
              _buildDemoModeSection(provider),
              const SizedBox(height: 24),

              // Appearance Section
              _buildAppearanceSection(),
              const SizedBox(height: 24),

              // Price Updates Section
              _buildPriceUpdatesSection(provider),
              const SizedBox(height: 24),

              // Database Section
              _buildDatabaseSection(),
              const SizedBox(height: 24),

              // Data Management Section
              _buildDataManagementSection(),
              const SizedBox(height: 24),

              // About Section
              _buildAboutSection(),
              const SizedBox(height: 24),

              // Danger Zone
              _buildDangerZone(provider),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Build account section
  Widget _buildAccountSection(PortfolioProvider provider) {
    final user = provider.currentUser!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User avatar and info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _getInitials(user.fullName),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // User details
                _buildInfoRow(Icons.email, 'Email', user.email),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Member since',
                  Formatters.formatDate(user.createdAt),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Last login',
                  Formatters.formatDateTime(user.lastLoginAt),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null, // Disabled for demo
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null, // Disabled for demo
                        icon: const Icon(Icons.lock),
                        label: const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build demo mode section
  Widget _buildDemoModeSection(PortfolioProvider provider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Demo Mode'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: null, // Always on for demo
                  title: const Text('Demo Mode Enabled'),
                  subtitle: const Text('Using SQLite database with demo data'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text(
                  '$_assetCount assets • $_transactionCount transactions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetDemoData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Demo Data'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build appearance section
  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (value) {
                  if (value != null) _saveThemeMode(value);
                },
                title: const Text('Light'),
                secondary: const Icon(Icons.light_mode),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (value) {
                  if (value != null) _saveThemeMode(value);
                },
                title: const Text('Dark'),
                secondary: const Icon(Icons.dark_mode),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (value) {
                  if (value != null) _saveThemeMode(value);
                },
                title: const Text('System'),
                secondary: const Icon(Icons.settings_suggest),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build price updates section
  Widget _buildPriceUpdatesSection(PortfolioProvider provider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Price Updates'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: _autoUpdateEnabled,
                  onChanged: _saveAutoUpdate,
                  title: const Text('Auto Update Prices'),
                  subtitle: Text(
                    provider.isPriceUpdatesActive ? 'Updates active' : 'Updates paused',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Frequency: ${_updateFrequency.toInt()}s',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: _updateFrequency,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_updateFrequency.toInt()}s',
                  onChanged: _saveUpdateFrequency,
                ),
                const SizedBox(height: 8),
                if (_lastUpdate != null)
                  Text(
                    'Last update: ${Formatters.formatTime(_lastUpdate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Prices are saved to database every 15 seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build database section
  Widget _buildDatabaseSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Database'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.storage,
                  'Database Size',
                  '${_databaseSize.toStringAsFixed(2)} MB',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.show_chart,
                  'Assets',
                  _assetCount.toString(),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.receipt_long,
                  'Transactions',
                  _transactionCount.toString(),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.folder,
                  'Path',
                  _databasePath,
                  isPath: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _compactDatabase,
                        icon: const Icon(Icons.compress),
                        label: const Text('Compact'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null, // Disabled for future
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build data management section
  Widget _buildDataManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Data Management'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Portfolio'),
                subtitle: const Text('Coming soon'),
                enabled: false,
                onTap: null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Import Data'),
                subtitle: const Text('Coming soon'),
                enabled: false,
                onTap: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build about section
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                trailing: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('View on GitHub'),
                enabled: false,
                onTap: null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Rate this app'),
                enabled: false,
                onTap: null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Share feedback'),
                enabled: false,
                onTap: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build danger zone
  Widget _buildDangerZone(PortfolioProvider provider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Danger Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _clearAllAssets,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All Assets'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: null, // Disabled for demo
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Delete Account'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _clearAllData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'These actions will permanently delete data from the SQLite database',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isPath = false}) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
                maxLines: isPath ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}