import 'dart:developer' show log;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';
import 'package:muslimdigest/api/collections.dart';
import 'package:muslimdigest/widgets/collections/collection_list.dart';
import 'package:muslimdigest/widgets/collections/collection_search.dart';

/// Collections management page
/// 
/// Shows all user collections with search functionality
/// Navigates to filtered saved feeds when collection is tapped
class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _collections = [];
  List<String> _filteredCollections = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final collections = await CollectionApi.getCollections();
      setState(() {
        _collections = collections;
        _filteredCollections = collections;
      });
    } catch (e) {
      log('[CollectionsPage] Error loading collections: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _filteredCollections = _collections
          .where((collection) => collection.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToCollection(String collection) {
    context.push('/saved_feeds?collection=$collection');
  }

  void _navigateToAllSaved() {
    context.push('/saved_feeds');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MyAppBar(title: 'Saved Feeds'),
      body: SafeArea(
        child: Column(
          children: [
            // Search section
            CollectionSearchWidget(
              controller: _searchController,
              hintText: 'Search collections...',
            ).withPadding(
              horizontal: AppThemes.contentPadding,
              vertical: 8
            ),
            
            // Collections list
            Expanded(
              child: _isLoading 
                ? _buildLoadingState()
                : _filteredCollections.isEmpty && _searchQuery.isNotEmpty
                  ? _buildEmptyState()
                  : CollectionListWidget(
                      collections: _filteredCollections,
                      onTap: _navigateToCollection,
                      showCreateButton: _searchQuery.isNotEmpty && _filteredCollections.isEmpty,
                      onCreateCollection: _createCollection,
                      onAllSavedTap: _navigateToAllSaved,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return MyLoader().center();
  }

  Widget _buildEmptyState() {
    return MyPlaceholder(
      'No collections found for "$_searchQuery"',
      footer: 'Try a different search term',
      padding: 48,
      icon: Icon(
        CupertinoIcons.search,
        size: 64,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    ).center();
  }

  void _createCollection(String collectionName) {
    // Navigate to saved feeds with the new collection
    // The collection will be created implicitly when a feed is saved to it
    _navigateToCollection(collectionName);
  }
}
