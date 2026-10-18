import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference _perfumesCollection = FirebaseFirestore.instance
      .collection('perfumes');

  final CollectionReference _ordersCollection = FirebaseFirestore.instance
      .collection('orders');

  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // 1. جلب تدفق العطور (Real-time stream) للشاشة الرئيسية
  Stream<QuerySnapshot> getPerfumesStream() {
    return _perfumesCollection.snapshots();
  }

  // 2. إضافة عطر جديد إلى قاعدة البيانات
  Future<void> addPerfume({
    required String name,
    required String brand,
    required String price,
    required String category,
    required String image,
    String? description,
  }) async {
    await _perfumesCollection.add({
      'name': name,
      'brand': brand,
      'price': price,
      'category': category,
      'image': image,
      'description': description ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. إرسال وحفظ طلب شراء جديد مع بيانات التوصيل
  Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String phone,
    required String address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لإتمام عملية الشراء');
    }

    await _ordersCollection.add({
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userEmail': user.email ?? '',
      'phone': phone,
      'address': address,
      'items': items,
      'totalPrice': totalPrice,
      'status': 'قيد المعالجة',
      'paymentMethod': 'الدفع عند الاستلام',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. جلب طلبات المستخدم المسجل فقط لعرضها في شاشة "طلباتي"
  Stream<QuerySnapshot> getUserOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _ordersCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 5. تبديل حالة المفضلة لعطر معين (إضافة / إزالة)
  Future<void> toggleWishlist(String perfumeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول لإدارة المفضلة');

    final userDoc = _usersCollection.doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'wishlist': [perfumeId],
      });
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    final List wishlist = List.from(data?['wishlist'] ?? []);

    if (wishlist.contains(perfumeId)) {
      await userDoc.update({
        'wishlist': FieldValue.arrayRemove([perfumeId]),
      });
    } else {
      await userDoc.update({
        'wishlist': FieldValue.arrayUnion([perfumeId]),
      });
    }
  }

  // 6. مراقبة قائمة المعرفات المفضلة للمستخدم الحالي
  Stream<DocumentSnapshot> getUserWishlistStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _usersCollection.doc(user.uid).snapshots();
  }
}
