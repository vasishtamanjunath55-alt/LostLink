class Item {
  final String id;
  final String userId;
  final String type; // 'lost' or 'found'
  final String title;
  final String description;
  final String category;
  final String location;
  final String status; // 'open' or 'recovered'
  final String? photoUrl;
  final String contactName;
  final String? contactPhone;
  final String? contactEmail;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.photoUrl,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.createdAt,
  });

  factory Item.fromMap(Map<String, dynamic> m) => Item(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        type: m['type'] as String,
        title: m['title'] as String,
        description: (m['description'] ?? '') as String,
        category: (m['category'] ?? 'Other') as String,
        location: (m['location'] ?? '') as String,
        status: (m['status'] ?? 'open') as String,
        photoUrl: m['photo_url'] as String?,
        contactName: (m['contact_name'] ?? 'Someone') as String,
        contactPhone: m['contact_phone'] as String?,
        contactEmail: m['contact_email'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );

  bool get isLost => type == 'lost';
  bool get isOpen => status == 'open';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${d.day}/${d.month}/${d.year}';
}
