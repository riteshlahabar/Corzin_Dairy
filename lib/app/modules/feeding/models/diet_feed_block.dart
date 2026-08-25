import 'package:flutter/material.dart';

import 'feed_type_model.dart';

class DietFeedBlock {
  DietFeedBlock({required this.id});

  final int id;
  FeedTypeModel? selectedFeedType;
  String unit = 'Kg';
  final Map<int, bool> subtypeSelected = <int, bool>{};
  final Map<int, TextEditingController> subtypeQtyControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> subtypeDmPercentControllers =
      <int, TextEditingController>{};
  VoidCallback? _listener;

  double get totalQuantity {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      total +=
          double.tryParse(
            subtypeQtyControllers[subtypeId]?.text.trim() ?? '',
          ) ??
          0;
    });
    return total;
  }

  double get totalDryMatter {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      final qty =
          double.tryParse(
            subtypeQtyControllers[subtypeId]?.text.trim() ?? '',
          ) ??
          0;
      final dmPercent =
          double.tryParse(
            subtypeDmPercentControllers[subtypeId]?.text.trim() ?? '',
          ) ??
          0;
      if (qty > 0 && dmPercent > 0 && dmPercent <= 100) {
        total += (qty * dmPercent) / 100;
      }
    });
    return total;
  }

  void configureForFeedType(FeedTypeModel? value, VoidCallback onChanged) {
    _disposeSubtypeControllers();
    selectedFeedType = value;
    unit = value?.defaultUnit ?? 'Kg';
    _listener = onChanged;

    if (value == null) return;

    for (final subtype in value.subtypes) {
      subtypeSelected[subtype.id] = false;
      final ctrl = TextEditingController();
      final dmCtrl = TextEditingController();
      ctrl.addListener(onChanged);
      dmCtrl.addListener(onChanged);
      subtypeQtyControllers[subtype.id] = ctrl;
      subtypeDmPercentControllers[subtype.id] = dmCtrl;
    }
  }

  void setSubtypeSelected(int subtypeId, bool selected) {
    subtypeSelected[subtypeId] = selected;
    if (!selected) {
      subtypeQtyControllers[subtypeId]?.clear();
      subtypeDmPercentControllers[subtypeId]?.clear();
    }
  }

  String? validateSelectedSubtypeInputs() {
    bool hasSelected = false;
    subtypeSelected.forEach((subtypeId, selected) {
      if (selected) {
        hasSelected = true;
      }
    });
    if (!hasSelected) {
      return 'Please select at least one subtype.';
    }

    for (final entry in subtypeSelected.entries) {
      if (!entry.value) continue;
      final qty =
          double.tryParse(
            subtypeQtyControllers[entry.key]?.text.trim() ?? '',
          ) ??
          0;
      if (qty <= 0) {
        return 'Enter valid subtype quantity.';
      }
      final dmPercent =
          double.tryParse(
            subtypeDmPercentControllers[entry.key]?.text.trim() ?? '',
          ) ??
          -1;
      if (dmPercent <= 0 || dmPercent > 100) {
        return 'Enter DM% between 0 and 100.';
      }
    }
    return null;
  }

  List<Map<String, dynamic>> selectedSubtypePayload() {
    final type = selectedFeedType;
    if (type == null) return <Map<String, dynamic>>[];
    final payload = <Map<String, dynamic>>[];
    for (final subtype in type.subtypes) {
      if (!(subtypeSelected[subtype.id] ?? false)) continue;
      final qty =
          double.tryParse(
            subtypeQtyControllers[subtype.id]?.text.trim() ?? '',
          ) ??
          0;
      final dmPercent =
          double.tryParse(
            subtypeDmPercentControllers[subtype.id]?.text.trim() ?? '',
          ) ??
          0;
      if (qty <= 0 || dmPercent <= 0 || dmPercent > 100) continue;
      payload.add({
        'subtype_id': subtype.id,
        'name': subtype.name,
        'quantity': qty,
        'dm_percent': dmPercent,
      });
    }
    return payload;
  }

  void _disposeSubtypeControllers() {
    for (final ctrl in subtypeQtyControllers.values) {
      if (_listener != null) {
        ctrl.removeListener(_listener!);
      }
      ctrl.dispose();
    }
    for (final ctrl in subtypeDmPercentControllers.values) {
      if (_listener != null) {
        ctrl.removeListener(_listener!);
      }
      ctrl.dispose();
    }
    subtypeQtyControllers.clear();
    subtypeDmPercentControllers.clear();
    subtypeSelected.clear();
  }

  void dispose() {
    _disposeSubtypeControllers();
    _listener = null;
  }
}
