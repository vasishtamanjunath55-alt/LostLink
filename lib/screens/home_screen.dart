import 'package:flutter/material.dart';

import '../config.dart';
import '../widgets/brand.dart';
import 'post_item_screen.dart';
import 'tabs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _tick = 0;

  Future<void> _post() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostItemScreen()),
    );
    if (posted == true) setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(children: [
          const BrandMark(size: 32),
          const SizedBox(width: 10),
          Text('LostLink',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _tab == 0
            ? BrowseTab(key: ValueKey('browse$_tick'))
            : MyPostsTab(key: ValueKey('mine$_tick')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _post,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Report item'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.manage_search),
              label: 'Browse'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'My posts'),
        ],
      ),
    );
  }
}
