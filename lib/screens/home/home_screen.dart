import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../product/product_details_screen.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'الكل',
    'رجالي',
    'نسائي',
    'للجنسين',
    'عود شرقي',
  ];
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _uploadInitialPerfumes() async {
    final perfumesCollection = FirebaseFirestore.instance.collection(
      'perfumes',
    );
    final snapshot = await perfumesCollection.limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('البيانات موجودة بالفعل في قاعدة البيانات'),
        ),
      );
      return;
    }

    final initialList = [
      {
        "name": "حواس (Hawas)",
        "brand": "الرصاصي (Rasasi)",
        "price": "200 ₪",
        "oldPrice": 250.0,
        "category": "رجالي",
        "isSoldOut": false,
        "image":
            "https://images.unsplash.com/photo-1523293115678-d29062015fa7?q=80&w=400&auto=format&fit=crop",
      },
      {
        "name": "خمرة (Khamrah)",
        "brand": "لطافة (Lattafa)",
        "price": "165 ₪",
        "oldPrice": 0.0,
        "category": "نسائي",
        "isSoldOut": false,
        "image":
            "https://images.unsplash.com/photo-1594035910387-fea47794261f?q=80&w=400&auto=format&fit=crop",
      },
    ];

    for (var item in initialList) {
      await perfumesCollection.add(item);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفع العطور الأولية بنجاح!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متجر العطور الفاخرة'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            icon: const Icon(Icons.favorite_outline, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WishlistScreen()),
            ),
          ),
          IconButton(
            tooltip: 'مزامنة العطور الأولية',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _uploadInitialPerfumes,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserWishlistStream(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final List wishlist = List.from(userData?['wishlist'] ?? []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن عطر أو ماركة...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getPerfumesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('حدث خطأ أثناء تحميل البيانات'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: ElevatedButton.icon(
                          onPressed: _uploadInitialPerfumes,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('إضافة العطور الأولية الآن'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      );
                    }

                    final List<Map<String, dynamic>> perfumes = snapshot
                        .data!
                        .docs
                        .map<Map<String, dynamic>>((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final rawImg =
                              (data['image'] ?? data['imageUrl'] ?? '')
                                  .toString();
                          String rawPrice = (data['price'] ?? '')
                              .toString()
                              .replaceAll('\$', '')
                              .replaceAll('USD', '')
                              .replaceAll('₪', '')
                              .trim();
                          String formattedPrice = rawPrice.isNotEmpty
                              ? '$rawPrice ₪'
                              : '';

                          double oldPrice =
                              double.tryParse(
                                (data['oldPrice'] ?? 0).toString(),
                              ) ??
                              0.0;
                          double currentPriceNum =
                              double.tryParse(
                                (data['price50'] ?? 0).toString(),
                              ) ??
                              0.0;
                          if (currentPriceNum == 0) {
                            currentPriceNum = double.tryParse(rawPrice) ?? 0.0;
                          }

                          return {
                            'id': doc.id,
                            'name': (data['name'] ?? 'عطر بدون اسم').toString(),
                            'brand': (data['brand'] ?? '').toString(),
                            'price': formattedPrice,
                            'oldPrice': oldPrice,
                            'currentPriceNum': currentPriceNum,
                            'category': (data['category'] ?? 'رجالي')
                                .toString(),
                            'image': rawImg,
                            'isSoldOut': data['isSoldOut'] == true,
                            'originalData': data,
                          };
                        })
                        .where((perfume) {
                          final matchesCategory =
                              _selectedCategory == 'الكل' ||
                              perfume['category'].toString() ==
                                  _selectedCategory;
                          final query = _searchController.text.toLowerCase();
                          final matchesSearch =
                              perfume['name'].toString().toLowerCase().contains(
                                query,
                              ) ||
                              perfume['brand']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query);
                          return matchesCategory && matchesSearch;
                        })
                        .toList();

                    if (perfumes.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد عطور مطابقة للبحث',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: perfumes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      itemBuilder: (context, index) {
                        final perfume = perfumes[index];
                        final String perfumeId = perfume['id'].toString();
                        final isFavorite = wishlist.contains(perfumeId);
                        final String imageUrl = perfume['image'].toString();
                        final bool isSoldOut = perfume['isSoldOut'] == true;

                        final double oldPrice = perfume['oldPrice'] as double;
                        final double currentPriceNum =
                            perfume['currentPriceNum'] as double;
                        final bool hasDiscount =
                            oldPrice > currentPriceNum &&
                            currentPriceNum > 0 &&
                            !isSoldOut;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                perfume:
                                    perfume['originalData']
                                        as Map<String, dynamic>? ??
                                    perfume,
                              ),
                            ),
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          child:
                                              imageUrl.isNotEmpty &&
                                                  imageUrl.startsWith('http')
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.liquor,
                                                        size: 50,
                                                        color: Color(
                                                          0xFFD4AF37,
                                                        ),
                                                      ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.liquor,
                                                    size: 50,
                                                    color: Color(0xFFD4AF37),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (hasDiscount)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'خصم %',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (isSoldOut) ...[
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade800,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'نفد المخزون',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.9),
                                          radius: 18,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.red
                                                  : Colors.black87,
                                              size: 20,
                                            ),
                                            onPressed: () => _firestoreService
                                                .toggleWishlist(perfumeId),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        perfume['name'].toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSoldOut
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        perfume['brand'].toString(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      if (hasDiscount)
                                        Row(
                                          children: [
                                            Text(
                                              '$oldPrice ₪',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              perfume['price'].toString(),
                                              style: const TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          perfume['price'].toString(),
                                          style: TextStyle(
                                            color: isSoldOut
                                                ? Colors.grey
                                                : const Color(0xFFD4AF37),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
