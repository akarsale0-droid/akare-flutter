import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'services.dart';
import 'admin_page.dart';

const teal = Color(0xff087f75);
const ink = Color(0xff173b37);
const background = Color(0xfff6f9f8);
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(const AqaratApp());
}

class AqaratApp extends StatelessWidget {
  const AqaratApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'العقارات',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      fontFamily: 'Arial',
    ),
    builder: (context, child) =>
        Directionality(textDirection: .rtl, child: child ?? const SizedBox()),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();
  String? filter;
  List<Property> properties = const [];
  Profile? profile;
  bool loading = false;
  String error = '';

  bool get configured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (configured) {
      _loadProfile();
      _load();
    }
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      profile = await fetchProfile(user.id);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      properties = await fetchProperties(
        query: search.text,
        type: filter == null
            ? null
            : (filter == 'rent' ? DealType.rent : DealType.sale),
      );
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: background,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'اكتشف منزلك القادم',
            style: TextStyle(fontSize: 12, color: Color(0xff758a85)),
          ),
          Text(
            'العقارات',
            style: TextStyle(fontWeight: FontWeight.w800, color: ink),
          ),
        ],
      ),
      actions: [
        if (profile?.isAdmin == true)
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPage()),
              );
              _load();
            },
            icon: const Icon(Icons.admin_panel_settings_outlined, color: teal),
          ),
        if (configured && supabase.auth.currentSession != null)
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
              setState(() => profile = null);
            },
            icon: const Icon(Icons.logout, color: teal),
          )
        else
          IconButton(
            onPressed: _openAuth,
            icon: const Icon(Icons.login, color: teal),
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث بالعنوان أو المدينة',
              prefixIcon: const Icon(Icons.search, color: teal),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        search.clear();
                        _load();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xffe3ece9)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [('الكل', null), ('بيع', 'sale'), ('إيجار', 'rent')]
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(item.$1),
                        selected: filter == item.$2,
                        onSelected: (_) {
                          setState(() => filter = item.$2);
                          _load();
                        },
                        selectedColor: teal,
                        labelStyle: TextStyle(
                          color: filter == item.$2 ? Colors.white : teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          if (!configured)
            const _StateBox(
              title: 'ربط Supabase مؤجل',
              message: 'مرّر SUPABASE_URL وSUPABASE_ANON_KEY عند التشغيل لعرض العقارات الحقيقية.',
            ),
          if (configured && loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(color: teal),
              ),
            ),
          if (configured && !loading && error.isNotEmpty)
            _StateBox(
              title: 'تعذّر تحميل العقارات',
              message: error,
              action: TextButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ),
          if (configured && !loading && error.isEmpty && properties.isEmpty)
            const _StateBox(
              title: 'لا توجد عروض حالياً',
              message: 'جرّب تغيير كلمات البحث أو نوع العرض.',
            ),
          if (configured && !loading && error.isEmpty)
            ...properties.map(
              (property) => PropertyCard(
                property: property,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyPage(property: property),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({required this.property, required this.onTap, super.key});
  final Property property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xffe5eeeb)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: property.images.isEmpty
                    ? Container(
                        color: const Color(0xffdcefea),
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: teal,
                          size: 34,
                        ),
                      )
                    : Image.network(
                        property.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: teal,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatPrice(property.price),
                    style: const TextStyle(
                      fontSize: 15,
                      color: teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${property.city ?? 'غير محدد'} • ${property.type == DealType.rent ? 'إيجار' : 'بيع'}',
                    style: const TextStyle(
                      color: Color(0xff71847f),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PropertyPage extends StatefulWidget {
  const PropertyPage({required this.property, super.key});
  final Property property;
  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  ({List<PropertyReaction> reactions, List<PropertyComment> comments})? data;
  final comment = TextEditingController();
  String? message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      data = await fetchInteractions(widget.property.id);
      if (mounted) setState(() {});
    } catch (e) {
      message = e.toString();
      if (mounted) setState(() {});
    }
  }

  Future<void> _react(ReactionType type, [String? emoji]) async {
    try {
      await toggleReaction(
        propertyId: widget.property.id,
        type: type,
        emoji: emoji,
      );
      _load();
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final comments = data?.comments ?? const <PropertyComment>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العقار'),
        backgroundColor: background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (p.images.isNotEmpty)
            SizedBox(
              height: 230,
              child: PageView(
                children: p.images
                    .map(
                      (url) => ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xffdcefea),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                color: teal,
                size: 70,
              ),
            ),
          const SizedBox(height: 18),
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPrice(p.price),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: teal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.description ?? 'لا يوجد وصف.',
            style: const TextStyle(height: 1.7, color: Color(0xff526864)),
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _react(ReactionType.like),
                icon: const Icon(Icons.thumb_up_alt_outlined),
                label: Text(
                  'إعجاب ${data?.reactions.where((r) => r.type == ReactionType.like).length ?? 0}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _react(ReactionType.favorite),
                icon: const Icon(Icons.favorite_border),
                label: const Text('مفضلة'),
              ),
              ...['👍', '❤️', '😂', '😮'].map(
                (emoji) => IconButton(
                  onPressed: () => _react(ReactionType.emoji, emoji),
                  icon: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'التعليقات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: comment,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقاً',
              suffixIcon: IconButton(
                onPressed: () async {
                  await addComment(p.id, comment.text);
                  comment.clear();
                  _load();
                },
                icon: const Icon(Icons.send, color: teal),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (message != null)
            Text(message!, style: const TextStyle(color: Colors.red)),
          ...comments.map(
            (c) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(c.body),
              subtitle: Text(
                DateFormat('yyyy-MM-dd').format(c.createdAt ?? DateTime.now()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await supabase.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(register ? 'إنشاء حساب' : 'تسجيل الدخول'),
      backgroundColor: background,
      elevation: 0,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (register)
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
              ),
            if (register) const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: busy ? null : submit,
              style: FilledButton.styleFrom(backgroundColor: teal),
              child: Text(
                busy
                    ? 'جارٍ التنفيذ...'
                    : register
                    ? 'إنشاء الحساب'
                    : 'دخول',
              ),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(
                register
                    ? 'لديك حساب؟ تسجيل الدخول'
                    : 'مستخدم جديد؟ إنشاء حساب',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined, color: teal, size: 42),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xff73837f), height: 1.5),
            textAlign: TextAlign.center,
          ),
          ?action,
        ],
      ),
    ),
  );
}
