import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/api.dart';

class ShopController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = 'all'.obs;
  final RxList<ShopProductModel> products = <ShopProductModel>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  List<ShopProductModel> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    return products.where((item) {
      final categoryMatch = selectedCategory.value == 'all'
          ? true
          : item.category == selectedCategory.value;
      final searchMatch = query.isEmpty || item.searchText.contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    loadShopData();
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

      final categoryData = categoryResponse.body.isNotEmpty
          ? jsonDecode(categoryResponse.body)
          : {};
      final productData = productResponse.body.isNotEmpty
          ? jsonDecode(productResponse.body)
          : {};

      final List categoryList = categoryData['data'] ?? [];
      categories.assignAll([
        'all',
        ...categoryList.map((item) => item.toString().toLowerCase()),
      ]);

      final List productList = productData['data'] ?? [];
      products.assignAll(
        productList.map((item) => ShopProductModel.fromJson(item)).toList(),
      );
    } catch (_) {
      categories.assignAll(['all']);
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class ShopProductModel {
  final String name;
  final String category;
  final String price;
  final String subtitle;
  final String unit;
  final String description;

  const ShopProductModel({
    required this.name,
    required this.category,
    required this.price,
    required this.subtitle,
    required this.unit,
    required this.description,
  });

  String get searchText => [
    name,
    category,
    subtitle,
    unit,
    description,
    price,
  ].join(' ').toLowerCase();

  factory ShopProductModel.fromJson(Map<String, dynamic> json) {
    return ShopProductModel(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? '',
      price: json['price_label']?.toString() ?? 'Rs 0.00',
      subtitle: json['subtitle']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
