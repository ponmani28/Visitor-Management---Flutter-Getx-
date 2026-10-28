import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/visitor_card.dart';
import '../../../data/controllers/visitor_controller.dart';
import '../../../data/models/visitor_model.dart';
import '../../../routes/app_routes.dart';

class VisitorListView extends StatefulWidget {
  const VisitorListView({super.key});

  @override
  State<VisitorListView> createState() => _VisitorListViewState();
}

class _VisitorListViewState extends State<VisitorListView> {
  static const List<_StatusFilter> _filters = <_StatusFilter>[
    _StatusFilter(label: 'All'),
    _StatusFilter(label: 'Registered', status: VisitorStatus.registered),
    _StatusFilter(label: 'Checked In', status: VisitorStatus.checkedIn),
    _StatusFilter(label: 'Checked Out', status: VisitorStatus.checkedOut),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final VisitorController _controller;
  Worker? _queryWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<VisitorController>();
    _searchController.text = _controller.query.value;
    _queryWorker = ever(_controller.query, (value) {
      if (_searchController.text.trim().toLowerCase() == value) {
        return;
      }
      _searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });
    _controller.load();
  }

  @override
  void dispose() {
    _queryWorker?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.updateQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final provider = _controller;
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Visitors',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.hasFilters
                              ? '${provider.visibleVisitors.length} results found'
                              : '${provider.visitors.length} registered visitors',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => AppNavigator.openVisitorForm(context),
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CustomTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                label: 'Search visitors',
                hint: 'Search by name or mobile number',
                prefixIcon: Icons.search_rounded,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: provider.updateQuery,
                suffixIcon: provider.query.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = provider.statusFilter.value == filter.status;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    onSelected: (_) => provider.setStatusFilter(filter.status),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    side: BorderSide(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.75),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody(context, provider)),
          ],
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context, VisitorController provider) {
    final items = provider.visibleVisitors;

    if (provider.isLoading.value && provider.visitors.isEmpty) {
      return _RefreshableMessage(
        onRefresh: provider.refresh,
        child: const _LoadingState(),
      );
    }

    if (provider.errorMessage.value != null && provider.visitors.isEmpty) {
      return _RefreshableMessage(
        onRefresh: provider.refresh,
        child: EmptyStateView(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to load visitors',
          message: provider.errorMessage.value!,
          actionLabel: 'Try again',
          actionIcon: Icons.refresh_rounded,
          onAction: provider.refresh,
        ),
      );
    }

    if (items.isEmpty) {
      return _RefreshableMessage(
        onRefresh: provider.refresh,
        child: EmptyStateView(
          icon: provider.hasFilters
              ? Icons.filter_alt_off_rounded
              : Icons.people_outline_rounded,
          title: provider.hasFilters
              ? 'No matching visitors'
              : 'No visitors yet',
          message: provider.hasFilters
              ? 'Try a different name or mobile number, or clear the active filters.'
              : 'Register a visitor to start building the visitor log.',
          actionLabel: provider.hasFilters
              ? 'Clear filters'
              : 'Register visitor',
          actionIcon: provider.hasFilters
              ? Icons.filter_alt_off_rounded
              : Icons.add_rounded,
          onAction: () {
            if (provider.hasFilters) {
              _searchController.clear();
              provider.clearFilters();
            } else {
              AppNavigator.openVisitorForm(context);
            }
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final visitor = items[index];
          return VisitorCard(
            visitor: visitor,
            onTap: () => AppNavigator.openVisitorDetails(context, visitor),
          );
        },
      ),
    );
  }
}

class _StatusFilter {
  const _StatusFilter({required this.label, this.status});

  final String label;
  final VisitorStatus? status;
}

class _RefreshableMessage extends StatelessWidget {
  const _RefreshableMessage({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading visitors...',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
