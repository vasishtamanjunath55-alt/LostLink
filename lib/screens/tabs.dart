import 'package:flutter/material.dart';

import '../config.dart';
import '../models/item.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

Widget _scrollable(Widget child) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [const SizedBox(height: 50), Center(child: child)],
    );

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
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: TextField(
            decoration: fieldDeco(context,
                hint: 'Search items, places...', icon: Icons.search),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final c in ['All', ...AppConfig.categories])
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(categoryIcon(c), size: 18),
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        if (!_loading && _error == null && list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${list.length} open report${list.length == 1 ? '' : 's'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
        Expanded(
          child: _loading
              ? const SkeletonList()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _error != null
                      ? _scrollable(EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'No connection',
                          message: _error!))
                      : list.isEmpty
                          ? _scrollable(const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Nothing here yet',
                              message:
                                  'No reports match your filters. Try a different search, or post one yourself.'))
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: list.length,
                              itemBuilder: (_, i) => ItemCard(
                                  index: i,
                                  item: list[i],
                                  onTap: () => _open(list[i])),
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
    if (_loading) return const SkeletonList();
    return RefreshIndicator(
      onRefresh: _load,
      child: _error != null
          ? _scrollable(EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'No connection',
              message: _error!))
          : _items.isEmpty
              ? _scrollable(const EmptyState(
                  icon: Icons.add_a_photo_outlined,
                  title: 'No posts yet',
                  message:
                      "Lost something or found something? Tap 'Report item' to post it."))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 90),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => ItemCard(
                      index: i, item: _items[i], onTap: () => _open(_items[i])),
                ),
    );
  }
}
