import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'property_editor_page.dart';
import 'services.dart';

const adminTeal = Color(0xff087f75);
const adminInk = Color(0xff173b37);
const adminBackground = Color(0xfff6f9f8);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Property> properties = const [];
  Profile? profile;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      profile = user == null ? null : await fetchProfile(user.id);
      properties = profile?.isAdmin == true
          ? await fetchProperties()
          : const [];
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit([Property? property]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PropertyEditorPage(property: property)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleSold(Property property) async {
    try {
      await updateSold(property.id, !property.sold);
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _remove(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العقار'),
        content: Text(
          'هل تريد حذف «${property.title}»؟ لا يمكن التراجع عن العملية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteProperty(property.id);
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final denied = !loading && profile?.isAdmin != true;
    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(
        backgroundColor: adminBackground,
        elevation: 0,
        title: const Text(
          'لوحة الإدارة',
          style: TextStyle(color: adminInk, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: adminTeal),
          ),
        ],
      ),
      floatingActionButton: !loading && !denied
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              backgroundColor: adminTeal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'إضافة عقار',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: adminTeal))
          : denied
          ? const _AdminState(
              title: 'غير مصرح',
              message: 'هذه الصفحة متاحة للأدمن فقط.',
            )
          : error != null
          ? _AdminState(
              title: 'تعذر تحميل العقارات',
              message: error!,
              action: TextButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _SummaryCard(count: properties.length),
                  const SizedBox(height: 14),
                  if (properties.isEmpty)
                    const _AdminState(
                      title: 'لا توجد عقارات',
                      message: 'ابدأ بإضافة أول عقار من زر الإضافة.',
                    ),
                  ...properties.map(
                    (p) => _AdminPropertyTile(
                      property: p,
                      onEdit: () => _edit(p),
                      onDelete: () => _remove(p),
                      onToggleSold: () => _toggleSold(p),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Card(
    color: adminTeal,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.apartment, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إجمالي العقارات',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdminPropertyTile extends StatelessWidget {
  const _AdminPropertyTile({
    required this.property,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleSold,
  });
  final Property property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleSold;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 82,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: property.images.isEmpty
                  ? const ColoredBox(
                      color: Color(0xffdcefea),
                      child: Icon(
                        Icons.home_work_outlined,
                        color: adminTeal,
                        size: 30,
                      ),
                    )
                  : Image.network(
                      property.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: adminTeal,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  property.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatPrice(property.price),
                  style: const TextStyle(
                    color: adminTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  property.sold
                      ? 'مباع / مؤجر'
                      : (property.type == DealType.rent ? 'إيجار' : 'بيع'),
                  style: TextStyle(
                    color: property.sold ? Colors.red : const Color(0xff71847f),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
              if (value == 'sold') onToggleSold();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(
                value: 'sold',
                child: Text(
                  property.sold ? 'إلغاء الحالة' : 'تحديد كمباع/مؤجر',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdminState extends StatelessWidget {
  const _AdminState({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: adminTeal,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: adminInk,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff71847f), height: 1.5),
          ),
          ?action,
        ],
      ),
    ),
  );
}
