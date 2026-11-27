import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'services.dart';

const editorTeal = Color(0xff087f75);
const editorInk = Color(0xff173b37);
const editorBackground = Color(0xfff6f9f8);

class PropertyEditorPage extends StatefulWidget {
  const PropertyEditorPage({this.property, super.key});
  final Property? property;
  @override
  State<PropertyEditorPage> createState() => _PropertyEditorPageState();
}

class _PropertyEditorPageState extends State<PropertyEditorPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title,
      price,
      city,
      area,
      rooms,
      description,
      phone;
  final picker = ImagePicker();
  late List<String> existingImages;
  final selectedFiles = <XFile>[];
  late DealType type;
  late bool sold;
  bool saving = false;
  String? error;
  bool get editing => widget.property != null;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    title = TextEditingController(text: p?.title ?? '');
    price = TextEditingController(text: p == null ? '' : p.price.toString());
    city = TextEditingController(text: p?.city ?? '');
    area = TextEditingController(text: p?.area?.toString() ?? '');
    rooms = TextEditingController(text: p?.rooms?.toString() ?? '');
    description = TextEditingController(text: p?.description ?? '');
    phone = TextEditingController(text: p?.contactPhone ?? '');
    existingImages = [...p?.images ?? const []];
    type = p?.type ?? DealType.sale;
    sold = p?.sold ?? false;
  }

  @override
  void dispose() {
    title.dispose();
    price.dispose();
    city.dispose();
    area.dispose();
    rooms.dispose();
    description.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> chooseImages() async {
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) setState(() => selectedFiles.addAll(files));
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      var allImages = [...existingImages];
      final removed =
          widget.property?.images
              .where((url) => !existingImages.contains(url))
              .toList() ??
          const <String>[];
      final id = await saveProperty(
        id: widget.property?.id,
        title: title.text,
        price: num.parse(price.text),
        city: city.text,
        area: num.tryParse(area.text),
        rooms: int.tryParse(rooms.text),
        type: type,
        description: description.text,
        contactPhone: phone.text,
        images: allImages,
        sold: sold,
      );
      if (selectedFiles.isNotEmpty) {
        final uploaded = await uploadPropertyImages(selectedFiles);
        allImages = [...allImages, ...uploaded];
        await saveProperty(
          id: id,
          title: title.text,
          price: num.parse(price.text),
          city: city.text,
          area: num.tryParse(area.text),
          rooms: int.tryParse(rooms.text),
          type: type,
          description: description.text,
          contactPhone: phone.text,
          images: allImages,
          sold: sold,
        );
      }
      if (removed.isNotEmpty) await deletePropertyImages(removed);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: editorBackground,
    appBar: AppBar(
      backgroundColor: editorBackground,
      elevation: 0,
      title: Text(
        editing ? 'تعديل العقار' : 'إضافة عقار',
        style: const TextStyle(color: editorInk, fontWeight: FontWeight.w800),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            children: [
              TextFormField(
                controller: title,
                decoration: inputDecoration('عنوان العقار'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration('السعر'),
                      validator: (v) => num.tryParse(v ?? '') == null
                          ? 'أدخل سعراً صحيحاً'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<DealType>(
                      initialValue: type,
                      decoration: inputDecoration('نوع العرض'),
                      items: const [
                        DropdownMenuItem(
                          value: DealType.sale,
                          child: Text('بيع'),
                        ),
                        DropdownMenuItem(
                          value: DealType.rent,
                          child: Text('إيجار'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => type = v ?? DealType.sale),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: city,
                      decoration: inputDecoration('المدينة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: area,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration('المساحة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: rooms,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration('الغرف'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: inputDecoration('رقم التواصل'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                minLines: 4,
                maxLines: 7,
                decoration: inputDecoration('الوصف'),
              ),
              SwitchListTile(
                value: sold,
                onChanged: (v) => setState(() => sold = v),
                title: const Text('العقار مباع / مؤجر'),
                activeThumbColor: editorTeal,
                contentPadding: EdgeInsets.zero,
              ),
              _ImagesSection(
                existingImages: existingImages,
                selectedFiles: selectedFiles,
                onAdd: chooseImages,
                onRemoveExisting: (url) =>
                    setState(() => existingImages.remove(url)),
                onRemoveNew: (file) =>
                    setState(() => selectedFiles.remove(file)),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: saving ? null : save,
                style: FilledButton.styleFrom(
                  backgroundColor: editorTeal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ العقار'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.existingImages,
    required this.selectedFiles,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });
  final List<String> existingImages;
  final List<XFile> selectedFiles;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<XFile> onRemoveNew;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'صور العقار',
            style: TextStyle(
              color: editorInk,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: editorTeal,
            ),
            label: const Text('اختيار صور'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (existingImages.isEmpty && selectedFiles.isEmpty)
        const Text(
          'لم تتم إضافة صور بعد.',
          style: TextStyle(color: Color(0xff71847f)),
        ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...existingImages.map(
            (url) => _ImageThumb(
              image: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined, color: editorTeal),
              ),
              onRemove: () => onRemoveExisting(url),
            ),
          ),
          ...selectedFiles.map(
            (file) => _ImageThumb(
              image: FutureBuilder(
                future: file.readAsBytes(),
                builder: (_, snapshot) => snapshot.hasData
                    ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                    : const Center(
                        child: CircularProgressIndicator(color: editorTeal),
                      ),
              ),
              onRemove: () => onRemoveNew(file),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.image, required this.onRemove});
  final Widget image;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 110,
          height: 90,
          child: ColoredBox(color: const Color(0xffdcefea), child: image),
        ),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: InkWell(
          onTap: onRemove,
          child: const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Icon(Icons.close, size: 15, color: Colors.red),
          ),
        ),
      ),
    ],
  );
}
