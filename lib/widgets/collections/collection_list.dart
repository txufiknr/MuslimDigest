import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';

/// Reusable collection list widget
/// 
/// Can be used in both selection sheets and collections page
/// Supports tap actions and optional create button
class CollectionListWidget extends ConsumerWidget {
  final List<String> collections;
  final Function(String)? onTap;
  final Function(String)? onCreateCollection;
  final bool showCreateButton;
  final String? newCollectionName;
  final VoidCallback? onAllSavedTap;

  const CollectionListWidget({
    super.key,
    required this.collections,
    this.onTap,
    this.onCreateCollection,
    this.showCreateButton = false,
    this.newCollectionName,
    this.onAllSavedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always include "All Saved" as the first item
    final allItems = ['All Saved', ...collections];
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allItems.length + (showCreateButton ? 1 : 0),
      itemBuilder: (context, index) {
        // Create new collection button
        if (showCreateButton && index == allItems.length) {
          return _buildCreateCollectionButton();
        }

        final item = allItems[index];
        if (item == 'All Saved') {
          return _buildAllSavedItem(context);
        }
        
        return _buildCollectionItem(context, item);
      },
    );
  }

  Widget _buildCreateCollectionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MyButton(
        text: 'Create "${newCollectionName ?? 'New Collection'}"',
        icon: Icon(CupertinoIcons.add),
        variant: MyButtonVariant.primary,
        outlined: true,
        onPressed: onCreateCollection != null && newCollectionName != null
          ? () => onCreateCollection!(newCollectionName!)
          : null,
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    final h = MyHelper(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        // color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: h.currentTheme.colorScheme.outline
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          splashColor: AppColors.accent.withValues(alpha: .1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconBackgroundColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: h.currentTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            color: h.currentTheme.colorScheme.tertiary,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildCollectionItem(BuildContext context, String collection) {
    return _buildListItem(
      context: context,
      title: collection,
      icon: CupertinoIcons.folder,
      onTap: onTap != null ? () => onTap!(collection) : null,
    );
  }

  Widget _buildAllSavedItem(BuildContext context) {
    return _buildListItem(
      context: context,
      title: 'All Saved',
      icon: CupertinoIcons.bookmark,
      onTap: onAllSavedTap,
    );
  }
}
