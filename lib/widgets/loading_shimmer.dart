import 'package:flutter/material.dart';

/// Loading shimmer widget for displaying placeholder content
/// 
/// Provides animated shimmer effects for various loading states.
/// Supports different shapes and sizes for flexible use cases.
/// 
/// Example usage:
/// ```dart
/// // Basic shimmer
/// LoadingShimmer(
///   width: 200,
///   height: 20,
/// )
/// 
/// // Card shimmer
/// LoadingShimmer(
///   shape: ShimmerShape.card,
/// )
/// 
/// // Circle shimmer (for avatars)
/// LoadingShimmer(
///   shape: ShimmerShape.circle,
///   width: 50,
///   height: 50,
/// )
/// 
/// // List item shimmer
/// LoadingShimmer(
///   shape: ShimmerShape.listItem,
/// )
/// ```
class LoadingShimmer extends StatefulWidget {
  /// Width of the shimmer widget
  final double? width;

  /// Height of the shimmer widget
  final double? height;

  /// Shape of the shimmer
  final ShimmerShape shape;

  /// Border radius (only used for rectangle and card shapes)
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width,
    this.height,
    this.shape = ShimmerShape.rectangle,
    this.borderRadius = 8,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default dimensions based on shape
    double? width = widget.width;
    double? height = widget.height;

    switch (widget.shape) {
      case ShimmerShape.card:
        width ??= double.infinity;
        height ??= 120;
        break;
      case ShimmerShape.listItem:
        width ??= double.infinity;
        height ??= 72;
        break;
      case ShimmerShape.circle:
        width ??= 40;
        height ??= 40;
        break;
      case ShimmerShape.rectangle:
        width ??= 100;
        height ??= 20;
        break;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: widget.shape == ShimmerShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.shape == ShimmerShape.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
              stops: [
                _animation.value - 0.5,
                _animation.value,
                _animation.value + 0.5,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Shape options for shimmer loading
enum ShimmerShape {
  /// Rectangular shape
  rectangle,

  /// Card shape (larger rectangle)
  card,

  /// List item shape (full width rectangle)
  listItem,

  /// Circle shape (for avatars)
  circle,
}

/// Shimmer loading placeholder for portfolio header
/// 
/// Example usage:
/// ```dart
/// ShimmerPortfolioHeader()
/// ```
class ShimmerPortfolioHeader extends StatelessWidget {
  const ShimmerPortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingShimmer(width: 120, height: 16),
          SizedBox(height: 8),
          LoadingShimmer(width: 200, height: 36),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingShimmer(height: 60)),
              SizedBox(width: 16),
              Expanded(child: LoadingShimmer(height: 60)),
            ],
          ),
          SizedBox(height: 12),
          LoadingShimmer(width: 150, height: 14),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for asset card
/// 
/// Example usage:
/// ```dart
/// ShimmerAssetCard()
/// ```
class ShimmerAssetCard extends StatelessWidget {
  const ShimmerAssetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  LoadingShimmer(width: 80, height: 24),
                  SizedBox(height: 4),
                  LoadingShimmer(width: 120, height: 14),
                  SizedBox(height: 8),
                  LoadingShimmer(width: 100, height: 12),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                LoadingShimmer(width: 100, height: 20),
                SizedBox(height: 4),
                LoadingShimmer(width: 70, height: 14),
                SizedBox(height: 8),
                LoadingShimmer(width: 90, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for transaction item
/// 
/// Example usage:
/// ```dart
/// ShimmerTransactionItem()
/// ```
class ShimmerTransactionItem extends StatelessWidget {
  const ShimmerTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const LoadingShimmer(
            width: 60,
            height: 28,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LoadingShimmer(width: 100, height: 18),
                SizedBox(height: 6),
                LoadingShimmer(width: 150, height: 14),
                SizedBox(height: 4),
                LoadingShimmer(width: 120, height: 12),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              LoadingShimmer(width: 80, height: 18),
              SizedBox(height: 4),
              LoadingShimmer(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for metric card
/// 
/// Example usage:
/// ```dart
/// ShimmerMetricCard()
/// ```
class ShimmerMetricCard extends StatelessWidget {
  const ShimmerMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            LoadingShimmer(
              shape: ShimmerShape.circle,
              width: 48,
              height: 48,
            ),
            SizedBox(height: 16),
            LoadingShimmer(width: 100, height: 14),
            SizedBox(height: 8),
            LoadingShimmer(width: 140, height: 28),
            SizedBox(height: 8),
            LoadingShimmer(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}

/// List of shimmer loading placeholders
/// 
/// Example usage:
/// ```dart
/// ShimmerList(
///   itemCount: 5,
///   itemBuilder: (context, index) => ShimmerAssetCard(),
/// )
/// ```
class ShimmerList extends StatelessWidget {
  /// Number of shimmer items to display
  final int itemCount;

  /// Builder for individual shimmer items
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Spacing between items
  final double spacing;

  const ShimmerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: itemBuilder,
    );
  }
}

/// Grid of shimmer loading placeholders
/// 
/// Example usage:
/// ```dart
/// ShimmerGrid(
///   itemCount: 6,
///   crossAxisCount: 2,
///   itemBuilder: (context, index) => ShimmerMetricCard(),
/// )
/// ```
class ShimmerGrid extends StatelessWidget {
  /// Number of shimmer items to display
  final int itemCount;

  /// Number of columns
  final int crossAxisCount;

  /// Builder for individual shimmer items
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Spacing between items
  final double spacing;

  const ShimmerGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.2,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}