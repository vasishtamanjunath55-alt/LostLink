import 'package:flutter/material.dart';

import '../config.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('LostLink'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: _tab == 0
          ? BrowseTab(key: ValueKey('browse$_tick'))
          : MyPostsTab(key: ValueKey('mine$_tick')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _post,
        icon: const Icon(Icons.add),
        label: const Text('Report item'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'My posts'),
        ],
      ),
    );
  }
}
