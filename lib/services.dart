import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';

SupabaseClient get supabase => Supabase.instance.client;

Future<List<Property>> fetchProperties({String? query, DealType? type}) async {
  var request = supabase.from('properties').select();
  if (type != null) {
    request = request.eq('type', type == DealType.rent ? 'rent' : 'sale');
  }
  final rows = await request.order('created_at', ascending: false);
  final normalized = query?.trim().toLowerCase();
  return (rows as List)
      .map((row) => Property.fromMap(Map<String, dynamic>.from(row as Map)))
      .where(
        (property) =>
            normalized == null ||
            normalized.isEmpty ||
            property.title.toLowerCase().contains(normalized) ||
            (property.city ?? '').toLowerCase().contains(normalized),
      )
      .toList();
}

Future<Property?> fetchProperty(String id) async {
  final row = await supabase
      .from('properties')
      .select()
      .eq('id', id)
      .maybeSingle();
  return row == null ? null : Property.fromMap(Map<String, dynamic>.from(row));
}

Future<Profile?> fetchProfile(String userId) async {
  final row = await supabase
      .from('profiles')
      .select('id, full_name, role')
      .eq('id', userId)
      .maybeSingle();
  return row == null ? null : Profile.fromMap(Map<String, dynamic>.from(row));
}

Future<({List<PropertyReaction> reactions, List<PropertyComment> comments})>
fetchInteractions(String propertyId) async {
  final results = await Future.wait([
    supabase.from('property_reactions').select().eq('property_id', propertyId),
    supabase
        .from('property_comments')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false),
  ]);
  return (
    reactions: (results[0] as List)
        .map(
          (row) =>
              PropertyReaction.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList(),
    comments: (results[1] as List)
        .map(
          (row) =>
              PropertyComment.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList(),
  );
}

Future<void> toggleReaction({
  required String propertyId,
  required ReactionType type,
  String? emoji,
}) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('سجّل الدخول أولاً لإضافة تفاعل.');
  final typeName = switch (type) {
    ReactionType.like => 'like',
    ReactionType.favorite => 'favorite',
    ReactionType.emoji => 'emoji',
  };
  final existing = await supabase
      .from('property_reactions')
      .select('id, emoji')
      .eq('property_id', propertyId)
      .eq('user_id', userId)
      .eq('reaction_type', typeName)
      .maybeSingle();
  if (existing != null &&
      type == ReactionType.emoji &&
      emoji != null &&
      existing['emoji'] != emoji) {
    await supabase
        .from('property_reactions')
        .update({'emoji': emoji})
        .eq('id', existing['id']);
  } else if (existing != null) {
    await supabase.from('property_reactions').delete().eq('id', existing['id']);
  } else {
    await supabase.from('property_reactions').insert({
      'property_id': propertyId,
      'user_id': userId,
      'reaction_type': typeName,
      'emoji': type == ReactionType.emoji ? (emoji ?? '👍') : null,
    });
  }
}

Future<void> addComment(String propertyId, String body) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('سجّل الدخول أولاً لإضافة تعليق.');
  final trimmed = body.trim();
  if (trimmed.isEmpty) return;
  await supabase.from('property_comments').insert({
    'property_id': propertyId,
    'user_id': userId,
    'body': trimmed,
  });
}

Future<String> saveProperty({
  String? id,
  required String title,
  required num price,
  String? city,
  num? area,
  int? rooms,
  required DealType type,
  String? description,
  String? contactPhone,
  required List<String> images,
  required bool sold,
}) async {
  final payload = <String, dynamic>{
    'title': title.trim(),
    'price': price,
    'city': city?.trim().isEmpty == true ? null : city?.trim(),
    'area': area,
    'rooms': rooms,
    'type': type == DealType.rent ? 'rent' : 'sale',
    'description': description?.trim().isEmpty == true
        ? null
        : description?.trim(),
    'contact_phone': contactPhone?.trim().isEmpty == true
        ? null
        : contactPhone?.trim(),
    'images': images,
    'sold': sold,
  };

  if (id != null) {
    await supabase.from('properties').update(payload).eq('id', id);
    return id;
  }

  final row = await supabase
      .from('properties')
      .insert(payload)
      .select('id')
      .single();
  return row['id'] as String;
}

Future<void> deleteProperty(String id) async {
  final row = await supabase
      .from('properties')
      .select('images')
      .eq('id', id)
      .maybeSingle();
  final images = List<String>.from(row?['images'] as List? ?? const []);
  await supabase.from('properties').delete().eq('id', id);
  await deletePropertyImages(images);
}

Future<void> updateSold(String id, bool sold) async {
  await supabase.from('properties').update({'sold': sold}).eq('id', id);
}

Future<List<String>> uploadPropertyImages(List<XFile> files) async {
  final urls = <String>[];
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final path =
        'properties/${DateTime.now().microsecondsSinceEpoch}-$safeName';
    await supabase.storage
        .from('property-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: 'image/$extension',
          ),
        );
    urls.add(supabase.storage.from('property-images').getPublicUrl(path));
  }
  return urls;
}

Future<void> deletePropertyImages(List<String> urls) async {
  final paths = <String>[];
  for (final url in urls) {
    final marker = '/storage/v1/object/public/property-images/';
    final index = url.indexOf(marker);
    if (index >= 0) {
      paths.add(Uri.decodeComponent(url.substring(index + marker.length)));
    }
  }
  if (paths.isNotEmpty) {
    await supabase.storage.from('property-images').remove(paths);
  }
}
