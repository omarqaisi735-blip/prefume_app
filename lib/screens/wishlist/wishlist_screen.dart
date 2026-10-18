import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../product/product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المفضلة'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getUserWishlistStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final List wishlistIds = List.from(userData?['wishlist'] ?? []);

          if (wishlistIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'قائمة المفضلة فارغة حالياً',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getPerfumesStream(),
            builder: (context, perfumesSnapshot) {
              if (perfumesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              final favoritePerfumes =
                  perfumesSnapshot.data?.docs.where((doc) {
                    return wishlistIds.contains(doc.id);
                  }).toList() ??
                  [];

              if (favoritePerfumes.isEmpty) {
                return const Center(child: Text('لا توجد عناصر لعرضها'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoritePerfumes.length,
                itemBuilder: (context, index) {
                  final doc = favoritePerfumes[index];
                  final item = doc.data() as Map<String, dynamic>;
                  final perfumeData = {'id': doc.id, ...item};

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item['image'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.liquor,
                                color: Color(0xFFD4AF37),
                              ),
                        ),
                      ),
                      title: Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item['price'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          firestoreService.toggleWishlist(doc.id);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(perfume: perfumeData),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
