import 'package:flutter/material.dart';

import '../tokens.dart';

/// Bloque gris animado que ocupa el lugar del contenido mientras carga.
class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
    super.key,
  });

  final double? width;
  final double height;
  final Radius radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(widget.radius),
          ),
        ),
      ),
    );
  }
}
