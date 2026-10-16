import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/item.dart';
import '../services/matching.dart';
import '../theme.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'lost';
  String _category = AppConfig.categories.last;
  Uint8List? _photoBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phone.text =
        supabase.auth.currentUser?.userMetadata?['phone']?.toString() ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await ImagePicker()
          .pickImage(source: source, maxWidth: 1080, imageQuality: 70);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (_) {
      _snack('Could not open the camera/gallery.');
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _showMatches(List<Item> matches) async {
    final isLost = _type == 'lost';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Icon(Icons.auto_awesome,
                        color: Theme.of(ctx).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Possible matches',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                      isLost
                          ? 'Your report is posted. Someone may have already found this:'
                          : 'Your report is posted. Someone may be looking for this:',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                ),
                for (final m in matches)
                  ItemCard(
                    item: m,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: m)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = supabase.auth.currentUser!;
      String? photoUrl;
      if (_photoBytes != null) {
        final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('item-photos').uploadBinary(
              path,
              _photoBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        photoUrl = supabase.storage.from('item-photos').getPublicUrl(path);
      }
      final phone = _phone.text.trim();
      final row = await supabase
          .from('items')
          .insert({
            'user_id': user.id,
            'type': _type,
            'title': _title.text.trim(),
            'description': _desc.text.trim(),
            'category': _category,
            'location': _location.text.trim(),
            'photo_url': photoUrl,
            'contact_name':
                (user.userMetadata?['name'] ?? 'A student').toString(),
            'contact_phone': phone.isEmpty ? null : phone,
            'contact_email': user.email,
          })
          .select()
          .single();

      // Look for similar reports of the opposite type.
      try {
        final matches =
            await findMatches(Item.fromMap(Map<String, dynamic>.from(row)));
        if (matches.isNotEmpty && mounted) await _showMatches(matches);
      } catch (_) {}

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Could not post. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _photoPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _choosePhotoSource,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: _photoBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer.withAlpha(160)),
                    child: Icon(Icons.add_a_photo_outlined,
                        color: scheme.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text('Add a photo'),
                  Text('Photos help owners recognise their things',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                ],
              )
            : Stack(fit: StackFit.expand, children: [
                Image.memory(_photoBytes!, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _photoBytes = null),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _type == 'lost';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Report an item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: 'lost',
                    icon: Icon(Icons.search_off),
                    label: Text('I lost something')),
                ButtonSegment(
                    value: 'found',
                    icon: Icon(Icons.volunteer_activism),
                    label: Text('I found something')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            _photoPicker(context),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDeco(context,
                  label: 'Item name (e.g. Black wallet)',
                  icon: Icons.label_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an item name' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: fieldDeco(context,
                  label: 'Category', icon: categoryIcon(_category)),
              items: [
                for (final c in AppConfig.categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDeco(
                context,
                label:
                    isLost ? 'Where did you lose it?' : 'Where did you find it?',
                hint: 'e.g. Library 2nd floor, Canteen',
                icon: Icons.place_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a location' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDeco(context,
                  label: 'Description (colour, brand, marks...)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: fieldDeco(
                context,
                label: 'Contact phone (optional)',
                helper: 'Your email is shared too so people can reach you',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : const Text('Post report',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
