import 'package:flutter/material.dart';
import 'package:muslimdigest/models/more_apps.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

class MoreApps extends StatelessWidget {
  const MoreApps({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'More apps:',
          textAlign: TextAlign.center,
          style: h.currentTextTheme.titleSmall?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            children: MoreApp.values.map((app) => _AppTile(app: app).expand()).toList().addItemInBetween(SizedBox(width: 12)),
          ),
        ),
      ],
    );
  }
}

class _AppTile extends StatelessWidget {
  final MoreApp app;
  
  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      children: [
        Image.asset(app.image),
        SizedBox(height: 8),
        Text(
          app.title,
          textAlign: TextAlign.center,
          style: h.currentTextTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.15,
          ),
        ),
      ],
    ).onTap(() {
      openStoreListing(app.id);
    });
  }
}
