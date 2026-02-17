import 'package:flutter/material.dart';

class MySwitch extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const MySwitch({this.value, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value ?? false,
      onChanged: onChanged,
      inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }
}