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
  final RxList<ShopOrderModel> myOrders = <ShopOrderModel>[].obs;
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
  double get subtotal => cartItems.fold(0, (sum, item) => sum + lineTotalForItem(item));
  double get deliveryCharge => 0;
  double get grandTotal => subtotal + deliveryCharge;

  bool supportsQuantityMode(CartItemModel item) => item.product.hasPackPricing;

  bool canUseUnitMode(CartItemModel item) =>
      item.product.hasPackPricing && item.product.allowPartialUnits;

  double itemUnitPrice(CartItemModel item) {
    if (item.product.hasPackPricing && item.quantityMode == CartQuantityMode.unit) {
      return item.product.unitPrice;
    }
    return item.product.price;
  }

  String itemUnitLabel(CartItemModel item) {
    if (!item.product.hasPackPricing) {
      return item.product.unit.trim().isEmpty ? 'unit' : item.product.unit.trim();
    }
    if (item.quantityMode == CartQuantityMode.pack) {
      return 'strip';
    }
    return item.product.medicineUnitName;
  }

  double lineTotalForItem(CartItemModel item) {
    return itemUnitPrice(item) * item.quantity;
  }

  String itemRateLabel(CartItemModel item) {
    final unitPrice = itemUnitPrice(item).toStringAsFixed(2);
    final unitName = itemUnitLabel(item);
    if (!item.product.hasPackPricing) {
      return 'Rs $unitPrice / $unitName';
    }
    final packInfo = '1 strip = ${item.product.packSize} ${item.product.medicineUnitName}';
    return 'Rs $unitPrice / $unitName ($packInfo)';
  }

  String itemQuantityLabel(CartItemModel item) {
    return '${item.quantity} ${itemUnitLabel(item)}';
  }

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

  void addToCart(
    ShopProductModel product, {
    int quantity = 1,
    String? quantityMode,
    bool showMessage = true,
  }) {
    final targetMode = _initialQuantityModeForProduct(
      product,
      override: quantityMode,
    );
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      var current = cartItems[index];
      if (current.quantityMode != targetMode && product.hasPackPricing) {
        final converted = _convertQuantityBetweenModes(
          quantity: current.quantity,
          fromMode: current.quantityMode,
          toMode: targetMode,
          packSize: product.packSize,
        );
        current = current.copyWith(quantity: converted, quantityMode: targetMode);
      }
      cartItems[index] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      cartItems.add(
        CartItemModel(
          product: product,
          quantity: quantity,
          quantityMode: targetMode,
        ),
      );
    }
    cartItems.refresh();
    if (showMessage) {
      Get.snackbar('Added', '${product.name} added to cart');
    }
  }

  CartItemModel initialCartItemForProduct(
    ShopProductModel product, {
    int quantity = 1,
    String? quantityMode,
  }) {
    return CartItemModel(
      product: product,
      quantity: quantity <= 0 ? 1 : quantity,
      quantityMode: _initialQuantityModeForProduct(product, override: quantityMode),
    );
  }

  void updateQuantityMode(CartItemModel item, String nextMode) {
    final index = cartItems.indexWhere((e) => e.product.id == item.product.id);
    if (index < 0) return;
    if (!item.product.hasPackPricing) return;

    final normalizedMode =
        nextMode == CartQuantityMode.unit && item.product.allowPartialUnits
            ? CartQuantityMode.unit
            : CartQuantityMode.pack;

    if (cartItems[index].quantityMode == normalizedMode) {
      return;
    }

    final convertedQty = _convertQuantityBetweenModes(
      quantity: cartItems[index].quantity,
      fromMode: cartItems[index].quantityMode,
      toMode: normalizedMode,
      packSize: item.product.packSize,
    );
    cartItems[index] = cartItems[index].copyWith(
      quantity: convertedQty,
      quantityMode: normalizedMode,
    );
    cartItems.refresh();
  }

  void removeFromCart(CartItemModel item) {
    final index = cartItems.indexWhere((e) => e.product.id == item.product.id);
    if (index < 0) return;
    final removed = cartItems[index].product.name;
    cartItems.removeAt(index);
    cartItems.refresh();
    Get.snackbar('Removed', '$removed removed from cart');
  }

  String _initialQuantityModeForProduct(
    ShopProductModel product, {
    String? override,
  }) {
    if (!product.hasPackPricing) return CartQuantityMode.pack;

    if (override == CartQuantityMode.unit && product.allowPartialUnits) {
      return CartQuantityMode.unit;
    }
    if (override == CartQuantityMode.pack) {
      return CartQuantityMode.pack;
    }

    return product.allowPartialUnits ? CartQuantityMode.unit : CartQuantityMode.pack;
  }

  int _convertQuantityBetweenModes({
    required int quantity,
    required String fromMode,
    required String toMode,
    required int packSize,
  }) {
    final safeQty = quantity <= 0 ? 1 : quantity;
    if (fromMode == toMode) return safeQty;
    if (packSize <= 0) return safeQty;

    if (fromMode == CartQuantityMode.pack && toMode == CartQuantityMode.unit) {
      return (safeQty * packSize).clamp(1, 5000);
    }
    if (fromMode == CartQuantityMode.unit && toMode == CartQuantityMode.pack) {
      return (safeQty / packSize).ceil().clamp(1, 5000);
    }
    return safeQty;
  }

  Future<PrescriptionAddToCartResult> addPrescriptionToCart(
    List<PrescriptionCartRequest> requests,
  ) async {
    final cleaned = requests
        .where((item) => item.name.trim().isNotEmpty)
        .map((item) => PrescriptionCartRequest(
              name: item.name.trim(),
              quantity: _safePrescriptionQty(item.quantity),
            ))
        .toList();

    if (cleaned.isEmpty) {
      Get.snackbar('Unavailable', 'No prescription medicine found.');
      return const PrescriptionAddToCartResult(addedCount: 0, unmatchedNames: []);
    }

    List<PrescriptionProductMatch> matches = await _fetchPrescriptionMatches(cleaned);
    if (matches.isEmpty) {
      matches = _localPrescriptionMatches(cleaned);
    }

    if (matches.isEmpty) {
      Get.snackbar('Unavailable', 'Prescription medicines are not available in shop.');
      return PrescriptionAddToCartResult(
        addedCount: 0,
        unmatchedNames: cleaned.map((item) => item.name).toList(),
      );
    }

    final grouped = <int, PrescriptionProductMatch>{};
    for (final match in matches) {
      final existing = grouped[match.product.id];
      if (existing == null) {
        grouped[match.product.id] = match;
      } else {
        grouped[match.product.id] = existing.copyWith(
          quantity: existing.quantity + match.quantity,
        );
      }
    }

    for (final match in grouped.values) {
      final useUnitMode = match.product.hasPackPricing && match.product.allowPartialUnits;
      final qtyToAdd = useUnitMode
          ? _safePrescriptionQty(match.quantity)
          : (match.product.hasPackPricing
              ? (match.quantity / match.product.packSize).ceil().clamp(1, 50)
              : _safePrescriptionQty(match.quantity));
      addToCart(
        match.product,
        quantity: qtyToAdd,
        quantityMode: useUnitMode ? CartQuantityMode.unit : CartQuantityMode.pack,
        showMessage: false,
      );
    }

    final matchedNames = matches.map((e) => e.requestedName.toLowerCase()).toSet();
    final unmatched = cleaned
        .where((item) => !matchedNames.contains(item.name.toLowerCase()))
        .map((item) => item.name)
        .toSet()
        .toList();

    Get.snackbar(
      'Added',
      '${grouped.length} prescription item(s) added to cart',
    );

    if (unmatched.isNotEmpty) {
      Get.snackbar(
        'Some medicines not found',
        unmatched.join(', '),
        duration: const Duration(seconds: 4),
      );
    }

    return PrescriptionAddToCartResult(
      addedCount: grouped.length,
      unmatchedNames: unmatched,
    );
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

  Future<List<PrescriptionProductMatch>> _fetchPrescriptionMatches(
    List<PrescriptionCartRequest> requests,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(Api.shopPrescriptionProducts),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': requests
              .map((item) => {
                    'name': item.name,
                    'quantity': _safePrescriptionQty(item.quantity),
                  })
              .toList(),
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok = (response.statusCode == 200 || response.statusCode == 201) && data['status'] == true;
      if (!ok) {
        return const [];
      }

      final payload = data['data'];
      if (payload is! Map) {
        return const [];
      }

      final rows = payload['matched'];
      if (rows is! List) {
        return const [];
      }

      return rows
          .map((row) => row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{})
          .map((row) {
            final productMap = row['product'];
            if (productMap is! Map) {
              return null;
            }
            final product = ShopProductModel.fromJson(Map<String, dynamic>.from(productMap));
            if (product.id <= 0) {
              return null;
            }
            return PrescriptionProductMatch(
              requestedName: row['requested_name']?.toString() ?? '',
              quantity: _safePrescriptionQty(int.tryParse(row['quantity']?.toString() ?? '1') ?? 1),
              product: product,
            );
          })
          .whereType<PrescriptionProductMatch>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<PrescriptionProductMatch> _localPrescriptionMatches(
    List<PrescriptionCartRequest> requests,
  ) {
    final matches = <PrescriptionProductMatch>[];
    for (final request in requests) {
      final product = _localFindProductForPrescriptionName(request.name);
      if (product == null) continue;
      matches.add(
        PrescriptionProductMatch(
          requestedName: request.name,
          quantity: _safePrescriptionQty(request.quantity),
          product: product,
        ),
      );
    }
    return matches;
  }

  ShopProductModel? _localFindProductForPrescriptionName(String medicineName) {
    final needle = medicineName.trim().toLowerCase();
    if (needle.isEmpty) return null;

    ShopProductModel? exactMedicine;
    ShopProductModel? containsMedicine;
    ShopProductModel? containsAny;

    for (final product in products) {
      final name = product.name.trim().toLowerCase();
      final subtitle = product.subtitle.trim().toLowerCase();
      final description = product.description.trim().toLowerCase();
      final aliases = product.medicineAliases.join(' ').toLowerCase();
      final isMedicine = product.category.trim().toLowerCase() == 'medicine';

      if (name == needle) {
        if (isMedicine) return product;
        exactMedicine ??= product;
      }

      final contains = name.contains(needle) ||
          needle.contains(name) ||
          subtitle.contains(needle) ||
          description.contains(needle) ||
          aliases.contains(needle);
      if (!contains) continue;
      if (isMedicine && containsMedicine == null) {
        containsMedicine = product;
      }
      containsAny ??= product;
    }

    return exactMedicine ?? containsMedicine ?? containsAny;
  }

  int _safePrescriptionQty(int value) {
    if (value <= 0) return 1;
    if (value > 50) return 50;
    return value;
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
                  'quantity_unit': item.product.hasPackPricing ? item.quantityMode : CartQuantityMode.pack,
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

      if (directItems == null) cartItems.clear();
      await fetchMyOrders();
      return true;
    } catch (e) {
      Get.snackbar('Order Failed', e.toString());
      return false;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  Future<void> fetchMyOrders() async {
    if (farmerId <= 0) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.shopOrdersByFarmer}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok = response.statusCode == 200 && data['status'] == true;
      if (!ok) return;
      final List rows = data['data'] ?? [];
      myOrders.assignAll(rows.map((e) => ShopOrderModel.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (_) {}
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
  final bool isMedicine;
  final String priceLabel;
  final double price;
  final String subtitle;
  final String unit;
  final String description;
  final List<String> features;
  final List<String> medicineAliases;
  final int packSize;
  final bool allowPartialUnits;
  final String imageUrl;
  final List<String> galleryImageUrls;

  const ShopProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isMedicine,
    required this.priceLabel,
    required this.price,
    required this.subtitle,
    required this.unit,
    required this.description,
    required this.features,
    required this.medicineAliases,
    required this.packSize,
    required this.allowPartialUnits,
    required this.imageUrl,
    required this.galleryImageUrls,
  });

  bool get hasPackPricing => isMedicine && packSize > 0;

  double get unitPrice {
    if (!hasPackPricing) return price;
    return price / packSize;
  }

  String get medicineUnitName {
    final cleaned = unit.trim();
    if (cleaned.isEmpty) return 'tablet';
    return cleaned.toLowerCase();
  }

  String get searchText => [
        name,
        category,
        subtitle,
        unit,
        description,
        priceLabel,
        ...features,
        ...medicineAliases,
      ].join(' ').toLowerCase();

  factory ShopProductModel.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['gallery_image_urls'];
    final List<String> gallery = galleryRaw is List ? galleryRaw.map((e) => e.toString()).toList() : <String>[];
    final featuresRaw = json['features'];
    final List<String> features = featuresRaw is List ? featuresRaw.map((e) => e.toString()).toList() : <String>[];
    final aliasesRaw = json['medicine_aliases'];
    final List<String> aliases = aliasesRaw is List ? aliasesRaw.map((e) => e.toString()).toList() : <String>[];

    return ShopProductModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? '',
      isMedicine: (json['is_medicine']?.toString().toLowerCase() == 'true') ||
          (json['is_medicine']?.toString() == '1') ||
          (json['category']?.toString().toLowerCase() == 'medicine'),
      priceLabel: json['price_label']?.toString() ?? 'Rs 0.00',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      subtitle: json['subtitle']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      features: features,
      medicineAliases: aliases,
      packSize: int.tryParse(json['pack_size']?.toString() ?? '0') ?? 0,
      allowPartialUnits: (json['allow_partial_units']?.toString().toLowerCase() == 'true') ||
          (json['allow_partial_units']?.toString() == '1'),
      imageUrl: json['image_url']?.toString() ?? '',
      galleryImageUrls: gallery,
    );
  }
}

class CartItemModel {
  const CartItemModel({
    required this.product,
    required this.quantity,
    this.quantityMode = CartQuantityMode.pack,
  });

  final ShopProductModel product;
  final int quantity;
  final String quantityMode;

  CartItemModel copyWith({
    ShopProductModel? product,
    int? quantity,
    String? quantityMode,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      quantityMode: quantityMode ?? this.quantityMode,
    );
  }
}

class ShopOrderModel {
  const ShopOrderModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final double total;
  final String createdAt;
  final List<ShopOrderItemModel> items;

  factory ShopOrderModel.fromJson(Map<String, dynamic> json) {
    final List rawItems = json['items'] is List ? json['items'] as List : <dynamic>[];
    return ShopOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      items: rawItems.map((e) => ShopOrderItemModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class ShopOrderItemModel {
  const ShopOrderItemModel({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.unit,
  });

  final String productName;
  final int quantity;
  final double price;
  final double lineTotal;
  final String unit;

  factory ShopOrderItemModel.fromJson(Map<String, dynamic> json) {
    return ShopOrderItemModel(
      productName: json['product_name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      lineTotal: double.tryParse(json['line_total']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class PrescriptionCartRequest {
  const PrescriptionCartRequest({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;
}

class PrescriptionProductMatch {
  const PrescriptionProductMatch({
    required this.requestedName,
    required this.quantity,
    required this.product,
  });

  final String requestedName;
  final int quantity;
  final ShopProductModel product;

  PrescriptionProductMatch copyWith({
    String? requestedName,
    int? quantity,
    ShopProductModel? product,
  }) {
    return PrescriptionProductMatch(
      requestedName: requestedName ?? this.requestedName,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }
}

class PrescriptionAddToCartResult {
  const PrescriptionAddToCartResult({
    required this.addedCount,
    required this.unmatchedNames,
  });

  final int addedCount;
  final List<String> unmatchedNames;

  bool get hasAdded => addedCount > 0;
}

class CartQuantityMode {
  static const String pack = 'pack';
  static const String unit = 'unit';
}
