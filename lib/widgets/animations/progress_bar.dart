import 'package:flutter/material.dart';
import '../../config/colors.dart';

/// Animated progress bar widget with smooth fill animations
/// 
/// This widget displays a horizontal progress bar that animates
/// smoothly when the progress value changes. Uses AnimatedContainer
/// for simple and efficient fill animations with customizable colors and height.
class AnimatedProgressBar extends StatefulWidget {
  /// Current progress value (0.0 to 1.0)
  final double progress;
  
  /// Height of the progress bar
  final double height;
  
  /// Background color of the progress bar track
  final Color backgroundColor;
  
  /// Color of the progress fill
  final Color progressColor;
  
  /// Border radius of the progress bar
  final double radius;
  
  /// Duration of the fill animation
  final Duration animationDuration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 4.0,
    this.backgroundColor = AppColors.surfaceLight,
    this.progressColor = AppColors.primary,
    this.radius = 2.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  late final _borderRadius = BorderRadius.circular(widget.radius);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Container(
          alignment: Alignment.centerLeft,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: _borderRadius,
          ),
          child: ClipRRect(
            borderRadius: _borderRadius,
            child: AnimatedContainer(
              width: width * widget.progress.clamp(0.0, 1.0),
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: widget.progressColor,
                borderRadius: _borderRadius,
              ),
            ),
          ),
        );
      }
    );
  }
}