import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/config/themes.dart';
// import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/helpers.dart';

/// Reusable search widget
/// 
/// Provides search functionality for collections, feeds, and other lists with proper styling
class CollectionSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;

  const CollectionSearchWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search collections...',
    this.onClear,
    this.onChanged,
  });

  @override
  State<CollectionSearchWidget> createState() => _CollectionSearchWidgetState();
}

class _CollectionSearchWidgetState extends State<CollectionSearchWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return TextField(
      controller: widget.controller,
      style: h.inputStyleLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: h.hintStyleLarge,
        prefixIcon: Icon(
          CupertinoIcons.search,
          color: h.currentTheme.colorScheme.tertiary,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                CupertinoIcons.clear_circled_solid,
                color: h.currentTheme.colorScheme.tertiary,
              ),
              onPressed: () {
                widget.controller.clear();
                widget.onClear?.call();
              },
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
          borderSide: BorderSide(
            color: h.currentTheme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
          borderSide: BorderSide(
            color: h.currentTheme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
          borderSide: BorderSide(
            color: h.currentTheme.colorScheme.primary,
            width: 2.0,
          ),
        ),
        // filled: true,
        // fillColor: h.currentTheme.colorScheme.surface,
      ),
    );
  }
}
