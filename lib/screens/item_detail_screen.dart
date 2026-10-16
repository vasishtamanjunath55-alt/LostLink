import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/item.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  bool get _isOwner => supabase.auth.currentUser?.id == item.userId;

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _snack(context, 'Could not open that app.');
    } catch (_) {
      if (context.mounted) _snack(context, 'Could not open that app.');
    }
  }

  Future<void> _markRecovered(BuildContext context) async {
    try {
      await supabase.from('items').update({'status': 'recovered'}).eq('id', item.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (_) {
      if (context.mounted) _snack(context, 'Could not update. Try again.');
    }
  }

  Future<void> _delete(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
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
      if (context.mounted) Navigator.pop(context, true);
    } catch (_) {
      if (context.mounted) _snack(context, 'Could not delete. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = item.contactPhone;
    final email = item.contactEmail;
    final badgeColor = item.isLost ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(title: Text(item.isLost ? 'Lost item' : 'Found item')),
      body: ListView(
        children: [
          if (item.photoUrl != null)
            Image.network(item.photoUrl!,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120, child: Center(child: Icon(Icons.broken_image)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, children: [
                  Chip(
                    label: Text(item.isLost ? 'LOST' : 'FOUND',
                        style: TextStyle(
                            color: badgeColor, fontWeight: FontWeight.bold)),
                  ),
                  Chip(label: Text(item.category)),
                  if (!item.isOpen) const Chip(label: Text('RECOVERED')),
                ]),
                const SizedBox(height: 8),
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (item.description.isNotEmpty) Text(item.description),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(item.location.isEmpty ? 'Not specified' : item.location),
                  subtitle: const Text('Location'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(timeAgo(item.createdAt)),
                  subtitle: const Text('Posted'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(item.contactName),
                  subtitle: const Text('Posted by'),
                ),
                const Divider(height: 32),
                if (!_isOwner && item.isOpen) ...[
                  Text('Contact ${item.contactName}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (phone != null && phone.isNotEmpty)
                      FilledButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                        onPressed: () =>
                            _launch(context, Uri(scheme: 'tel', path: phone)),
                      ),
                    if (phone != null && phone.isNotEmpty)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        onPressed: () {
                          var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
                          if (d.length == 10) d = '91$d'; // India country code
                          final text = Uri.encodeComponent(
                              'Hi, I saw your LostLink post: ${item.title}');
                          _launch(context,
                              Uri.parse('https://wa.me/$d?text=$text'));
                        },
                      ),
                    if (email != null && email.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Email'),
                        onPressed: () => _launch(
                          context,
                          Uri(
                            scheme: 'mailto',
                            path: email,
                            query:
                                'subject=${Uri.encodeComponent('LostLink: ${item.title}')}',
                          ),
                        ),
                      ),
                  ]),
                ],
                if (_isOwner) ...[
                  if (item.isOpen)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(item.isLost
                            ? 'Mark as recovered'
                            : 'Mark as returned to owner'),
                        onPressed: () => _markRecovered(context),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete report'),
                      onPressed: () => _delete(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
