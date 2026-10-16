import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

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
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = supabase.auth.currentUser!;
      String? photoUrl;
      if (_photoBytes != null) {
        final path =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('item-photos').uploadBinary(
              path,
              _photoBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        photoUrl = supabase.storage.from('item-photos').getPublicUrl(path);
      }
      final phone = _phone.text.trim();
      await supabase.from('items').insert({
        'user_id': user.id,
        'type': _type,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'category': _category,
        'location': _location.text.trim(),
        'photo_url': photoUrl,
        'contact_name': (user.userMetadata?['name'] ?? 'A student').toString(),
        'contact_phone': phone.isEmpty ? null : phone,
        'contact_email': user.email,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Could not post. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _type == 'lost';
    return Scaffold(
      appBar: AppBar(title: const Text('Report an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            GestureDetector(
              onTap: _choosePhotoSource,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBytes == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40),
                            SizedBox(height: 6),
                            Text('Add a photo (recommended)'),
                          ],
                        ),
                      )
                    : Image.memory(_photoBytes!,
                        fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Item name (e.g. Black wallet)',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an item name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: [
                for (final c in AppConfig.categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(
                  labelText: isLost
                      ? 'Where did you lose it?'
                      : 'Where did you find it?',
                  hintText: 'e.g. Library 2nd floor, Canteen',
                  border: const OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a location' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Description (colour, brand, marks...)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Contact phone (optional)',
                  helperText: 'Your email is shared too so people can reach you',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post report'),
            ),
          ],
        ),
      ),
    );
  }
}
