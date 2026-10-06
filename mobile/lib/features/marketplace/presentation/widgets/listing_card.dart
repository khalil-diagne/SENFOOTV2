import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/marketplace/domain/listing_model.dart';
import 'package:efoot_market/shared/widgets/app_surface.dart';
import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (listing.teamStrength != null)
                PowerNumeral(value: listing.teamStrength!, size: 38)
              else
                Text('—', style: theme.textTheme.displaySmall?.copyWith(fontSize: 38)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(listing.platformLabel, style: theme.textTheme.labelSmall),
                        if (listing.seller?.avgRating != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '★ ${listing.seller!.avgRating!.toStringAsFixed(1)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatFcfa(listing.priceXof),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}