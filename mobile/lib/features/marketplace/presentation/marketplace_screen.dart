import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/features/marketplace/application/listings_controller.dart';
import 'package:efoot_market/features/marketplace/domain/listing_model.dart';
import 'package:efoot_market/features/marketplace/presentation/widgets/listing_card.dart';
import 'package:efoot_market/shared/widgets/empty_state.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _platforms = <String, String>{
  'ps4': 'PS4',
  'ps5': 'PS5',
  'xbox': 'Xbox',
  'mobile': 'Mobile',
  'pc': 'PC',
};

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyQuery() async {
    final q = _searchController.text.trim();
    final filters = ref.read(listingsControllerProvider).filters.copyWith(
          query: q,
          clearQuery: q.isEmpty,
        );
    await ref.read(listingsControllerProvider.notifier).applyFilters(filters);
  }

  Future<void> _selectPlatform(String? platform) async {
    final current = ref.read(listingsControllerProvider).filters;
    final filters = platform == null
        ? current.copyWith(clearPlatform: true)
        : current.copyWith(platform: platform);
    await ref.read(listingsControllerProvider.notifier).applyFilters(filters);
  }

  Future<void> _openFilters() async {
    final current = ref.read(listingsControllerProvider).filters;
    final result = await showModalBottomSheet<ListingFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(initial: current),
    );
    if (result != null) {
      await ref.read(listingsControllerProvider.notifier).applyFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marché'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune),
            tooltip: 'Filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un compte...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _applyQuery,
                ),
              ),
              onSubmitted: (_) => _applyQuery(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _PlatformChip(
                  label: 'Toutes',
                  selected: state.filters.platform == null,
                  onSelected: () => _selectPlatform(null),
                ),
                for (final entry in _platforms.entries)
                  _PlatformChip(
                    label: entry.value,
                    selected: state.filters.platform == entry.key,
                    onSelected: () => _selectPlatform(entry.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(listingsControllerProvider.notifier).refresh(),
              child: state.error != null && state.page == null
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: ErrorView(
                            message: state.error!,
                            onRetry: () =>
                                ref.read(listingsControllerProvider.notifier).refresh(),
                          ),
                        ),
                      ],
                    )
                  : _ListingGrid(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _ListingGrid extends StatelessWidget {
  const _ListingGrid({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = state.page?.items ?? const <Listing>[];
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          EmptyState(
            title: 'Aucune annonce pour le moment',
            subtitle: 'Revenez plus tard ou ajustez vos filtres.',
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900
            ? 3
            : width > 560
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 140,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final listing = items[index];
            return ListingCard(
              listing: listing,
              onTap: () => context.push('/listings/${listing.id}'),
            );
          },
        );
      },
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final ListingFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _platform = widget.initial.platform;
  late final TextEditingController _minController = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final TextEditingController _maxController = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );
  late final TextEditingController _powerController = TextEditingController(
    text: widget.initial.teamStrength?.toString() ?? '',
  );

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _powerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _platform,
            decoration: const InputDecoration(labelText: 'Plateforme'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Toutes')),
              for (final entry in _platforms.entries)
                DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _platform = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix min (FCFA)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix max (FCFA)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _powerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Puissance (ex. 3200)'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              final min = int.tryParse(_minController.text.trim());
              final max = int.tryParse(_maxController.text.trim());
              final power = int.tryParse(_powerController.text.trim());
              Navigator.pop(
                context,
                ListingFilters(
                  query: widget.initial.query,
                  platform: _platform,
                  minPrice: min,
                  maxPrice: max,
                  teamStrength: power,
                ),
              );
            },
            child: const Text('Appliquer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                widget.initial.copyWith(
                  clearPlatform: true,
                  clearPrices: true,
                  clearTeamStrength: true,
                ),
              );
            },
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }
}