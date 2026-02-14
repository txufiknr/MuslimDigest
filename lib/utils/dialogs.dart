import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';

/// Configuration class for modal buttons
class ModalButtonConfig {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final MyButtonVariant variant;
  final bool outlined;
  final Brightness brightness;
  
  const ModalButtonConfig({
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = MyButtonVariant.primary,
    this.outlined = false,
    this.brightness = Brightness.light,
  });
}

/// Shows a bottom modal sheet with customizable message and buttons
/// 
/// [message] - The message to display in the modal
/// [buttons] - List of button configurations for the modal
/// [context] - BuildContext for showing the modal
/// 
/// Returns a Future that completes when the modal is dismissed
/// 
/// Example:
/// ```
/// showBottomModalSheet(
///   context: context,
///   message: 'Something went wrong',
///   buttons: [
///     ModalButtonConfig(
///       text: 'Retry',
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
Future<void> showBottomModalSheet({
  required BuildContext context,
  required String message,
  required List<ModalButtonConfig> buttons,
  String? title,
  String? footer,
}) {
  final h = MyHelper(context);

  return showModalBottomSheet<void>(
    context: context,
    // backgroundColor: currentTheme.scaffoldBackgroundColor,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          // color: currentTheme.scaffoldBackgroundColor,
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle UI
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),

            // Title section
            if (title != null) Text(
              title,
              textAlign: TextAlign.center,
              style: h.currentTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).withPadding(bottom: 24),

            // Message section
            Text(
              message,
              textAlign: TextAlign.center,
              style: h.currentTextTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

            // Footer section
            if (footer != null) Text(
              footer,
              textAlign: TextAlign.center,
              style: h.currentTextTheme.bodySmall?.copyWith(
                color: h.currentTheme.hintColor,
              ),
            ).withPadding(top: 16),

            const SizedBox(height: 24),
            
            // Buttons section
            ...buttons.map((buttonConfig) => MyButton(
              text: buttonConfig.text,
              onPressed: buttonConfig.onPressed,
              icon: buttonConfig.icon,
              variant: buttonConfig.variant,
              outlined: buttonConfig.outlined,
              brightness: buttonConfig.brightness,
            ).withPadding(bottom: 12)),
            
            // Remove padding from last button
            if (buttons.isNotEmpty) 
              const SizedBox.shrink()
            else
              const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Shows a bottom modal dialog with confirm and cancel buttons.
/// Returns true if confirm is pressed, false if cancel is pressed.
/// 
/// [message] - The message to display in the modal
/// [confirmButtonText] - Text for the confirm button (default: 'Confirm')
/// [cancelButtonText] - Text for the cancel button (default: 'Cancel')
/// [confirmButtonIcon] - Icon for the confirm button
/// [cancelButtonIcon] - Icon for the cancel button
/// 
/// Returns true if confirm is pressed, false if cancel is pressed.
/// 
/// Example:
/// ```
/// final confirmed = await showBottomModalConfirm(
///   context,
///   message: 'Are you sure you want to delete this item?',
/// );
/// if (confirmed) {
///   // Perform delete action
/// }
/// ```
Future<bool?> showBottomModalConfirm(
  BuildContext context, {
    required String message,
    String? title,
    String? footer,
    String? confirmButtonText,
    Widget? confirmButtonIcon,
    MyButtonVariant confirmButtonVariant = MyButtonVariant.primary,
    String? cancelButtonText,
    Widget? cancelButtonIcon,
  }
) async {
  return await showBottomModalSheet(
    context: context,
    message: message,
    title: title,
    footer: footer,
    buttons: [
      ModalButtonConfig(
        text: cancelButtonText ?? 'Cancel',
        icon: cancelButtonIcon,
        onPressed: () {
          Navigator.of(context).pop(false); // Close modal with false
        },
        variant: MyButtonVariant.secondary,
        outlined: true,
      ),
      ModalButtonConfig(
        text: confirmButtonText ?? 'Confirm',
        icon: confirmButtonIcon,
        variant: confirmButtonVariant,
        onPressed: () {
          Navigator.of(context).pop(true); // Close modal with true
        },
      ),
    ],
  ) as bool?;
}

Future<bool> showRetryableError(BuildContext context, {String? title, String? message, String? footer, dynamic error}) async {
  final errorMessage = error == null ? null : 'Error: ${error.toString()}';
  final continueAnyway = await showBottomModalConfirm(
    context,
    title: title ?? 'Failed to load your data.',
    message: message ?? 'Please check your internet connection and try again.',
    footer: [footer, errorMessage].where((e) => e != null).join('\n'),
    confirmButtonText: 'Continue Anyway',
    cancelButtonText: 'Retry',
    cancelButtonIcon: Icon(CupertinoIcons.refresh),
  ) ?? true;
  return !continueAnyway;
}

void showSnackBar(BuildContext context, String message, {bool showAction = false, String? actionLabel, VoidCallback? action}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      // backgroundColor: currentTheme.colorScheme.surface,
      action: showAction ? SnackBarAction(label: actionLabel ?? "Close", onPressed: action ?? Navigator.of(context).pop) : null,
    ),
  );
}

void hideSnackBar(BuildContext context) => ScaffoldMessenger.of(context).hideCurrentSnackBar();
