import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/api/collections.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';

/// Collection selection bottom sheet for saving feeds to collections
class CollectionSelectionSheet extends ConsumerStatefulWidget {
  final FeedItem feedItem;
  final Function(String)? onCollectionSelected;
  final Function()? onUnsave;
  final bool isSaved;
  final String? currentCollection;

  const CollectionSelectionSheet({
    super.key,
    required this.feedItem,
    this.onCollectionSelected,
    this.onUnsave,
    this.isSaved = false,
    this.currentCollection,
  });

  @override
  ConsumerState<CollectionSelectionSheet> createState() => _CollectionSelectionSheetState();
}

class _CollectionSelectionSheetState extends ConsumerState<CollectionSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<String> _recentCollections = [];
  List<String> _filteredCollections = [];
  bool _isLoading = false;
  bool _showCreateButton = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentCollections();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _updateFilteredCollections();
      _updateCreateButtonVisibility();
    });
  }

  void _updateFilteredCollections() {
    if (_searchQuery.isEmpty) {
      _filteredCollections = _recentCollections;
    } else {
      _filteredCollections = _recentCollections
          .where((collection) => collection.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _updateCreateButtonVisibility() {
    // Show create button if search query doesn't match any existing collection
    _showCreateButton = _searchQuery.isNotEmpty && _filteredCollections.isEmpty;
  }

  void _addCollection() {
    _searchController.text = 'My First Collection 🌼';
    _searchFocusNode.requestFocus();
  }

  Future<void> _loadRecentCollections() async {
    setState(() => _isLoading = true);
    try {
      final collections = await CollectionApi.getCollections();
      _recentCollections = collections;
      _filteredCollections = _recentCollections;
    } catch (e) {
      // Handle error silently for now
      log('[CollectionSelectionSheet] Error loading collections: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectCollection(String collection) {
    widget.onCollectionSelected?.call(collection);
    Navigator.pop(context);
  }

  void _createNewCollection() async {
    if (_searchQuery.isEmpty) return;
    _selectCollection(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppThemes.contentPadding).copyWith(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppThemes.contentPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ).center(),

          // Header
          Text(
            'Save to Collection',
            style: h.currentTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          // Search input
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: h.inputStyle,
            decoration: InputDecoration(
              hintText: 'Search or create new collection...',
              hintStyle: h.hintStyle,
              prefixIcon: Icon(CupertinoIcons.search, size: 20, color: h.currentTheme.colorScheme.tertiary,),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: h.currentTheme.colorScheme.outline),
                borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            readOnly: _isLoading,
            enableInteractiveSelection: !_isLoading,
            enabled: !_isLoading,
          ),

          // Content area
          SingleChildScrollView(
            child: _buildListContent(h),
          ).flexible(),

          // Action buttons
          if (_showCreateButton) MyButton(
            text: 'Create Collection',
            onPressed: _createNewCollection,
            icon: Icon(CupertinoIcons.check_mark_circled),
            variant: MyButtonVariant.success,
            isLoading: _isLoading,
          ),

          // Show Unsave button if feed is already saved
          if (widget.isSaved && !_showCreateButton) MyButton(
            text: 'Unsave',
            onPressed: () async {
              // Check if widget is still mounted before calling callback
              if (!mounted) return;
              
              widget.onUnsave?.call();
              
              // Check again before navigation
              if (mounted) {
                Navigator.pop(context);
              }
            },
            icon: Icon(CupertinoIcons.bookmark_fill),
            variant: MyButtonVariant.error,
            isLoading: _isLoading,
          ),

          MyButton(
            text: _showCreateButton ? 'Cancel' : 'Close',
            outlined: true,
            onPressed: Navigator.of(context).pop,
          ).withPadding(bottom: 12),
        ].addItemInBetween(SizedBox(height: 16,)),
      ),
    );
  }

  Widget _buildListContent(MyHelper h) {
    if (_showCreateButton) return _buildCreateCollectionSection(h);
    if (_isLoading) return MyLoader().center();
    if (_filteredCollections.isEmpty) return _buildEmptyState(h);
    return _buildCollectionsList(h);
  }

  Widget _buildCreateCollectionSection(MyHelper h) {
    return SizedBox.shrink();
  }

  Widget _buildEmptyState(MyHelper h) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MyPlaceholder(
          'Create your first collection now',
          footer: 'Manage your saved feeds better with collections',
          padding: 48,
          icon: Icon(
            CupertinoIcons.folder,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        MyButton(text: "Add collection", icon: Icon(CupertinoIcons.add), variant: MyButtonVariant.success, onPressed: _addCollection,),
      ],
    );
  }

  Widget _buildCollectionsList(MyHelper h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchQuery.isEmpty) ...[
          Text(
            'Recent Collections',
            style: h.currentTextTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ..._filteredCollections.map((collection) => _buildCollectionItem(h, collection)),
      ],
    );
  }

  Widget _buildCollectionItem(MyHelper h, String collection) {
    final isCurrentCollection = widget.isSaved && collection == widget.currentCollection;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCollection(collection),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isCurrentCollection ? Border.all(
              color: h.currentTheme.colorScheme.primary,
              width: 2,
            ) : null,
            color: isCurrentCollection ? h.currentTheme.colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrentCollection 
                    ? h.currentTheme.colorScheme.primary
                    : h.currentTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isCurrentCollection ? CupertinoIcons.check_mark_circled : CupertinoIcons.folder,
                  size: 16,
                  color: isCurrentCollection 
                    ? h.currentTheme.colorScheme.onPrimary
                    : h.currentTheme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                collection,
                style: h.currentTextTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrentCollection ? FontWeight.w600 : FontWeight.w500,
                  color: isCurrentCollection ? h.currentTheme.colorScheme.primary : null,
                ),
              ).expand(),
              Icon(
                isCurrentCollection ? CupertinoIcons.check_mark : CupertinoIcons.chevron_right,
                size: 16,
                color: isCurrentCollection 
                  ? h.currentTheme.colorScheme.primary 
                  : h.currentTheme.colorScheme.tertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
