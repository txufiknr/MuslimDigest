import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/divider.dart';

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

/// Shows a bottom modal sheet
Future<dynamic> showBottomModalSheet(BuildContext context, List<Widget> widgets, {bool isDismissible = true}) {
  final h = MyHelper(context);

  return showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: h.currentTheme.colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppThemes.modalRadius))),
    clipBehavior: Clip.antiAlias,
    useSafeArea: false,
    builder: (BuildContext context) {
      final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.all(AppThemes.contentPadding).copyWith(
          // bottom: h.viewInsetsBottom + AppThemes.contentPadding * 2,
          bottom: bottomPadding + AppThemes.contentPadding * 2,
        ),
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
            ...widgets
          ],
        ),
      );
    },
  );
}

Future<dynamic> showBottomModalSheetContent(BuildContext context, {required String title, List<Widget> widgets = const [], bool isDismissible = true}) {
  final h = MyHelper(context);

  return showBottomModalSheet(context, [
    Text(title, textAlign: TextAlign.left, style: h.currentTextTheme.titleLarge,).left(),
    MyDivider().withPaddingVertical(12),
    SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: widgets.length == 1 ? widgets.first : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
    ).fullWidth().flexible(),
  ], isDismissible: isDismissible);
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
/// showBottomModalSheetMessage(
///   context,
///   'Something went wrong',
///   buttons: [
///     ModalButtonConfig(
///       text: 'Retry',
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
Future<dynamic> showBottomModalSheetMessage(BuildContext context, String message, {
  List<ModalButtonConfig> buttons = const [],
  String? title,
  Widget? header,
  String? footer,
}) {
  final h = MyHelper(context);

  return showBottomModalSheet(
    context, [
      // Title section
      if (title != null) Text(
        title,
        textAlign: TextAlign.center,
        style: h.currentTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ).withPadding(bottom: 24),

      // Header section
      ?header?.withPadding(bottom: 16),

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
      if (buttons.isEmpty)
        const SizedBox(height: 12)
      else
        const SizedBox.shrink()
    ]
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
    Widget? header,
    String? footer,
    String? confirmButtonText,
    Widget? confirmButtonIcon,
    MyButtonVariant confirmButtonVariant = MyButtonVariant.primary,
    String? cancelButtonText,
    Widget? cancelButtonIcon,
  }
) async {
  return await showBottomModalSheetMessage(
    context,
    message,
    title: title,
    header: header,
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

void showSnackBar(BuildContext context, String message, {Widget? icon, List<Widget> buttons = const [], bool showAction = false, String? actionLabel, VoidCallback? action}) {
  final h = MyHelper(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      content: Row(
        children: [
          ?icon,
          Text(message, style: h.currentTextTheme.bodyMedium?.copyWith(
            color: h.currentTheme.colorScheme.onSurface,
          )).expand(),
          ...buttons
        ].addItemInBetween(SizedBox(width: 8)),
      ),
      shape: h.popupShape,
      elevation: 0,
      backgroundColor: h.currentTheme.colorScheme.surface,
      action: showAction
        ? SnackBarAction(
          label: actionLabel ?? "Close", 
          onPressed: action ?? () => hideSnackBar(context),
        )
        : null,
    ),
  );
}

void showSnackBarMessage(BuildContext context, String message, Widget icon) {
  showSnackBar(
    context,
    message,
    icon: icon,
    buttons: [
      TextButton(onPressed: () => hideSnackBar(context), child: Text('Done')),
    ],
  );
}

void showSnackBarSuccess(BuildContext context, String message) {
  showSnackBarMessage(
    context,
    message,
    Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.success),
  );
}

void showSnackBarWarning(BuildContext context, String message) {
  showSnackBarMessage(
    context,
    message,
    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.warning),
  );
}

void showSnackBarError(BuildContext context, String message) {
  showSnackBarMessage(
    context,
    message,
    Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.error),
  );
}

void hideSnackBar(BuildContext context) => ScaffoldMessenger.of(context).hideCurrentSnackBar();
