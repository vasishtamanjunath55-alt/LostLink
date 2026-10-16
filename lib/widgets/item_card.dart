import 'package:flutter/material.dart';

import '../models/item.dart';
import '../theme.dart';
import 'brand.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final int index;
  const ItemCard(
      {super.key, required this.item, required this.onTap, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final Widget thumb = item.photoUrl != null
        ? Hero(
            tag: 'photo-${item.id}',
            child: Image.network(
              item.photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, prog) => prog == null
                  ? child
                  : Container(color: scheme.surfaceContainerHighest),
              errorBuilder: (_, __, ___) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined)),
            ),
          )
        : Container(
            color: scheme.primaryContainer,
            child: Icon(categoryIcon(item.category),
                size: 38, color: scheme.onPrimaryContainer),
          );

    return FadeInUp(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Material(
          color: scheme.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant.withAlpha(110)),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 108,
              child: Row(
                children: [
                  SizedBox(width: 108, height: 108, child: thumb),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            TypePill(isLost: item.isLost),
                            if (!item.isOpen) ...[
                              const SizedBox(width: 6),
                              Text('RECOVERED',
                                  style: text.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ]),
                          const SizedBox(height: 6),
                          Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.place_outlined,
                                size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                  item.location.isEmpty
                                      ? item.category
                                      : item.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(timeAgo(item.createdAt),
                              style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
