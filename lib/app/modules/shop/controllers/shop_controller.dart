import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class ShopController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isPlacingOrder = false.obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = 'all'.obs;
  final RxList<ShopProductModel> products = <ShopProductModel>[].obs;
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedPaymentMethod = 'cod'.obs;

  int farmerId = 0;

  List<ShopProductModel> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    return products.where((item) {
      final categoryMatch = selectedCategory.value == 'all' ? true : item.category == selectedCategory.value;
      final searchMatch = query.isEmpty || item.searchText.contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  int get cartCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => cartItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get deliveryCharge => 0;
  double get grandTotal => subtotal + deliveryCharge;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    _loadFarmerContext();
    loadShopData();
  }

  Future<void> _loadFarmerContext() async {
    farmerId = await SessionService.getFarmerId();
    final profile = await SessionService.getFarmerProfile();
    final parts = <String>[
      profile['village'] ?? '',
      profile['city'] ?? '',
      profile['taluka'] ?? '',
      profile['district'] ?? '',
      profile['state'] ?? '',
      profile['pincode'] ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();
    addressController.text = parts.isEmpty ? '' : parts.join(', ');
  }

  Future<void> loadShopData() async {
    try {
      isLoading.value = true;
      final responses = await Future.wait([
        http.get(Uri.parse(Api.shopCategories), headers: {'Accept': 'application/json'}),
        http.get(Uri.parse(Api.shopProducts), headers: {'Accept': 'application/json'}),
      ]);

      final categoryResponse = responses[0];
      final productResponse = responses[1];

      final categoryData = categoryResponse.body.isNotEmpty ? jsonDecode(categoryResponse.body) : {};
      final productData = productResponse.body.isNotEmpty ? jsonDecode(productResponse.body) : {};

      final List categoryList = categoryData['data'] ?? [];
      categories.assignAll([
        'all',
        ...categoryList.map((item) => item.toString().toLowerCase()),
      ]);

      final List productList = productData['data'] ?? [];
      products.assignAll(productList.map((item) => ShopProductModel.fromJson(item)).toList());
    } catch (_) {
      categories.assignAll(['all']);
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void addToCart(ShopProductModel product, {int quantity = 1}) {
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      cartItems[index] = cartItems[index].copyWith(quantity: cartItems[index].quantity + quantity);
    } else {
      cartItems.add(CartItemModel(product: product, quantity: quantity));
    }
    cartItems.refresh();
    Get.snackbar('Added', '${product.name} added to cart');
  }

  void increaseQty(CartItemModel item) {
    final index = cartItems.indexWhere((e) => e.product.id == item.product.id);
    if (index < 0) return;
    cartItems[index] = cartItems[index].copyWith(quantity: cartItems[index].quantity + 1);
    cartItems.refresh();
  }

  void decreaseQty(CartItemModel item) {
    final index = cartItems.indexWhere((e) => e.product.id == item.product.id);
    if (index < 0) return;
    final next = cartItems[index].quantity - 1;
    if (next <= 0) {
      cartItems.removeAt(index);
    } else {
      cartItems[index] = cartItems[index].copyWith(quantity: next);
    }
    cartItems.refresh();
  }

  Future<bool> placeOrder({List<CartItemModel>? directItems}) async {
    final items = (directItems ?? cartItems).where((e) => e.quantity > 0).toList();
    if (items.isEmpty) {
      Get.snackbar('Empty Cart', 'Please add product to cart.');
      return false;
    }
    if (farmerId <= 0) {
      Get.snackbar('Error', 'Farmer session not found.');
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      Get.snackbar('Address Required', 'Please provide delivery address.');
      return false;
    }

    try {
      isPlacingOrder.value = true;
      final payload = {
        'farmer_id': farmerId,
        'shipping_address': addressController.text.trim(),
        'payment_method': selectedPaymentMethod.value,
        'items': items
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
      };

      final response = await http.post(
        Uri.parse(Api.shopOrders),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final success = (response.statusCode == 200 || response.statusCode == 201) && data['status'] == true;
      if (!success) {
        Get.snackbar('Order Failed', data['message']?.toString() ?? 'Unable to place order.');
        return false;
      }

      if (directItems == null) {
        cartItems.clear();
      }
      return true;
    } catch (e) {
      Get.snackbar('Order Failed', e.toString());
      return false;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    addressController.dispose();
    super.onClose();
  }
}

class ShopProductModel {
  final int id;
  final String name;
  final String category;
  final String priceLabel;
  final double price;
  final String subtitle;
  final String unit;
  final String description;
  final List<String> features;
  final String imageUrl;
  final List<String> galleryImageUrls;

  const ShopProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.priceLabel,
    required this.price,
    required this.subtitle,
    required this.unit,
    required this.description,
    required this.features,
    required this.imageUrl,
    required this.galleryImageUrls,
  });

  String get searchText => [name, category, subtitle, unit, description, priceLabel, ...features].join(' ').toLowerCase();

  factory ShopProductModel.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['gallery_image_urls'];
    final List<String> gallery = galleryRaw is List ? galleryRaw.map((e) => e.toString()).toList() : <String>[];
    final featuresRaw = json['features'];
    final List<String> features = featuresRaw is List ? featuresRaw.map((e) => e.toString()).toList() : <String>[];

    return ShopProductModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? '',
      priceLabel: json['price_label']?.toString() ?? 'Rs 0.00',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      subtitle: json['subtitle']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      features: features,
      imageUrl: json['image_url']?.toString() ?? '',
      galleryImageUrls: gallery,
    );
  }
}

class CartItemModel {
  const CartItemModel({
    required this.product,
    required this.quantity,
  });

  final ShopProductModel product;
  final int quantity;

  CartItemModel copyWith({
    ShopProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
