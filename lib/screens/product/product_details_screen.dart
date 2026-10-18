import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cart/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> perfume;

  const ProductDetailsScreen({super.key, required this.perfume});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAddingToCart = false;

  void _addToCart() async {
    setState(() => _isAddingToCart = true);

    String rawPrice = (widget.perfume['price'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    double price = double.tryParse(rawPrice) ?? 0.0;
    if (price == 0.0) {
      price =
          double.tryParse((widget.perfume['price50'] ?? 0).toString()) ?? 0.0;
    }

    try {
      // تم حل الخطأ الأحمر هنا باستخدام FirebaseFirestore مباشرة
      await FirebaseFirestore.instance.collection('cart').add({
        'perfumeId': widget.perfume['id'] ?? widget.perfume['name'],
        'name': widget.perfume['name'] ?? 'عطر',
        'brand': widget.perfume['brand'] ?? '',
        'price': price,
        'image': widget.perfume['image'] ?? widget.perfume['imageUrl'] ?? '',
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت الإضافة إلى السلة بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الإضافة للسلة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.perfume;
    final String name = (data['name'] ?? 'عطر بدون اسم').toString();
    final String brand = (data['brand'] ?? '').toString();
    final String description =
        (data['description'] ?? 'لا يوجد وصف متاح لهذا العطر حالياً.')
            .toString();
    final String imageUrl = (data['image'] ?? data['imageUrl'] ?? '')
        .toString();
    final bool isSoldOut = data['isSoldOut'] == true;

    String rawPrice = (data['price'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    double currentPrice = double.tryParse(rawPrice) ?? 0.0;
    if (currentPrice == 0) {
      currentPrice = double.tryParse((data['price50'] ?? 0).toString()) ?? 0.0;
    }

    double oldPrice =
        double.tryParse((data['oldPrice'] ?? 0).toString()) ?? 0.0;
    bool hasDiscount =
        oldPrice > currentPrice && currentPrice > 0 && !isSoldOut;

    var rawNotes = data['notes'];
    List<String> notes = [];
    if (rawNotes is List) {
      notes = rawNotes
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } else if (rawNotes is String && rawNotes.trim().isNotEmpty) {
      notes = [rawNotes];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 400,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : const Icon(
                            Icons.liquor,
                            size: 100,
                            color: Color(0xFFD4AF37),
                          ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 100,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'عرض خاص',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isSoldOut)
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.5,
                      ), // تم التحديث هنا
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'نفد من المخزون',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        currentPrice > 0
                            ? '$currentPrice ₪'
                            : 'السعر غير متوفر',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSoldOut
                              ? Colors.grey
                              : const Color(0xFFD4AF37),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          '$oldPrice ₪',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.redAccent,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (notes.isNotEmpty) ...[
                    const Text(
                      'المكونات العطرية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: notes
                          .map(
                            (note) => Chip(
                              label: Text(
                                note,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              backgroundColor: const Color(0xFFF0F0F0),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'عن العطر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ], // تم التحديث هنا
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSoldOut
                    ? Colors.grey.shade400
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: isSoldOut ? 0 : 5,
              ),
              onPressed: (isSoldOut || _isAddingToCart) ? null : _addToCart,
              child: _isAddingToCart
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isSoldOut ? 'نفد من المخزون' : 'أضف إلى السلة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
