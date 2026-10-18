import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  // إضافة عطر أو زيادة كميته إذا كان موجوداً
  void addItem(Map<String, dynamic> product) {
    int index = _items.indexWhere((item) => item['name'] == product['name']);
    if (index >= 0) {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 1) + 1;
    } else {
      _items.add({...product, 'quantity': 1}); // إضافة منتج جديد بكمية 1
    }
    notifyListeners();
  }

  // زيادة الكمية من السلة
  void incrementQuantity(int index) {
    _items[index]['quantity'] += 1;
    notifyListeners();
  }

  // نقصان الكمية أو حذفها إذا وصلت 0
  void decrementQuantity(int index) {
    if (_items[index]['quantity'] > 1) {
      _items[index]['quantity'] -= 1;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // حذف عنصر محدد من السلة
  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // إفراغ السلة بالكامل بعد نجاح الطلب
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // حساب الإجمالي مع ضرب السعر في الكمية
  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      String priceString = item['price'].toString().replaceAll('\$', '').trim();
      double price = double.tryParse(priceString) ?? 0.0;
      int qty = item['quantity'] ?? 1;
      total += (price * qty);
    }
    return total;
  }
}
