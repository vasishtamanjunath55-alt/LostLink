import 'package:flutter/material.dart';

import '../config.dart';
import '../models/item.dart';
import 'item_detail_screen.dart';

Widget _emptyState(String msg) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Center(child: Text(msg, textAlign: TextAlign.center)),
      ],
    );

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = item.isLost ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: item.photoUrl != null
                  ? Image.network(item.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                  : Container(
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isLost ? 'LOST' : 'FOUND',
                          style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!item.isOpen) ...[
                        const SizedBox(width: 6),
                        const Text('RECOVERED',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${item.category} • ${item.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(timeAgo(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Browse all open reports, with search and filters.
class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  List<Item> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _type = 'all';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('items')
          .select()
          .eq('status', 'open')
          .order('created_at', ascending: false);
      _items = (data as List)
          .map((e) => Item.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _error = 'Could not load items. Pull down to retry.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Item> get _filtered {
    final q = _query.toLowerCase();
    return _items.where((i) {
      if (_type != 'all' && i.type != _type) return false;
      if (_category != 'All' && i.category != _category) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _open(Item item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search items, places...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'lost', label: Text('Lost')),
              ButtonSegment(value: 'found', label: Text('Found')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final c in ['All', ...AppConfig.categories])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _error != null
                      ? _emptyState(_error!)
                      : list.isEmpty
                          ? _emptyState('No matching reports yet.')
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: list.length,
                              itemBuilder: (_, i) => ItemCard(
                                  item: list[i], onTap: () => _open(list[i])),
                            ),
                ),
        ),
      ],
    );
  }
}

/// The signed-in user's own reports (open and recovered).
class MyPostsTab extends StatefulWidget {
  const MyPostsTab({super.key});

  @override
  State<MyPostsTab> createState() => _MyPostsTabState();
}

class _MyPostsTabState extends State<MyPostsTab> {
  List<Item> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('items')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      _items = (data as List)
          .map((e) => Item.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _error = 'Could not load your posts. Pull down to retry.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(Item item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: _error != null
          ? _emptyState(_error!)
          : _items.isEmpty
              ? _emptyState("You haven't posted anything yet.\nTap 'Report item' to start.")
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 90),
                  itemCount: _items.length,
                  itemBuilder: (_, i) =>
                      ItemCard(item: _items[i], onTap: () => _open(_items[i])),
                ),
    );
  }
}
