import '../config.dart';
import '../models/item.dart';

const _stop = {
  'the', 'and', 'with', 'for', 'near', 'from', 'this', 'that', 'lost',
  'found', 'item', 'have', 'has', 'was', 'are', 'you', 'your', 'inside',
};

Set<String> _tokens(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.length >= 3 && !_stop.contains(w))
    .toSet();

/// Finds open reports of the opposite type (lost <-> found) in the same
/// category whose title, description or location overlap with [item].
Future<List<Item>> findMatches(Item item, {int limit = 3}) async {
  final otherType = item.isLost ? 'found' : 'lost';
  final data = await supabase
      .from('items')
      .select()
      .eq('status', 'open')
      .eq('type', otherType)
      .eq('category', item.category)
      .order('created_at', ascending: false)
      .limit(60);

  final mine = _tokens('${item.title} ${item.description}');
  final myLoc = _tokens(item.location);
  final scored = <MapEntry<Item, int>>[];

  for (final e in data as List) {
    final other = Item.fromMap(Map<String, dynamic>.from(e as Map));
    final titleHits = _tokens(other.title).intersection(mine).length;
    final descHits = _tokens(other.description).intersection(mine).length;
    final locHits = _tokens(other.location).intersection(myLoc).length;
    final score = titleHits * 3 + descHits + locHits * 2;
    if (score >= 3) scored.add(MapEntry(other, score));
  }
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(limit).map((e) => e.key).toList();
}
