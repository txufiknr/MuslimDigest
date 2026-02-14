import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';

class MyPlaceholder extends StatelessWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onRetry;
  final String? retryLabel;
  const MyPlaceholder(this.text, {this.icon, this.onRetry, this.retryLabel, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?icon,
        Text(
          text,
          style: h.currentTextTheme.bodyMedium,
        ),
        if (onRetry != null) MyButton(
          text: retryLabel ?? 'Retry',
          onPressed: onRetry,
          icon: Icon(CupertinoIcons.refresh),
          width: 150,
        )
      ].addItemInBetween(SizedBox(height: 24,)),
    );
  }
}