import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

/// About screen displaying app information, features, and technology stack
/// 
/// This screen provides users with:
/// - App branding and version information
/// - Feature highlights
/// - Technology stack details
/// - SQLite database emphasis
/// 
/// Example usage:
/// ```dart
/// Navigator.pushNamed(context, '/about');
/// ```
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations for smooth entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text('About'),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        currentRoute: '/about',
        onNavigate: (route) {
          Navigator.of(context).pop(); // Close drawer
          if (route != '/about') {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon Section
                  _buildAppLogo(colorScheme),
                  const SizedBox(height: 32),

                  // Description Card
                  _buildDescriptionCard(theme),
                  const SizedBox(height: 24),

                  // Features List
                  _buildFeaturesSection(theme),
                  const SizedBox(height: 24),

                  // Technology Stack
                  _buildTechnologyStack(theme),
                  const SizedBox(height: 32),

                  // Footer
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app logo and branding section
  Widget _buildAppLogo(ColorScheme colorScheme) {
    return Column(
      children: [
        // Circular gradient icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.pie_chart_rounded,
            size: 64,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // App name
        Text(
          'Portfolio Tracker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),

        // Version number
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Builds the description card
  Widget _buildDescriptionCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Portfolio Tracker Demo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A beautiful Flutter app for tracking investment portfolios',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Built with Material 3 and modern best practices',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Using SQLite for local data persistence',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the features section
  Widget _buildFeaturesSection(ThemeData theme) {
    final features = [
      _FeatureItem(
        icon: Icons.trending_up,
        title: 'Real-time price updates',
      ),
      _FeatureItem(
        icon: Icons.category,
        title: 'Multiple asset types',
      ),
      _FeatureItem(
        icon: Icons.history,
        title: 'Transaction history',
      ),
      _FeatureItem(
        icon: Icons.bar_chart,
        title: 'Charts & analytics',
      ),
      _FeatureItem(
        icon: Icons.light_mode,
        title: 'Light & dark themes',
      ),
      _FeatureItem(
        icon: Icons.storage,
        title: 'SQLite local database',
      ),
      _FeatureItem(
        icon: Icons.save,
        title: 'Persistent data storage',
      ),
      _FeatureItem(
        icon: Icons.speed,
        title: 'Efficient queries and indexes',
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Features',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => _buildFeatureItem(theme, feature)),
          ],
        ),
      ),
    );
  }

  /// Builds a single feature item
  Widget _buildFeatureItem(ThemeData theme, _FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the technology stack section
  Widget _buildTechnologyStack(ThemeData theme) {
    final technologies = [
      _TechItem(
        name: 'Flutter',
        icon: Icons.phone_android,
        color: const Color(0xFF02569B),
      ),
      _TechItem(
        name: 'Provider',
        icon: Icons.sync_alt,
        color: const Color(0xFF4CAF50),
        subtitle: 'State Management',
      ),
      _TechItem(
        name: 'fl_chart',
        icon: Icons.show_chart,
        color: const Color(0xFFFF9800),
        subtitle: 'Charts',
      ),
      _TechItem(
        name: 'SQLite',
        icon: Icons.storage,
        color: const Color(0xFF003B57),
        subtitle: 'Database',
        isHighlighted: true,
      ),
      _TechItem(
        name: 'Material 3',
        icon: Icons.design_services,
        color: const Color(0xFF6200EA),
        subtitle: 'UI Design',
      ),
      _TechItem(
        name: 'Google Fonts',
        icon: Icons.font_download,
        color: const Color(0xFF4285F4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.code,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Built With',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: technologies
              .map((tech) => _buildTechnologyChip(theme, tech))
              .toList(),
        ),
      ],
    );
  }

  /// Builds a technology chip
  Widget _buildTechnologyChip(ThemeData theme, _TechItem tech) {
    final isHighlighted = tech.isHighlighted;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? tech.color.withOpacity(0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(
                color: tech.color,
                width: 2,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tech.icon,
            size: 20,
            color: isHighlighted ? tech.color : tech.color.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tech.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  color: isHighlighted ? tech.color : null,
                ),
              ),
              if (tech.subtitle != null)
                Text(
                  tech.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the footer section
  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        // Made with love
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Made with',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.favorite,
              size: 16,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              'using Flutter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Copyright
        Text(
          '© 2024 Portfolio Tracker',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 16),

        // Database note
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Data stored locally using SQLite',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Documentation links (disabled)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: null, // Disabled
              child: Text(
                'Documentation',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            Text(
              '•',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            TextButton(
              onPressed: null, // Disabled
              child: Text(
                'GitHub',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            Text(
              '•',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            TextButton(
              onPressed: null, // Disabled
              child: Text(
                'Support',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Internal data class for feature items
class _FeatureItem {
  final IconData icon;
  final String title;

  _FeatureItem({
    required this.icon,
    required this.title,
  });
}

/// Internal data class for technology items
class _TechItem {
  final String name;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isHighlighted;

  _TechItem({
    required this.name,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isHighlighted = false,
  });
}