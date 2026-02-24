import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';

class MyPlaceholder extends StatelessWidget {
  final String text;
  final String? footer;
  final Widget? icon;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final double? padding;
  const MyPlaceholder(this.text, {this.padding, this.footer, this.icon, this.onRetry, this.retryLabel, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?icon,
        Text(text, textAlign: TextAlign.center, style: h.currentTextTheme.bodyLarge),

        // Footer section
        if (footer != null) Text(
          footer!,
          textAlign: TextAlign.center,
          style: h.currentTextTheme.bodyMedium?.copyWith(
            color: h.currentTheme.hintColor,
          ),
        ),

        // Retry button
        if (onRetry != null) MyButton(
          text: retryLabel ?? 'Retry',
          onPressed: onRetry,
          icon: Icon(CupertinoIcons.refresh),
          width: 150,
        )
      ].addItemInBetween(SizedBox(height: 24,)),
    ).withPaddingAll(padding ?? AppThemes.contentPadding);
  }
}