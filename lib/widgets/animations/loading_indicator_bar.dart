import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../utils/helpers.dart';

class LoadingIndicatorBar extends StatefulWidget {
  final double height;
  final double? width;
  final Duration duration;
  final EdgeInsetsGeometry? margin;

  const LoadingIndicatorBar({
    super.key,
    this.height = 4.0,
    this.width,
    this.duration = const Duration(milliseconds: 1500),
    this.margin,
  });

  @override
  State<LoadingIndicatorBar> createState() => _LoadingIndicatorBarState();
}

class _LoadingIndicatorBarState extends State<LoadingIndicatorBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final width = widget.width ?? h.screenWidth;
    return Container(
      width: width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Center(
            child: Container(
              width: width * _expandAnimation.value,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.secondary,
                    AppColors.secondary,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
