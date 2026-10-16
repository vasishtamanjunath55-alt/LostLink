import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/item.dart';
import '../services/matching.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/item_card.dart';
import 'photo_viewer.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Item get item => widget.item;
  late final Future<List<Item>> _matches;

  bool get _isOwner => supabase.auth.currentUser?.id == item.userId;

  @override
  void initState() {
    super.initState();
    _matches = (_isOwner && item.isOpen)
        ? findMatches(item).catchError((_) => <Item>[])
        : Future.value(<Item>[]);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _launch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('Could not open that app.');
    } catch (_) {
      _snack('Could not open that app.');
    }
  }

  Future<void> _markRecovered() async {
    try {
      await supabase
          .from('items')
          .update({'status': 'recovered'}).eq('id', item.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _snack('Could not update. Try again.');
    }
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await supabase.from('items').delete().eq('id', item.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _snack('Could not delete. Try again.');
    }
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (item.photoUrl == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
          ),
        ),
        child: Center(
          child: Icon(categoryIcon(item.category),
              size: 96, color: scheme.primary.withAlpha(180)),
        ),
      );
    }
    final tag = 'photo-${item.id}';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PhotoViewer(url: item.photoUrl!, heroTag: tag)),
      ),
      child: Stack(fit: StackFit.expand, children: [
        Hero(
          tag: tag,
          child: Image.network(
            item.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 48)),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.zoom_out_map, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('Tap to enlarge',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: scheme.primaryContainer.withAlpha(160),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phone = item.contactPhone;
    final email = item.contactEmail;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _header(context)),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      TypePill(isLost: item.isLost),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(categoryIcon(item.category), size: 13),
                          const SizedBox(width: 4),
                          Text(item.category,
                              style: text.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      if (!item.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('RECOVERED',
                              style: text.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onTertiaryContainer)),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    Text(item.title,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(item.description,
                          style: text.bodyMedium?.copyWith(height: 1.5)),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: scheme.outlineVariant.withAlpha(110)),
                      ),
                      child: Column(children: [
                        _infoRow(
                            Icons.place_outlined,
                            item.isLost ? 'Lost at' : 'Found at',
                            item.location.isEmpty
                                ? 'Not specified'
                                : item.location),
                        _infoRow(Icons.schedule, 'Posted',
                            timeAgo(item.createdAt)),
                        _infoRow(Icons.person_outline, 'Posted by',
                            item.contactName),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    if (!_isOwner && item.isOpen) ...[
                      Text('Get in touch',
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        if (phone != null && phone.isNotEmpty)
                          FilledButton.icon(
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            onPressed: () =>
                                _launch(Uri(scheme: 'tel', path: phone)),
                          ),
                        if (phone != null && phone.isNotEmpty)
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                            onPressed: () {
                              var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
                              if (d.length == 10) d = '91$d';
                              final msg = Uri.encodeComponent(
                                  'Hi, I saw your LostLink post: ${item.title}');
                              _launch(Uri.parse('https://wa.me/$d?text=$msg'));
                            },
                          ),
                        if (email != null && email.isNotEmpty)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Email'),
                            onPressed: () => _launch(Uri(
                              scheme: 'mailto',
                              path: email,
                              query:
                                  'subject=${Uri.encodeComponent('LostLink: ${item.title}')}',
                            )),
                          ),
                      ]),
                    ],
                    if (!_isOwner && !item.isOpen)
                      Text('This item has been marked as recovered.',
                          style: text.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    if (_isOwner) ...[
                      FutureBuilder<List<Item>>(
                        future: _matches,
                        builder: (context, snap) {
                          final list = snap.data ?? const <Item>[];
                          if (list.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.auto_awesome,
                                    size: 18, color: scheme.primary),
                                const SizedBox(width: 6),
                                Text('Possible matches',
                                    style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 2),
                              Text(
                                  item.isLost
                                      ? 'Someone reported finding something similar'
                                      : 'Someone reported losing something similar',
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              for (final m in list)
                                Transform.translate(
                                  offset: const Offset(-14, 0),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: ItemCard(
                                      item: m,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ItemDetailScreen(item: m)),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 14),
                            ],
                          );
                        },
                      ),
                      if (item.isOpen)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(item.isLost
                                ? 'Mark as recovered'
                                : 'Mark as returned to owner'),
                            onPressed: _markRecovered,
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete report'),
                          onPressed: _delete,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
