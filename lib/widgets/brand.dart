import 'package:flutter/material.dart';

import '../theme.dart';

/// The LostLink logo mark (matches the app icon colours).
class BrandMark extends StatelessWidget {
  final double size;
  final bool inverted; // white tile with coloured icon (for gradient headers)
  const BrandMark({super.key, this.size = 36, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: inverted
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brand, AppColors.brandAlt],
              ),
        color: inverted ? Colors.white : null,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.travel_explore,
        color: inverted ? AppColors.brand : Colors.white,
        size: size * 0.58,
      ),
    );
  }
}

class TypePill extends StatelessWidget {
  final bool isLost;
  const TypePill({super.key, required this.isLost});

  @override
  Widget build(BuildContext context) {
    final color = isLost ? AppColors.lost : AppColors.found;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(isLost ? 'LOST' : 'FOUND',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6)),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer.withAlpha(140),
            ),
            child: Icon(icon, size: 56, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Fades and slides a child up when it first appears.
class FadeInUp extends StatelessWidget {
  final int index;
  final Widget child;
  const FadeInUp({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final ms = 280 + index.clamp(0, 8) * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Pulsing placeholder cards shown while loading.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          height: 108,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(150),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
