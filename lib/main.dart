  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:provider/provider.dart';

  // Database
  import 'database/database_helper.dart';

  // Models

  // Providers
  import 'providers/auth_provider.dart';
  import 'services/portfolio_provider.dart';
  import 'providers/theme_provider.dart';

  // Screens - Authentication
  import 'screens/auth/login_screen.dart';
  import 'screens/auth/register_screen.dart';
  import 'screens/auth/onboarding_screen.dart';

  // Screens - Main
  import 'screens/home_screen.dart';
  import 'screens/charts_screen.dart';
  import 'screens/transactions_screen.dart';
  import 'screens/settings_screen.dart';
  import 'screens/about_screen.dart';

  // Screens - Assets
  import 'screens/asset_detail_screen.dart';
  import 'screens/asset/add_asset_screen.dart';
  import 'screens/asset/edit_asset_screen.dart';

  // Screens - Transactions
  import 'screens/transaction/add_transaction_screen.dart';
  import 'screens/transaction/edit_transaction_screen.dart';

  // Theme
  import 'theme/app_theme.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize database
    DatabaseHelper.initializeDatabaseFactory();
    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    runApp(const PortfolioTrackerApp());
  }

  class PortfolioTrackerApp extends StatelessWidget {
    const PortfolioTrackerApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
          ChangeNotifierProxyProvider<AuthProvider, PortfolioProvider>(
            create: (_) => PortfolioProvider(),
            update: (context, authProvider, portfolioProvider) {
              // Sync user between providers when auth state changes
              if (portfolioProvider != null) {
                if (authProvider.isAuthenticated && 
                    authProvider.currentUser != null &&
                    portfolioProvider.currentUser?.id != authProvider.currentUser?.id) {
                  // Use Future.microtask to avoid calling during build
                  Future.microtask(() {
                    portfolioProvider.setUser(authProvider.currentUser!);
                  });
                } else if (!authProvider.isAuthenticated && portfolioProvider.currentUser != null) {
                  // User logged out - clear portfolio data
                  Future.microtask(() {
                    portfolioProvider.logout();
                  });
                }
              }
              return portfolioProvider!;
            },
          ),
        ],
        child: const AppInitializer(),
      );
    }
  }

  class AppInitializer extends StatefulWidget {
    const AppInitializer({super.key});

    @override
    State<AppInitializer> createState() => _AppInitializerState();
  }

  class _AppInitializerState extends State<AppInitializer> {
    bool _isInitialized = false;

    @override
    void initState() {
      super.initState();
      _initialize();
    }

    Future<void> _initialize() async {
      // Use addPostFrameCallback to ensure we're not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = context.read<AuthProvider>();
        final portfolioProvider = context.read<PortfolioProvider>();

        try {
          // Restore previous auth session
          await authProvider.checkSession();

          // If authenticated, load user into PortfolioProvider
          if (authProvider.isAuthenticated && authProvider.currentUser != null) {
            await portfolioProvider.setUser(authProvider.currentUser!);
          }
        } catch (e) {
          debugPrint('Initialization error: $e');
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      if (!_isInitialized) {
        // Splash screen
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.trending_up, size: 80, color: Colors.blue),
                  SizedBox(height: 24),
                  Text(
                    'Portfolio Tracker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      }

      return Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Portfolio Tracker',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (_) => const AuthInitializer(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const AuthGuard(child: HomeScreen()),
              '/charts': (_) => const AuthGuard(child: ChartsScreen()),
              '/transactions': (_) =>
                  const AuthGuard(child: TransactionsScreen()),
              '/settings': (_) => const AuthGuard(child: SettingsScreen()),
              '/about': (_) => const AuthGuard(child: AboutScreen()),
              '/add-asset': (_) => const AuthGuard(child: AddAssetScreen()),
              '/add-transaction': (_) =>
                  const AuthGuard(child: AddTransactionScreen()),
            },
            onGenerateRoute: (settings) {
              // Dynamic routes
              if (settings.name == '/asset-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AuthGuard(
                    child: AssetDetailScreen(assetId: args['assetId'] as int),
                  ),
                );
              }

              if (settings.name == '/edit-asset') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AuthGuard(
                    child: EditAssetScreen(assetId: args['assetId'] as int),
                  ),
                );
              }

              if (settings.name == '/edit-transaction') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AuthGuard(
                    child: EditTransactionScreen(
                      transactionId: args['transactionId'] as int,
                    ),
                  ),
                );
              }

              if (settings.name == '/onboarding') {
                final userId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => OnboardingScreen(userId: userId),
                );
              }

              return null;
            },
          );
        },
      );
    }
  }

  class AuthInitializer extends StatelessWidget {
    const AuthInitializer({super.key});

    @override
    Widget build(BuildContext context) {
      return Consumer<AuthProvider>(
        builder: (_, authProvider, __) {
          if (authProvider.isAuthenticated) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      );
    }
  }

  class AuthGuard extends StatelessWidget {
    final Widget child;

    const AuthGuard({super.key, required this.child});

    @override
    Widget build(BuildContext context) {
      return Consumer<AuthProvider>(
        builder: (_, authProvider, __) {
          if (authProvider.isAuthenticated) return child;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });

          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }
  }

  // Navigation helpers
  void navigateAfterLogout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void navigateAfterLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void navigateAfterRegistration(
    BuildContext context, {
    required int userId,
    bool showOnboarding = false,
  }) {
    if (showOnboarding) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (route) => false,
        arguments: userId,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }