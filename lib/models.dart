enum DealType { sale, rent }

enum ReactionType { like, favorite, emoji }

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.price,
    required this.city,
    required this.area,
    required this.rooms,
    required this.type,
    required this.description,
    required this.images,
    required this.sold,
    required this.contactPhone,
    this.createdAt,
  });

  final String id;
  final String title;
  final num price;
  final String? city;
  final num? area;
  final int? rooms;
  final DealType type;
  final String? description;
  final List<String> images;
  final bool sold;
  final String? contactPhone;
  final DateTime? createdAt;

  factory Property.fromMap(Map<String, dynamic> map) => Property(
    id: map['id'] as String,
    title: map['title'] as String? ?? '',
    price: map['price'] as num? ?? 0,
    city: map['city'] as String?,
    area: map['area'] as num?,
    rooms: (map['rooms'] as num?)?.toInt(),
    type: map['type'] == 'rent' ? DealType.rent : DealType.sale,
    description: map['description'] as String?,
    images: List<String>.from(map['images'] as List? ?? const []),
    sold: map['sold'] as bool? ?? false,
    contactPhone: map['contact_phone'] as String?,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
  );
}

class PropertyReaction {
  const PropertyReaction({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.type,
    required this.emoji,
  });

  final String id;
  final String propertyId;
  final String userId;
  final ReactionType type;
  final String? emoji;

  factory PropertyReaction.fromMap(Map<String, dynamic> map) =>
      PropertyReaction(
        id: map['id'] as String,
        propertyId: map['property_id'] as String,
        userId: map['user_id'] as String,
        type: switch (map['reaction_type']) {
          'favorite' => ReactionType.favorite,
          'emoji' => ReactionType.emoji,
          _ => ReactionType.like,
        },
        emoji: map['emoji'] as String?,
      );
}

class PropertyComment {
  const PropertyComment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final String userId;
  final String body;
  final DateTime? createdAt;

  factory PropertyComment.fromMap(Map<String, dynamic> map) => PropertyComment(
    id: map['id'] as String,
    propertyId: map['property_id'] as String,
    userId: map['user_id'] as String,
    body: map['body'] as String? ?? '',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
  );
}

class Profile {
  const Profile({required this.id, required this.fullName, required this.role});

  final String id;
  final String? fullName;
  final String role;

  bool get isAdmin => role == 'admin';

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    fullName: map['full_name'] as String?,
    role: map['role'] as String? ?? 'user',
  );
}

String formatPrice(num price) => '${price.toStringAsFixed(0)} \$';
