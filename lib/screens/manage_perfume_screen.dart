import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ManagePerfumeScreen extends StatefulWidget {
  final String? perfumeId;
  final Map<String, dynamic>? initialData;

  const ManagePerfumeScreen({super.key, this.perfumeId, this.initialData});

  @override
  State<ManagePerfumeScreen> createState() => _ManagePerfumeScreenState();
}

class _ManagePerfumeScreenState extends State<ManagePerfumeScreen> {
  static const String _imgbbApiKey = '9636b11e695480df8b135eb982abca73';
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _oldPriceController;
  late TextEditingController _price50Controller;
  late TextEditingController _price100Controller;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String _selectedCategory = 'رجالي';
  final List<String> _categories = ['رجالي', 'نسائي', 'للجنسين', 'عود شرقي'];
  bool _isLoading = false;
  bool _isSoldOut = false;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};

    _nameController = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );
    _brandController = TextEditingController(
      text: (data['brand'] ?? '').toString(),
    );

    String rawOldPrice = (data['oldPrice'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    String rawPrice50 = (data['price50'] ?? data['price'] ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9.]'), '');
    String rawPrice100 = (data['price100'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    _oldPriceController = TextEditingController(text: rawOldPrice);
    _price50Controller = TextEditingController(text: rawPrice50);
    _price100Controller = TextEditingController(text: rawPrice100);

    _imageController = TextEditingController(
      text: (data['image'] ?? data['imageUrl'] ?? '').toString().trim(),
    );
    _descriptionController = TextEditingController(
      text: (data['description'] ?? '').toString(),
    );

    var rawNotes = data['notes'];
    List<String> notesList = [];
    if (rawNotes is List) {
      notesList = rawNotes.map((e) => e.toString()).toList();
    } else if (rawNotes is String) {
      notesList = [rawNotes];
    }
    _notesController = TextEditingController(text: notesList.join(', '));

    _isSoldOut = data['isSoldOut'] == true;

    String cat = (data['category'] ?? '').toString().trim();
    if (_categories.contains(cat)) {
      _selectedCategory = cat;
    } else {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _oldPriceController.dispose();
    _price50Controller.dispose();
    _price100Controller.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح المعرض: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadToImgBB(File imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'];
    } else {
      throw Exception('فشل رفع الصورة إلى السيرفر');
    }
  }

  Future<void> _savePerfume() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasImage =
        _pickedImageFile != null || _imageController.text.trim().isNotEmpty;
    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة من المعرض أو وضع رابط صورة'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _imageController.text.trim();

      if (_pickedImageFile != null) {
        finalImageUrl = await _uploadToImgBB(_pickedImageFile!);
      }

      final double oldPrice =
          double.tryParse(_oldPriceController.text.trim()) ?? 0.0;
      final double price50 =
          double.tryParse(_price50Controller.text.trim()) ?? 0.0;
      final double price100 =
          double.tryParse(_price100Controller.text.trim()) ?? price50;
      final List<String> notes = _notesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final perfumeData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'price': '$price50 ₪',
        'oldPrice': oldPrice,
        'price50': price50,
        'price100': price100,
        'image': finalImageUrl,
        'imageUrl': finalImageUrl,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'notes': notes,
        'isSoldOut': _isSoldOut,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.perfumeId == null) {
        perfumeData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('perfumes')
            .add(perfumeData);
      } else {
        await FirebaseFirestore.instance
            .collection('perfumes')
            .doc(widget.perfumeId)
            .update(perfumeData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.perfumeId == null
                  ? 'تمت إضافة العطر بنجاح'
                  : 'تم تعديل العطر بنجاح',
            ),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePerfume() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: const Text(
          'هل أنت متأكد من حذف هذا العطر من المتجر؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('perfumes')
          .doc(widget.perfumeId)
          .delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العطر'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.perfumeId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isEditing ? 'تعديل العطر' : 'إضافة عطر جديد',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isLoading ? null : _deletePerfume,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 16),
                  Text(
                    'جاري حفظ البيانات...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                      ),
                      child: _pickedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                _pickedImageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (_imageController.text.isNotEmpty &&
                                _imageController.text.startsWith('http'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                _imageController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 50,
                                  color: Color(0xFFD4AF37),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'اضغط هنا لاختيار صورة العطر من هاتفك',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, 'اسم العطر', Icons.title),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _brandController,
                    'الماركة (Brand)',
                    Icons.branding_watermark,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _price50Controller,
                          'سعر 50ml (₪)',
                          Icons.attach_money,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _price100Controller,
                          'سعر 100ml (₪)',
                          Icons.attach_money,
                          isNumber: true,
                          isRequired: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _oldPriceController,
                    'السعر القديم قبل الخصم (₪) - اختياري',
                    Icons.money_off,
                    isNumber: true,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _imageController,
                    'أو رابط صورة مباشر (اختياري)',
                    Icons.link,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1E1E1E),
                        value: _selectedCategory,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _notesController,
                    'المكونات العطرية (افصل بفواصل: عود, عنبر)',
                    Icons.bubble_chart,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _descriptionController,
                    'الوصف التعريفي للعطر',
                    Icons.description,
                    maxLines: 3,
                    isRequired: false,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isSoldOut ? Colors.redAccent : Colors.white24,
                      ),
                    ),
                    child: SwitchListTile(
                      activeTrackColor: Colors.redAccent,
                      title: const Text(
                        'نفد من المخزون (Sold Out)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _isSoldOut
                            ? 'العطر غير متاح للشراء حالياً'
                            : 'العطر متوفر في المتجر',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: _isSoldOut,
                      onChanged: (val) {
                        setState(() => _isSoldOut = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _savePerfume,
                    child: Text(
                      isEditing ? 'حفظ التعديلات' : 'إضافة العطر للمتجر',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }
}
