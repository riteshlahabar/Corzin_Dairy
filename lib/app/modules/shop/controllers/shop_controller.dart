import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/razorpay_service.dart';
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

  /// False until the first My Orders fetch finishes, so the list can show a
  /// spinner instead of flashing "No orders" while the call is in flight.
  final RxBool hasLoadedMyOrders = false.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedPaymentMethod = ShopPaymentMethod.cod.obs;

  int farmerId = 0;
  String farmerName = '';
  String mobileNumber = '';

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

  int get cartCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      cartItems.fold(0, (sum, item) => sum + lineTotalForItem(item));
  double get deliveryCharge => 0;
  double get grandTotal => subtotal + deliveryCharge;

  bool supportsQuantityMode(CartItemModel item) => item.product.hasPackPricing;

  bool canUseUnitMode(CartItemModel item) =>
      item.product.hasPackPricing && item.product.allowPartialUnits;

  double itemUnitPrice(CartItemModel item) {
    if (item.product.hasPackPricing &&
        item.quantityMode == CartQuantityMode.unit) {
      return item.product.unitPrice;
    }
    return item.product.price;
  }

  String itemUnitLabel(CartItemModel item) {
    if (!item.product.hasPackPricing) {
      return item.product.unit.trim().isEmpty
          ? 'unit'
          : item.product.unit.trim();
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
    final packInfo =
        '1 strip = ${item.product.packSize} ${item.product.medicineUnitName}';
    return 'Rs $unitPrice / $unitName ($packInfo)';
  }

  String itemQuantityLabel(CartItemModel item) {
    return '${item.quantity} ${itemUnitLabel(item)}';
  }

  /// The price line that sits directly under a product's name in the cart and
  /// at checkout. Set [includeQuantity] on screens with no stepper — checkout
  /// — so the line also carries "× 2"; the cart leaves it out because its
  /// stepper already shows the quantity.
  String itemPriceLabel(CartItemModel item, {bool includeQuantity = false}) {
    final product = item.product;
    final price = 'amount_rs'.trParams({
      'value': itemUnitPrice(item).toStringAsFixed(2),
    });
    // A plain pack price needs no "/ unit" suffix — the pack label below it
    // already says what one pack is. Medicine priced per strip or per tablet
    // does, because the rate changes with the selected mode.
    final priceLabel = product.packSize > 0 && !product.hasPackPricing
        ? price
        : '$price / ${itemUnitLabel(item)}';

    if (!includeQuantity) return priceLabel;
    return '$priceLabel  ·  × ${item.quantity}';
  }

  /// The pack-size line shown beneath the price. Empty when the product has
  /// neither a pack size nor a unit, so callers can skip the line entirely.
  String itemPackLabel(CartItemModel item) => item.product.packLabel;

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
    farmerName = await SessionService.getFarmerName();
    mobileNumber = await SessionService.getMobile();
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

  Future<void> loadShopData({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading.value = true;
      }
      final responses = await Future.wait([
        http.get(
          Uri.parse(Api.shopCategories),
          headers: {'Accept': 'application/json'},
        ),
        http.get(
          Uri.parse(Api.shopProducts),
          headers: {'Accept': 'application/json'},
        ),
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
      if (!silent) {
        categories.assignAll(['all']);
        products.clear();
      }
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
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
        current = current.copyWith(
          quantity: converted,
          quantityMode: targetMode,
        );
      }
      cartItems[index] = current.copyWith(
        quantity: current.quantity + quantity,
      );
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
      quantityMode: _initialQuantityModeForProduct(
        product,
        override: quantityMode,
      ),
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

    return product.allowPartialUnits
        ? CartQuantityMode.unit
        : CartQuantityMode.pack;
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
        .map(
          (item) => PrescriptionCartRequest(
            name: item.name.trim(),
            quantity: _safePrescriptionQty(item.quantity),
          ),
        )
        .toList();

    if (cleaned.isEmpty) {
      Get.snackbar('Unavailable', 'No prescription medicine found.');
      return const PrescriptionAddToCartResult(
        addedCount: 0,
        unmatchedNames: [],
      );
    }

    List<PrescriptionProductMatch> matches = await _fetchPrescriptionMatches(
      cleaned,
    );
    if (matches.isEmpty) {
      matches = _localPrescriptionMatches(cleaned);
    }

    if (matches.isEmpty) {
      Get.snackbar(
        'Unavailable',
        'Prescription medicines are not available in shop.',
      );
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
      final useUnitMode =
          match.product.hasPackPricing && match.product.allowPartialUnits;
      final qtyToAdd = useUnitMode
          ? _safePrescriptionQty(match.quantity)
          : (match.product.hasPackPricing
                ? (match.quantity / match.product.packSize).ceil().clamp(1, 50)
                : _safePrescriptionQty(match.quantity));
      addToCart(
        match.product,
        quantity: qtyToAdd,
        quantityMode: useUnitMode
            ? CartQuantityMode.unit
            : CartQuantityMode.pack,
        showMessage: false,
      );
    }

    final matchedNames = matches
        .map((e) => e.requestedName.toLowerCase())
        .toSet();
    final unmatched = cleaned
        .where((item) => !matchedNames.contains(item.name.toLowerCase()))
        .map((item) => item.name)
        .toSet()
        .toList();

    Get.snackbar(
      'added'.tr,
      'prescription_items_added_to_cart'.trParams({
        'count': '${grouped.length}',
      }),
    );

    if (unmatched.isNotEmpty) {
      Get.snackbar(
        'unavailable'.tr,
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
    cartItems[index] = cartItems[index].copyWith(
      quantity: cartItems[index].quantity + 1,
    );
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
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': requests
              .map(
                (item) => {
                  'name': item.name,
                  'quantity': _safePrescriptionQty(item.quantity),
                },
              )
              .toList(),
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok =
          (response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true;
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
          .map(
            (row) => row is Map
                ? Map<String, dynamic>.from(row)
                : <String, dynamic>{},
          )
          .map((row) {
            final productMap = row['product'];
            if (productMap is! Map) {
              return null;
            }
            final product = ShopProductModel.fromJson(
              Map<String, dynamic>.from(productMap),
            );
            if (product.id <= 0) {
              return null;
            }
            return PrescriptionProductMatch(
              requestedName: row['requested_name']?.toString() ?? '',
              quantity: _safePrescriptionQty(
                int.tryParse(row['quantity']?.toString() ?? '1') ?? 1,
              ),
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

      final contains =
          name.contains(needle) ||
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
    return placeOrderWithPayment(directItems: directItems);
  }

  Future<bool> checkoutOrder({List<CartItemModel>? directItems}) async {
    final items = (directItems ?? cartItems)
        .where((e) => e.quantity > 0)
        .toList();
    final validationError = _validateCheckout(items);
    if (validationError != null) {
      Get.snackbar(validationError.title, validationError.message);
      return false;
    }

    if (selectedPaymentMethod.value != ShopPaymentMethod.razorpay) {
      return placeOrderWithPayment(
        directItems: directItems,
        paymentMethod: ShopPaymentMethod.cod,
      );
    }

    final total = items.fold<double>(
      0,
      (sum, item) => sum + lineTotalForItem(item),
    );
    final orderResult = await _createShopRazorpayOrder(items);
    if (!orderResult.success ||
        orderResult.order == null ||
        !orderResult.order!.isValid) {
      Get.snackbar(
        'payment'.tr,
        orderResult.message.isNotEmpty
            ? orderResult.message
            : 'Unable to create payment order.',
      );
      return false;
    }
    final razorpayOrder = orderResult.order!;
    final paymentResult = await RazorpayService.instance.openCheckout(
      amount: razorpayOrder.amount,
      keyId: razorpayOrder.keyId,
      orderId: razorpayOrder.orderId,
      customerName: farmerName,
      contact: mobileNumber,
      description: 'Shop order payment',
      notes: {
        'flow': 'shop',
        'farmer_id': '$farmerId',
        'item_count': '${items.length}',
      },
    );

    if (!paymentResult.success) {
      if (paymentResult.message.trim().isNotEmpty &&
          paymentResult.message.trim() != 'payment_cancelled'.tr) {
        Get.snackbar('payment'.tr, paymentResult.message.trim());
      }
      return false;
    }

    final saved = await placeOrderWithPayment(
      directItems: directItems,
      paymentMethod: ShopPaymentMethod.razorpay,
      paymentStatus: 'paid',
      paidAmount: total,
      paymentMeta: paymentResult.toApiPayload(),
    );
    if (!saved) {
      Get.snackbar(
        'payment'.tr,
        'shop_payment_captured_order_pending'.trParams({
          'id': paymentResult.paymentId,
        }),
        duration: const Duration(seconds: 5),
      );
    }
    return saved;
  }

  Future<_ShopRazorpayOrderResult> _createShopRazorpayOrder(
    List<CartItemModel> items,
  ) async {
    try {
      final payload = <String, dynamic>{
        'farmer_id': farmerId,
        'items': items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'quantity_unit': item.product.hasPackPricing
                    ? item.quantityMode
                    : CartQuantityMode.pack,
              },
            )
            .toList(),
      };
      final response = await http.post(
        Uri.parse(Api.shopRazorpayOrder),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final message = data['message']?.toString().trim() ?? '';
      if (response.statusCode != 200 ||
          data['status'] != true ||
          data['data'] is! Map) {
        return _ShopRazorpayOrderResult(success: false, message: message);
      }
      return _ShopRazorpayOrderResult(
        success: true,
        message: message,
        order: _ShopRazorpayOrder.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        ),
      );
    } catch (e) {
      return _ShopRazorpayOrderResult(success: false, message: e.toString());
    }
  }

  Future<bool> placeOrderWithPayment({
    List<CartItemModel>? directItems,
    String? paymentMethod,
    String? paymentStatus,
    double? paidAmount,
    Map<String, dynamic>? paymentMeta,
  }) async {
    final items = (directItems ?? cartItems)
        .where((e) => e.quantity > 0)
        .toList();
    final validationError = _validateCheckout(items);
    if (validationError != null) {
      Get.snackbar(validationError.title, validationError.message);
      return false;
    }

    try {
      isPlacingOrder.value = true;
      final payload = <String, dynamic>{
        'farmer_id': farmerId,
        'shipping_address': addressController.text.trim(),
        'payment_method': paymentMethod ?? selectedPaymentMethod.value,
        'items': items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'quantity_unit': item.product.hasPackPricing
                    ? item.quantityMode
                    : CartQuantityMode.pack,
              },
            )
            .toList(),
      };
      if (paymentStatus != null && paymentStatus.trim().isNotEmpty) {
        payload['payment_status'] = paymentStatus.trim();
      }
      if (paidAmount != null && paidAmount > 0) {
        payload['paid_amount'] = double.parse(paidAmount.toStringAsFixed(2));
      }
      if (paymentMeta != null && paymentMeta.isNotEmpty) {
        payload['payment_meta'] = paymentMeta;
        payload.addAll(paymentMeta);
      }

      final response = await http.post(
        Uri.parse(Api.shopOrders),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final success =
          (response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true;
      if (!success) {
        Get.snackbar(
          'order_failed'.tr,
          data['message']?.toString() ?? 'unable_to_place_order'.tr,
        );
        return false;
      }

      if (directItems == null) cartItems.clear();
      // Not awaited: the order is already saved, so the success screen should
      // appear immediately. Awaiting the refetch kept the button spinning
      // through a second round-trip, long after the "order placed" push had
      // already arrived. My Orders also refetches in its own initState, so it
      // cannot go stale if this one is still in flight.
      unawaited(fetchMyOrders());
      return true;
    } catch (e) {
      Get.snackbar('order_failed'.tr, e.toString());
      return false;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  _CheckoutValidationError? _validateCheckout(List<CartItemModel> items) {
    if (items.isEmpty) {
      return _CheckoutValidationError(
        title: 'empty_cart'.tr,
        message: 'please_add_product_to_cart'.tr,
      );
    }
    if (farmerId <= 0) {
      return _CheckoutValidationError(
        title: 'error'.tr,
        message: 'please_login_again'.tr,
      );
    }
    if (addressController.text.trim().isEmpty) {
      return _CheckoutValidationError(
        title: 'address_required'.tr,
        message: 'please_provide_delivery_address'.tr,
      );
    }
    return null;
  }

  Future<ShopOrderModel?> fetchOrderById(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.shopOrders}/$orderId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok = response.statusCode == 200 && data['status'] == true;
      if (!ok || data['data'] == null) return null;
      return ShopOrderModel.fromJson(Map<String, dynamic>.from(data['data']));
    } catch (_) {
      return null;
    }
  }

  /// Farmer cancels their own order. The backend enforces the rules (COD only,
  /// and only before the delivery man sets off); this just surfaces whatever it
  /// says. Returns null on success, or the message to show on failure.
  Future<String?> cancelOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.shopOrders}/$orderId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'farmer_id': farmerId}),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok = response.statusCode == 200 && data['status'] == true;
      if (!ok) {
        return data['message']?.toString() ?? 'unable_to_cancel_order'.tr;
      }

      unawaited(fetchMyOrders());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> fetchMyOrders() async {
    if (farmerId <= 0) {
      hasLoadedMyOrders.value = true;
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${Api.shopOrdersByFarmer}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final ok = response.statusCode == 200 && data['status'] == true;
      if (!ok) return;
      final List rows = data['data'] ?? [];
      myOrders.assignAll(
        rows
            .map((e) => ShopOrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (_) {
    } finally {
      hasLoadedMyOrders.value = true;
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

  String get displayUnit {
    final cleanedUnit = unit.trim();
    if (!isMedicine && packSize > 0 && cleanedUnit.isNotEmpty) {
      return '$packSize $cleanedUnit';
    }
    return unit;
  }

  /// "80 kg pack" when the product has a pack size, otherwise just the unit.
  /// Same wording as `ShopOrderItemModel.packLabel` so the cart and the order
  /// details screen describe the same product identically.
  String get packLabel {
    final cleanedUnit = unit.trim();
    if (packSize > 0) {
      return cleanedUnit.isEmpty ? '$packSize pack' : '$packSize $cleanedUnit pack';
    }
    return cleanedUnit;
  }

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
    final List<String> gallery = galleryRaw is List
        ? galleryRaw.map((e) => e.toString()).toList()
        : <String>[];
    final featuresRaw = json['features'];
    final List<String> features = featuresRaw is List
        ? featuresRaw.map((e) => e.toString()).toList()
        : <String>[];
    final aliasesRaw = json['medicine_aliases'];
    final List<String> aliases = aliasesRaw is List
        ? aliasesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return ShopProductModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? '',
      isMedicine:
          (json['is_medicine']?.toString().toLowerCase() == 'true') ||
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
      allowPartialUnits:
          (json['allow_partial_units']?.toString().toLowerCase() == 'true') ||
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
    required this.delivery,
    required this.support,
  });

  final int id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final double total;
  final String createdAt;
  final List<ShopOrderItemModel> items;
  final ShopOrderDeliveryModel delivery;

  /// Support numbers the admin maintains in the web panel, sent with every
  /// order so the Contact Us tab always shows the current ones.
  final ShopSupportContactModel support;

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isDelivered =>
      delivery.isDelivered || status.toLowerCase() == 'completed';

  /// The farmer may cancel only before the delivery man sets off, and only for
  /// COD — a prepaid order would need a refund, which admin handles. Mirrors
  /// CancelOrderService::farmerCanCancel() on the backend.
  bool get canFarmerCancel =>
      !isDelivered &&
      !isCancelled &&
      !delivery.isOutForDelivery &&
      paymentMethod.toLowerCase() == 'cod';

  /// How far the order has got: 1 new order, 2 preparing, 3 out for delivery,
  /// 4 delivered. "Out for delivery" comes from the delivery data rather than
  /// the order status, because it is the delivery man's trip that started.
  int get timelineStep {
    if (isDelivered) return 4;
    if (delivery.isOutForDelivery) return 3;
    if (status.toLowerCase() == 'in_progress') return 2;
    return 1;
  }

  /// The one place a status turns into words. Both My Orders and Order Details
  /// read this, so the two screens cannot drift apart again.
  String get statusLabel {
    if (isCancelled) return 'shop_status_cancelled'.tr;
    if (isDelivered) return 'shop_status_delivered'.tr;
    if (delivery.isOutForDelivery) return 'shop_status_out_for_delivery'.tr;
    if (status.toLowerCase() == 'in_progress') return 'shop_status_preparing'.tr;
    return 'shop_status_order_placed'.tr;
  }

  /// Badge colour matching [statusLabel] — red for cancelled, green when done,
  /// blue while on the way, amber while being prepared.
  Color get statusColor {
    if (isCancelled) return const Color(0xFFD32F2F);
    if (isDelivered) return const Color(0xFF2E7D32);
    if (delivery.isOutForDelivery) return const Color(0xFF1565C0);
    if (status.toLowerCase() == 'in_progress') return const Color(0xFFE07A00);
    return const Color(0xFF6C757D);
  }

  factory ShopOrderModel.fromJson(Map<String, dynamic> json) {
    final List rawItems = json['items'] is List
        ? json['items'] as List
        : <dynamic>[];
    return ShopOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      items: rawItems
          .map((e) => ShopOrderItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      delivery: ShopOrderDeliveryModel.fromJson(
        json['delivery'] is Map
            ? Map<String, dynamic>.from(json['delivery'] as Map)
            : <String, dynamic>{},
      ),
      support: ShopSupportContactModel.fromJson(
        json['support'] is Map
            ? Map<String, dynamic>.from(json['support'] as Map)
            : <String, dynamic>{},
      ),
    );
  }
}

/// Support contact shown under Order Details -> Contact Us. The values are the
/// admin support contact maintained in the web panel under Farmer Data ->
/// Settings, so the same number is used here and for Buy Animal / Upgrade Plan.
/// The fallbacks only apply if the backend sends nothing.
class ShopSupportContactModel {
  const ShopSupportContactModel({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String? name;
  final String phone;
  final String email;

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasEmail => email.trim().isNotEmpty;

  factory ShopSupportContactModel.fromJson(Map<String, dynamic> json) {
    String read(String key, String fallback) {
      final value = json[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    final name = json['name']?.toString().trim() ?? '';

    return ShopSupportContactModel(
      name: name.isEmpty ? null : name,
      phone: read('phone', '18001234567'),
      email: read('email', 'support@corzin.com'),
    );
  }
}

class ShopOrderDeliveryModel {
  const ShopOrderDeliveryModel({
    required this.stage,
    required this.deliveryManName,
    required this.deliveryManPhone,
    required this.code,
    required this.codeExpiresAt,
    required this.placedAt,
    required this.assignedAt,
    required this.departedAt,
    required this.deliveredAt,
  });

  /// One of: unassigned, assigned, out_for_delivery, code_requested, delivered.
  final String stage;
  final String? deliveryManName;
  final String? deliveryManPhone;
  final String? code;
  final String? codeExpiresAt;

  /// Milestone times, used to date each step of the delivery timeline.
  final DateTime? placedAt;
  final DateTime? assignedAt;
  final DateTime? departedAt;
  final DateTime? deliveredAt;

  DateTime? get codeExpiry =>
      codeExpiresAt == null ? null : DateTime.tryParse(codeExpiresAt!)?.toLocal();

  bool get isCodeRequested => stage == 'code_requested' && (code?.isNotEmpty ?? false);
  bool get isAssigned =>
      stage == 'assigned' || stage == 'out_for_delivery' || stage == 'code_requested';

  /// The delivery man has set off. Also true once he has reached the farmer
  /// and asked for the handover code, since that comes after departure.
  bool get isOutForDelivery => stage == 'out_for_delivery' || stage == 'code_requested';
  bool get isDelivered => stage == 'delivered';

  factory ShopOrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    return ShopOrderDeliveryModel(
      stage: json['stage']?.toString() ?? 'unassigned',
      deliveryManName: json['delivery_man_name']?.toString(),
      deliveryManPhone: json['delivery_man_phone']?.toString(),
      code: json['code']?.toString(),
      codeExpiresAt: json['code_expires_at']?.toString(),
      placedAt: at('placed_at'),
      assignedAt: at('assigned_at'),
      departedAt: at('departed_at'),
      deliveredAt: at('delivered_at'),
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
    required this.packSize,
    required this.image,
  });

  final String productName;
  final int quantity;
  final double price;
  final double lineTotal;
  final String unit;

  /// Units per pack, snapshotted when the order was placed. Null when the
  /// product is not sold by the pack.
  final int? packSize;
  final String? image;

  /// "80 kg pack" when the product has a pack size, otherwise just the unit.
  /// Empty when neither is known, so callers can skip the line entirely.
  String get packLabel {
    final trimmedUnit = unit.trim();
    if (packSize != null && packSize! > 0) {
      return trimmedUnit.isEmpty ? '$packSize pack' : '$packSize $trimmedUnit pack';
    }
    return trimmedUnit;
  }

  factory ShopOrderItemModel.fromJson(Map<String, dynamic> json) {
    final packSize = int.tryParse(json['pack_size']?.toString() ?? '');
    final image = json['image']?.toString().trim() ?? '';

    return ShopOrderItemModel(
      productName: json['product_name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      lineTotal: double.tryParse(json['line_total']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString() ?? '',
      packSize: (packSize != null && packSize > 0) ? packSize : null,
      image: image.isEmpty ? null : image,
    );
  }
}

class PrescriptionCartRequest {
  const PrescriptionCartRequest({required this.name, required this.quantity});

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

class ShopPaymentMethod {
  static const String cod = 'cod';
  static const String razorpay = 'razorpay';
}

class _ShopRazorpayOrderResult {
  const _ShopRazorpayOrderResult({
    required this.success,
    required this.message,
    this.order,
  });

  final bool success;
  final String message;
  final _ShopRazorpayOrder? order;
}

class _ShopRazorpayOrder {
  const _ShopRazorpayOrder({
    required this.keyId,
    required this.orderId,
    required this.amount,
  });

  final String keyId;
  final String orderId;
  final double amount;

  bool get isValid => keyId.isNotEmpty && orderId.isNotEmpty && amount > 0;

  factory _ShopRazorpayOrder.fromJson(Map<String, dynamic> json) {
    return _ShopRazorpayOrder(
      keyId: json['key_id']?.toString().trim() ?? '',
      orderId: json['order_id']?.toString().trim() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class _CheckoutValidationError {
  const _CheckoutValidationError({required this.title, required this.message});

  final String title;
  final String message;
}
