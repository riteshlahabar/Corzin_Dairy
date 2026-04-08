import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class AnimalHistoryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<AnimalHistoryItem> history = <AnimalHistoryItem>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  int farmerId = 0;

  List<AnimalHistoryItem> get filteredHistory {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return history;
    return history.where((item) => item.searchText.contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() => searchQuery.value = searchController.text);
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await fetchHistory();
  }

  Future<void> fetchHistory() async {
    if (farmerId == 0) {
      history.clear();
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.animalHistory}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        history.assignAll(list.map((item) => AnimalHistoryItem.fromJson(item)).toList());
      } else {
        history.clear();
      }
    } catch (_) {
      history.clear();
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

class AnimalHistoryItem {
  final String animalName;
  final String tagNumber;
  final String actionType;
  final String fromStatus;
  final String toStatus;
  final String fromAnimalType;
  final String toAnimalType;
  final String notes;
  final String changedAt;

  AnimalHistoryItem({
    required this.animalName,
    required this.tagNumber,
    required this.actionType,
    required this.fromStatus,
    required this.toStatus,
    required this.fromAnimalType,
    required this.toAnimalType,
    required this.notes,
    required this.changedAt,
  });

  String get prettyAction => actionType.replaceAll('_', ' ');

  String get searchText => [
    animalName,
    tagNumber,
    actionType,
    fromStatus,
    toStatus,
    fromAnimalType,
    toAnimalType,
    notes,
    changedAt,
  ].join(' ').toLowerCase();

  factory AnimalHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnimalHistoryItem(
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      fromStatus: json['from_status']?.toString() ?? '',
      toStatus: json['to_status']?.toString() ?? '',
      fromAnimalType: json['from_animal_type']?.toString() ?? '',
      toAnimalType: json['to_animal_type']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      changedAt: json['changed_at']?.toString() ?? '',
    );
  }
}
