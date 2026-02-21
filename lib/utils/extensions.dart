import 'dart:math';

import 'package:flutter/material.dart';

extension NumExtension on num {
  /// Function to determine min & max value
  num withLimit(num minimum, num maximum) => min(maximum, max(minimum, this));
}

extension ListExtension<T> on List<T> {
  List<T> addItemInBetween<A extends T>(A item) => isEmpty ? this : (fold([], (r, element) => [...r, element, item])..removeLast());
  T? firstWhereOrNull(bool Function(T) test) => where(test).firstOrNull;
  T? getRandom() => isEmpty ? null : length == 1 ? first : this[Random().nextInt(length)];
  List<T> reverse([bool enable = true]) => enable ? reversed.toList() : this;
}

extension IterableNumExtension on Iterable<num> {
  num get sum => fold(0, (p, c) => p + c);
  num get avg => length > 0 ? sum / length : 0;
}

extension StringExtension on String {
  /// Change the first letter to capital
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  /// Convert text to title case
  String toTitleCase() => trim().replaceAll(RegExp(r'\s+'), ' ').split(' ').map((str) => str.isEmpty ? '' : str.toCapitalized()).join(' ');
  /// Count the number of substrings in a string
  int occurrencesOf(String substring) => substring.allMatches(this).length;
  /// Convert slug to regular text (e.g. "high_risk" or "high-risk" to "high risk")
  String unslug() => replaceAll(RegExp(r'[_-]'), ' ');
  /// Convert slug to title case (e.g. "high_risk" or "high-risk" to "High Risk")
  String unslugTitleCase() => unslug().toTitleCase();
}

extension NullableStringExtension on String? {
  /// Check if string is empty or null
  bool get isEmptyOrNull => this?.isEmpty ?? true;
}

extension WidgetExtension on Widget {
  Widget fullWidth([bool enable = true]) => enable ? SizedBox(width: double.infinity, child: this) : this;
  Widget moveTo(Offset offset) => Transform.translate(offset: offset, child: this);
  Widget moveIt(double x, double y) => moveTo(Offset(x, y));
  Widget moveX(double x) => moveTo(Offset(x, 0));
  Widget moveY(double y) => moveTo(Offset(0, y));
  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);
  Widget left() => align(Alignment.centerLeft);
  Widget right() => align(Alignment.centerRight);
  Widget scale(double scale) => Transform.scale(scale: scale, child: this);
  Widget sized({double? width, double? height}) => SizedBox(width: width, height: height, child: this);
  Widget squared(double? size) => sized(width: size, height: size);
  Widget center() => Center(child: this);
  Widget clipRadius(double radius) => ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);
  Widget expand() => Expanded(child: this);
  Widget flexible() => Flexible(child: this);
  Widget hero(String tag) => Hero(tag: tag, child: this);
  Widget ignore([bool ignoring = true]) => IgnorePointer(ignoring: ignoring, child: this,);
  Widget invisible([bool hide = true]) => Visibility(
    visible: !hide,
    maintainSize: true,
    maintainState: true,
    maintainAnimation: true,
    child: this,
  );

  Widget withPadding({double horizontal = 0, double vertical = 0, double top = 0, double right = 0, double bottom = 0, double left = 0}) => Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical).copyWith(top: top == 0 ? vertical : top, right: right == 0 ? horizontal : right, bottom: bottom == 0 ? vertical : bottom, left: left == 0 ? horizontal : left), child: this);
  Widget withPaddingAll(double padding) => Padding(padding: EdgeInsets.all(padding), child: this);
  Widget withPaddingHorizontal(double padding) => Padding(padding: EdgeInsets.symmetric(horizontal: padding), child: this);
  Widget withPaddingVertical(double padding) => Padding(padding: EdgeInsets.symmetric(vertical: padding), child: this);

  /// Function for tap widget action with GestureDetector
  Widget onTap(VoidCallback? onTap) {
    return onTap != null ? GestureDetector(onTap: onTap, child: this) : this;
  }

  /// Function to change widget opacity
  Widget withOpacity([double opacity = 1.0]) => Opacity(opacity: opacity, child: this);

  /// Function for arrow animation on widget
  Widget arrowIt({bool arrow = true, int duration = 1000, double offset = 50.0}) {
    return arrow ? ArrowIt(duration: duration, offset: offset, child: this) : this;
  }

  /// Function for expand animation on widget
  Widget expandIt({bool show = true, int delay = 0, int duration = 500, double beginValue = 0.0, double endValue = 1.0, Alignment alignment = Alignment.centerLeft, Key? key}) {
    return ExpandIt(key: key, show: show, delay: delay, duration: duration, beginValue: beginValue, endValue: endValue, alignment: alignment, child: this);
  }

  /// Function for pulse animation on widget
  Widget pulseIt({bool pulse = true, double scaleBegin = 1.0, double scaleEnd = 1.2, int duration = 500}) {
    return pulse ? PulseIt(scaleBegin: scaleBegin, scaleEnd: scaleEnd, duration: duration, child: this) : this;
  }

  /// Function for rise animation on widget
  Widget riseIn({bool show = true, double offsetBegin = 30.0, int delay = 0, int duration = 200, Curve ease = Curves.easeInOutBack, Key? key}) {
    return RiseIn(show: show, offsetBegin: offsetBegin, delay: delay, duration: duration, ease: ease, key: key, child: this);
  }

  /// Function for fade animation on widget
  Widget fadeOut({bool hide = true, int duration = 500}) => AnimatedOpacity(
    opacity: hide ? 0 : 1,
    duration: Duration(milliseconds: duration),
    curve: Curves.linear,
    child: this,
  ).ignore(hide);

  /// Function for shader mask transparent gradient
  Widget maskIt({bool enable = true, Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter, List<double> opacities = const [1, 0],}) {
    return enable ? ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: begin,
          end: end,
          colors: opacities.map<Color>((o) => Colors.black.withValues(alpha: o)).toList(),
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
      },
      blendMode: BlendMode.dstIn,
      child: this,
    ) : this;
  }
}

class ArrowIt extends StatefulWidget {
  const ArrowIt({super.key, required this.child, this.float = true, this.duration = 1000, this.offset = 50.0});
  final Widget child;
  final bool float;
  final int duration;
  final double offset;

  @override
  ArrowItState createState() => ArrowItState();
}

class ArrowItState extends State<ArrowIt> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: widget.duration), vsync: this)..repeat(reverse: true);
    _animation = Tween(begin: -widget.offset, end: widget.offset).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.float ? AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(offset: Offset(_animation.value, 0), child: widget.child,),
    ) : widget.child;
  }
}

class ExpandIt extends StatefulWidget {
  const ExpandIt({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = 500,
    this.show = true,
    this.beginValue = 0.0,
    this.endValue = 1.0,
    this.onEnd,
    this.alignment = Alignment.centerLeft,
  });
  final Widget child;
  final bool show;
  final int delay;
  final int duration;
  final double beginValue;
  final double endValue;
  final VoidCallback? onEnd;
  final Alignment alignment;

  @override
  ExpandItState createState() => ExpandItState();
}

class ExpandItState extends State<ExpandIt> with SingleTickerProviderStateMixin {

  late final AnimationController _animationController;
  late final Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: widget.duration), vsync: this);
    _animation = Tween(begin: widget.beginValue, end: widget.endValue).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    if (widget.onEnd != null) {
      _animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onEnd!();
        }
      });
    }
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _animationController.forward();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ExpandIt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _animationController.forward();
      } else {
        _animationController.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(scaleX: _animation.value, alignment: widget.alignment, child: widget.child,),
    );
  }
}

class PulseIt extends StatefulWidget {
  const PulseIt({super.key, required this.child, this.pulse = true, this.scaleBegin = 1.0, this.scaleEnd = 1.2, this.duration = 500});
  final Widget child;
  final bool pulse;
  final double scaleBegin;
  final double scaleEnd;
  final int duration;

  @override
  PulseItState createState() => PulseItState();
}

class PulseItState extends State<PulseIt> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: widget.duration), vsync: this)..repeat(reverse: true);
    _animation = Tween(begin: widget.scaleBegin, end: widget.scaleEnd).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.pulse ? AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(scale: _animation.value, child: widget.child,),
    ) : widget.child;
  }
}

class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child, this.show = true, this.rise = true, this.offsetBegin = 30.0, this.delay = 0, this.duration = 200, this.ease = Curves.easeInOutBack});
  final Widget child;
  final bool show;
  final bool rise;
  final double offsetBegin;
  final int delay;
  final int duration;
  final Curve ease;

  @override
  RiseInState createState() => RiseInState();
}

class RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(duration: Duration(milliseconds: widget.duration), vsync: this);
  late final Animation<double> _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    parent: _animationController,
    curve: widget.ease,
  ));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (!mounted) return;
        _animationController.forward();
      });
    });
  }

  @override
  void didUpdateWidget(covariant RiseIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _animationController.forward();
      } else {
        _animationController.animateTo(0);
      }

    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.rise ? AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(offset: Offset(0, _animation.value * -widget.offsetBegin + widget.offsetBegin), child: Opacity(
          opacity: _animation.value.withLimit(0, 1.0).toDouble(),
          child: widget.child,
        ),);
      }
    ) : widget.child;
  }
}