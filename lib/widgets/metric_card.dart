import 'package:flutter/material.dart';

/// Metric card widget for displaying key portfolio metrics
///
/// A reusable card component that displays an icon, title, value,
/// and optional subtitle. Supports theming and fade-in animation.
///
/// Example usage:
/// ```dart
/// MetricCard(
///   title: 'Total Assets',
///   value: '12',
///   subtitle: '3 stocks, 9 crypto',
///   icon: Icons.pie_chart,
///   color: Colors.blue,
/// )
///
/// MetricCard(
///   title: 'Total Invested',
///   value: '\$45,000',
///   icon: Icons.account_balance_wallet,
///   color: Colors.green,
/// )
/// ```
class MetricCard extends StatefulWidget {
  /// Title text displayed at the top
  final String title;

  /// Main value displayed prominently
  final String value;

  /// Optional subtitle displayed at the bottom
  final String? subtitle;

  /// Icon to display
  final IconData icon;

  /// Color for the icon background
  final Color? color;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Animation delay (for staggered animations)
  final Duration delay;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.color ?? theme.colorScheme.primary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Card(
            elevation: 2,
            // FIX: Remove any implicit height constraint — let the card
            // size itself to fit its content naturally.
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // FIX: mainAxisSize.min so the Column wraps its children
                // tightly and does NOT stretch to fill an unbounded height.
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with colored background
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: cardColor, size: 24),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Value
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.value,
                      key: ValueKey(widget.value),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Subtitle (if provided)
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact metric card for smaller displays or dense layouts
///
/// Example usage:
/// ```dart
/// CompactMetricCard(
///   label: 'Stocks',
///   value: '5',
///   icon: Icons.show_chart,
///   color: Colors.blue,
/// )
/// ```
class CompactMetricCard extends StatelessWidget {
  /// Label text
  final String label;

  /// Value text
  final String value;

  /// Icon to display
  final IconData icon;

  /// Color for the icon and accent
  final Color? color;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  const CompactMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Metric row for displaying multiple metrics in a horizontal layout
///
/// Example usage:
/// ```dart
/// MetricRow(
///   metrics: [
///     MetricData(label: 'Assets', value: '12', icon: Icons.pie_chart),
///     MetricData(label: 'Invested', value: '\$45K', icon: Icons.wallet),
///     MetricData(label: 'Return', value: '+12%', icon: Icons.trending_up),
///   ],
/// )
/// ```
class MetricRow extends StatelessWidget {
  /// List of metrics to display
  final List<MetricData> metrics;

  /// Spacing between metrics
  final double spacing;

  const MetricRow({super.key, required this.metrics, this.spacing = 8});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: CompactMetricCard(
              label: metrics[i].label,
              value: metrics[i].value,
              icon: metrics[i].icon,
              color: metrics[i].color,
              onTap: metrics[i].onTap,
            ),
          ),
        ],
      ],
    );
  }
}

/// Data class for metric information
class MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const MetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });
}

// import 'package:flutter/material.dart';

// /// Metric card widget for displaying key portfolio metrics
// ///
// /// A reusable card component that displays an icon, title, value,
// /// and optional subtitle. Supports theming and fade-in animation.
// ///
// /// Example usage:
// /// ```dart
// /// MetricCard(
// ///   title: 'Total Assets',
// ///   value: '12',
// ///   subtitle: '3 stocks, 9 crypto',
// ///   icon: Icons.pie_chart,
// ///   color: Colors.blue,
// /// )
// ///
// /// MetricCard(
// ///   title: 'Total Invested',
// ///   value: '\$45,000',
// ///   icon: Icons.account_balance_wallet,
// ///   color: Colors.green,
// /// )
// /// ```
// class MetricCard extends StatefulWidget {
//   /// Title text displayed at the top
//   final String title;

//   /// Main value displayed prominently
//   final String value;

//   /// Optional subtitle displayed at the bottom
//   final String? subtitle;

//   /// Icon to display
//   final IconData icon;

//   /// Color for the icon background
//   final Color? color;

//   /// Callback when card is tapped
//   final VoidCallback? onTap;

//   /// Animation delay (for staggered animations)
//   final Duration delay;

//   const MetricCard({
//     super.key,
//     required this.title,
//     required this.value,
//     this.subtitle,
//     required this.icon,
//     this.color,
//     this.onTap,
//     this.delay = Duration.zero,
//   });

//   @override
//   State<MetricCard> createState() => _MetricCardState();
// }

// class _MetricCardState extends State<MetricCard>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

//     // Start animation after delay
//     Future.delayed(widget.delay, () {
//       if (mounted) {
//         _controller.forward();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cardColor = widget.color ?? theme.colorScheme.primary;

//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: SlideTransition(
//         position: _slideAnimation,
//         child: GestureDetector(
//           onTap: widget.onTap,
//           child: Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12), // FIXED: Changed from 20 to 12
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Icon with colored background
//                   Container(
//                     padding: const EdgeInsets.all(
//                       8,
//                     ), // FIXED: Changed from 12 to 8
//                     decoration: BoxDecoration(
//                       color: cardColor.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       widget.icon,
//                       color: cardColor,
//                       size: 24,
//                     ), // FIXED: Changed from 28 to 24
//                   ),
//                   const SizedBox(height: 12), // FIXED: Changed from 16 to 12
//                   // Title
//                   Text(
//                     widget.title,
//                     style: theme.textTheme.titleSmall?.copyWith(
//                       color: theme.colorScheme.onSurface.withOpacity(0.7),
//                       fontWeight: FontWeight.w500,
//                     ),
//                     maxLines: 1, // ADDED: Prevent title overflow
//                     overflow:
//                         TextOverflow.ellipsis, // ADDED: Handle long titles
//                   ),
//                   const SizedBox(height: 6), // FIXED: Changed from 8 to 6
//                   // Value
//                   AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 300),
//                     transitionBuilder: (child, animation) {
//                       return FadeTransition(
//                         opacity: animation,
//                         child: SlideTransition(
//                           position: Tween<Offset>(
//                             begin: const Offset(0, 0.2),
//                             end: Offset.zero,
//                           ).animate(animation),
//                           child: child,
//                         ),
//                       );
//                     },
//                     child: Text(
//                       widget.value,
//                       key: ValueKey(widget.value),
//                       style: theme.textTheme.headlineSmall?.copyWith(
//                         // FIXED: Changed from headlineMedium to headlineSmall
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                       maxLines: 1, // ADDED: Prevent value overflow
//                       overflow:
//                           TextOverflow.ellipsis, // ADDED: Handle long values
//                     ),
//                   ),

//                   // Subtitle (if provided)
//                   if (widget.subtitle != null) ...[
//                     const SizedBox(height: 6), // FIXED: Changed from 8 to 6
//                     Text(
//                       widget.subtitle!,
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Compact metric card for smaller displays or dense layouts
// ///
// /// Example usage:
// /// ```dart
// /// CompactMetricCard(
// ///   label: 'Stocks',
// ///   value: '5',
// ///   icon: Icons.show_chart,
// ///   color: Colors.blue,
// /// )
// /// ```
// class CompactMetricCard extends StatelessWidget {
//   /// Label text
//   final String label;

//   /// Value text
//   final String value;

//   /// Icon to display
//   final IconData icon;

//   /// Color for the icon and accent
//   final Color? color;

//   /// Callback when card is tapped
//   final VoidCallback? onTap;

//   const CompactMetricCard({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.icon,
//     this.color,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final accentColor = color ?? theme.colorScheme.primary;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: accentColor.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: accentColor, size: 20),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   value,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 Text(
//                   label,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurface.withOpacity(0.6),
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Metric row for displaying multiple metrics in a horizontal layout
// ///
// /// Example usage:
// /// ```dart
// /// MetricRow(
// ///   metrics: [
// ///     MetricData(label: 'Assets', value: '12', icon: Icons.pie_chart),
// ///     MetricData(label: 'Invested', value: '\$45K', icon: Icons.wallet),
// ///     MetricData(label: 'Return', value: '+12%', icon: Icons.trending_up),
// ///   ],
// /// )
// /// ```
// class MetricRow extends StatelessWidget {
//   /// List of metrics to display
//   final List<MetricData> metrics;

//   /// Spacing between metrics
//   final double spacing;

//   const MetricRow({super.key, required this.metrics, this.spacing = 8});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         for (int i = 0; i < metrics.length; i++) ...[
//           if (i > 0) SizedBox(width: spacing),
//           Expanded(
//             child: CompactMetricCard(
//               label: metrics[i].label,
//               value: metrics[i].value,
//               icon: metrics[i].icon,
//               color: metrics[i].color,
//               onTap: metrics[i].onTap,
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

// /// Data class for metric information
// class MetricData {
//   final String label;
//   final String value;
//   final IconData icon;
//   final Color? color;
//   final VoidCallback? onTap;

//   const MetricData({
//     required this.label,
//     required this.value,
//     required this.icon,
//     this.color,
//     this.onTap,
//   });
// }
