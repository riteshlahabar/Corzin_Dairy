import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class LivestockReportController extends GetxController {
  static const MethodChannel _exportChannel = MethodChannel(
    'com.dairy.corzin/report_export',
  );

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxString scope = 'animal'.obs;
  final RxString reportType = 'all'.obs;
  final RxnInt selectedTargetId = RxnInt();

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final RxList<ReportTargetOption> targets = <ReportTargetOption>[].obs;
  final RxList<LivestockReportRow> rows = <LivestockReportRow>[].obs;
  final Rx<LivestockReportTotals> totals = LivestockReportTotals.zero().obs;
  final RxList<ReportSectionData> sectionReports = <ReportSectionData>[].obs;

  int farmerId = 0;

  static const String reportTypeAll = 'all';
  static const String reportTypeMilk = 'milk';
  static const String reportTypeFeeding = 'feeding';
  static const String reportTypeMedical = 'medical';
  static const String reportTypeLifecycle = 'lifecycle';
  static const String reportTypeMastitis = 'mastitis';
  static const String reportTypeProfitLoss = 'profit_loss';

  static const String sectionMilk = 'Milk Report';
  static const String sectionFeeding = 'Feeding Report';
  static const String sectionMedical = 'Medical History';
  static const String sectionLifecycle = 'Life Cycle History';
  static const String sectionPregnancy = 'Pregnancy Report';
  static const String sectionMastitis = 'Mastitis Report';
  static const String sectionProfitLoss = 'Profit Loss Report';

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDateController.text = DateFormat('dd/MM/yyyy').format(
      DateTime(now.year, now.month, 1),
    );
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await _loadFarmerId();
    await fetchTargets();
    await fetchReport();
  }

  Future<void> _loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> changeScope(String? value) async {
    final next = (value ?? '').trim().toLowerCase();
    if (next != 'animal' && next != 'pan') return;
    if (scope.value == next) return;
    scope.value = next;
    selectedTargetId.value = null;
    await fetchTargets();
    await fetchReport();
  }

  void changeReportType(String? value) {
    final next = (value ?? '').trim().toLowerCase();
    const allowed = <String>{
      reportTypeAll,
      reportTypeMilk,
      reportTypeFeeding,
      reportTypeMedical,
      reportTypeLifecycle,
      reportTypeMastitis,
      reportTypeProfitLoss,
    };
    if (!allowed.contains(next) || reportType.value == next) return;
    reportType.value = next;
  }

  Future<void> fetchTargets() async {
    if (farmerId == 0) {
      targets.clear();
      return;
    }
    final endpoint = scope.value == 'pan' ? Api.animalPanList : Api.animalList;
    final uri = scope.value == 'pan'
        ? Uri.parse('$endpoint/$farmerId')
        : Uri.parse('$endpoint/$farmerId')
            .replace(queryParameters: const {'include_inactive': '1'});
    try {
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || body['status'] != true) {
        targets.clear();
        return;
      }

      final List<dynamic> list = body['data'] ?? <dynamic>[];
      final items = <ReportTargetOption>[];
      if (scope.value == 'pan') {
        for (final raw in list.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final id = int.tryParse((item['id'] ?? '').toString()) ?? 0;
          final name = (item['name'] ?? '').toString().trim();
          if (id <= 0 || name.isEmpty) continue;
          items.add(ReportTargetOption(id: id, label: name));
        }
      } else {
        for (final raw in list.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final id = int.tryParse((item['id'] ?? '').toString()) ?? 0;
          if (id <= 0) continue;
          final animal = (item['animal_name'] ?? item['name'] ?? '').toString().trim();
          final tag = (item['tag_number'] ?? '').toString().trim();
          if (animal.isEmpty) continue;
          final label = tag.isEmpty ? animal : '$animal ($tag)';
          items.add(ReportTargetOption(id: id, label: label));
        }
      }
      items.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      targets.assignAll(items);

      final selected = selectedTargetId.value;
      if (selected != null && !items.any((item) => item.id == selected)) {
        selectedTargetId.value = null;
      }
    } catch (_) {
      targets.clear();
    }
  }

  Future<void> pickFromDate(BuildContext context) async {
    final picked = await _pickDate(context, fromDateController.text);
    if (picked == null) return;
    fromDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await fetchReport();
  }

  Future<void> pickToDate(BuildContext context) async {
    final picked = await _pickDate(context, toDateController.text);
    if (picked == null) return;
    toDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await fetchReport();
  }

  Future<DateTime?> _pickDate(BuildContext context, String existingText) async {
    final parsed = _parseDisplayDate(existingText) ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            surface: Color(0xFFF2FAF2),
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> fetchReport() async {
    if (farmerId == 0) {
      rows.clear();
      totals.value = LivestockReportTotals.zero();
      sectionReports.clear();
      return;
    }

    final fromDate = _apiDate(fromDateController.text.trim());
    final toDate = _apiDate(toDateController.text.trim());
    final query = <String, String>{
      'scope': scope.value,
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (selectedTargetId.value != null && selectedTargetId.value! > 0) {
      query['target_id'] = selectedTargetId.value.toString();
    }

    try {
      isLoading.value = true;
      final uri = Uri.parse('${Api.livestockReport}/$farmerId').replace(
        queryParameters: query,
      );
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || body['status'] != true) {
        rows.clear();
        totals.value = LivestockReportTotals.zero();
        return;
      }
      final data = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : <String, dynamic>{};
      final list = (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => LivestockReportRow.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      rows.assignAll(list);
      totals.value = LivestockReportTotals.fromJson(
        data['totals'] is Map ? Map<String, dynamic>.from(data['totals']) : <String, dynamic>{},
      );
      sectionReports.assignAll(await _buildDetailedSections());
    } catch (_) {
      rows.clear();
      totals.value = LivestockReportTotals.zero();
      sectionReports.clear();
    } finally {
      isLoading.value = false;
    }
  }

  String get scopeLabel => scope.value == 'pan' ? 'pan_wise'.tr : 'animal_wise'.tr;

  String get selectedTargetLabel {
    final id = selectedTargetId.value;
    if (id == null || id <= 0) {
      return scope.value == 'pan' ? 'all_pans'.tr : 'all_animals'.tr;
    }
    for (final item in targets) {
      if (item.id == id) return item.label;
    }
    return '-';
  }

  List<ReportSectionData> get visibleSections =>
      _filterSectionsByType(sectionReports.toList());

  List<ReportSummaryCardData> get summaryCards {
    final currentSections = visibleSections;
    if (currentSections.isEmpty) return const <ReportSummaryCardData>[];

    final medicalTotal = _sumColumn(currentSections, sectionMedical, 'Total');
    final profitDebit = _sumColumn(currentSections, sectionProfitLoss, 'Debit');
    final profitCredit = _sumColumn(currentSections, sectionProfitLoss, 'Credit');
    final profitNet = profitCredit - profitDebit;

    switch (reportType.value) {
      case reportTypeMilk:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'milk_quantity'.tr, value: '${totals.value.milkQuantity.toStringAsFixed(2)} L'),
          ReportSummaryCardData(label: 'milk_earning'.tr, value: 'Rs ${totals.value.milkAmount.toStringAsFixed(2)}'),
        ];
      case reportTypeFeeding:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'feeding_quantity'.tr, value: '${totals.value.feedingQuantity.toStringAsFixed(2)} Kg'),
          ReportSummaryCardData(label: 'feeding_cost'.tr, value: 'Rs ${totals.value.feedingCost.toStringAsFixed(2)}'),
        ];
      case reportTypeMedical:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'medical_cost'.tr, value: 'Rs ${medicalTotal.toStringAsFixed(2)}'),
        ];
      case reportTypeLifecycle:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'lifecycle_events'.tr, value: '${totals.value.lifecycleEvents}'),
          ReportSummaryCardData(label: 'transfer_events'.tr, value: '${totals.value.lifecycleTransfer}'),
          ReportSummaryCardData(label: 'sold_events'.tr, value: '${totals.value.lifecycleSold}'),
          ReportSummaryCardData(label: 'death_events'.tr, value: '${totals.value.lifecycleDeath}'),
        ];
      case reportTypeMastitis:
        final mastitisCount = currentSections
            .where((section) => section.title == sectionMastitis)
            .fold<int>(0, (count, section) => count + section.rows.length);
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'mastitis'.tr, value: '$mastitisCount'),
        ];
      case reportTypeProfitLoss:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'debit'.tr, value: 'Rs ${profitDebit.toStringAsFixed(2)}'),
          ReportSummaryCardData(label: 'credit'.tr, value: 'Rs ${profitCredit.toStringAsFixed(2)}'),
          ReportSummaryCardData(
            label: profitNet >= 0 ? 'net_profit'.tr : 'net_loss'.tr,
            value: 'Rs ${profitNet.abs().toStringAsFixed(2)}',
          ),
        ];
      default:
        return <ReportSummaryCardData>[
          ReportSummaryCardData(label: 'milk_quantity'.tr, value: '${totals.value.milkQuantity.toStringAsFixed(2)} L'),
          ReportSummaryCardData(label: 'milk_earning'.tr, value: 'Rs ${totals.value.milkAmount.toStringAsFixed(2)}'),
          ReportSummaryCardData(label: 'feeding_quantity'.tr, value: '${totals.value.feedingQuantity.toStringAsFixed(2)} Kg'),
          ReportSummaryCardData(label: 'feeding_cost'.tr, value: 'Rs ${totals.value.feedingCost.toStringAsFixed(2)}'),
          ReportSummaryCardData(label: 'medical_cost'.tr, value: 'Rs ${medicalTotal.toStringAsFixed(2)}'),
          ReportSummaryCardData(
            label: 'profit_loss'.tr,
            value: 'Rs ${profitNet.toStringAsFixed(2)}',
          ),
        ];
    }
  }

  List<ReportSectionData> _filterSectionsByType(List<ReportSectionData> sections) {
    if (sections.isEmpty) return const <ReportSectionData>[];
    switch (reportType.value) {
      case reportTypeMilk:
        return sections.where((section) => section.title == sectionMilk).toList();
      case reportTypeFeeding:
        return sections.where((section) => section.title == sectionFeeding).toList();
      case reportTypeMedical:
        return sections.where((section) => section.title == sectionMedical).toList();
      case reportTypeLifecycle:
        return sections.where((section) => section.title == sectionLifecycle).toList();
      case reportTypeMastitis:
        return sections.where((section) => section.title == sectionMastitis).toList();
      case reportTypeProfitLoss:
        return sections.where((section) => section.title == sectionProfitLoss).toList();
      default:
        return sections;
    }
  }

  double _sumColumn(
    List<ReportSectionData> sections,
    String sectionTitle,
    String header,
  ) {
    final section = sections.firstWhereOrNull((item) => item.title == sectionTitle);
    if (section == null || section.rows.isEmpty) return 0;
    final index = section.headers.indexOf(header);
    if (index < 0) return 0;
    double total = 0;
    for (final row in section.rows) {
      if (index >= row.length) continue;
      total += _asDouble(row[index]);
    }
    return total;
  }

  Future<void> exportExcel() async {
    try {
      isExporting.value = true;
      final sections = _filterSectionsByType(await _buildDetailedSections());
      final hasAnyRow = sections.any((section) => section.rows.isNotEmpty);
      if (!hasAnyRow) {
        Get.snackbar('Info', 'no_report_data'.tr);
        return;
      }

      final buffer = StringBuffer();
      for (final section in sections) {
        buffer.writeln(_csv(section.title));
        buffer.writeln(section.headers.map(_csv).join(','));
        if (section.rows.isEmpty) {
          buffer.writeln(_csv('No records found'));
        } else {
          for (final row in section.rows) {
            buffer.writeln(row.map(_csv).join(','));
          }
        }
        buffer.writeln();
      }

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      await _exportFile(
        fileName:
            'farmer_report_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
        bytes: bytes,
      );
    } catch (error) {
      Get.snackbar('error'.tr, '${'download_failed'.tr}: $error');
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportPdf() async {
    try {
      isExporting.value = true;
      final sections = _filterSectionsByType(await _buildDetailedSections());
      final hasAnyRow = sections.any((section) => section.rows.isNotEmpty);
      if (!hasAnyRow) {
        Get.snackbar('Info', 'no_report_data'.tr);
        return;
      }

      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            final widgets = <pw.Widget>[
              pw.Text(
                'Farmer Detailed Report',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Range: ${fromDateController.text} to ${toDateController.text}'),
              pw.SizedBox(height: 10),
            ];

            for (final section in sections) {
              widgets.add(
                pw.Text(
                  section.title,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(
                pw.TableHelper.fromTextArray(
                  headers: section.headers,
                  data: section.rows.isEmpty ? <List<String>>[['No records found']] : section.rows,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
                  cellStyle: const pw.TextStyle(fontSize: 7.2),
                  cellAlignment: pw.Alignment.centerLeft,
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
            }
            return widgets;
          },
        ),
      );

      await _exportFile(
        fileName:
            'farmer_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        mimeType: 'application/pdf',
        bytes: await document.save(),
      );
    } catch (error) {
      Get.snackbar('error'.tr, '${'download_failed'.tr}: $error');
    } finally {
      isExporting.value = false;
    }
  }

  Future<List<ReportSectionData>> _buildDetailedSections() async {
    if (farmerId <= 0) return const <ReportSectionData>[];
    final rangeStart =
        _parseDisplayDate(fromDateController.text.trim()) ?? DateTime.now();
    final rangeEnd =
        _parseDisplayDate(toDateController.text.trim()) ?? DateTime.now();
    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end =
        DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59);

    final result = await Future.wait<List<Map<String, dynamic>>>([
      _fetchListFromApi(
        '${Api.animalList}/$farmerId',
        query: const {'include_inactive': '1'},
      ),
      _fetchListFromApi('${Api.milkList}/$farmerId'),
      _fetchListFromApi('${Api.feedingList}/$farmerId'),
      _fetchListFromApi('${Api.animalHistory}/$farmerId'),
      _fetchListFromApi('${Api.doctorAppointmentsByFarmer}/$farmerId'),
      _fetchListFromApi('${Api.pregnancyList}/$farmerId'),
      _fetchListFromApi('${Api.healthMastitis}/$farmerId'),
    ]);

    final animals = result[0];
    final milkRowsRaw = result[1];
    final feedingRowsRaw = result[2];
    final lifecycleRowsRaw = result[3];
    final appointmentsRaw = result[4];
    final pregnancyRowsRaw = result[5];
    final mastitisRowsRaw = result[6];

    final animalLookup = <int, _AnimalExportInfo>{};
    for (final item in animals) {
      final id = _asInt(item['id']);
      if (id <= 0) continue;
      animalLookup[id] = _AnimalExportInfo(
        id: id,
        panId: _asInt(item['pan_id']),
        panName: _asText(item['pan_name']),
        animalName: _asText(item['animal_name']),
        tagNumber: _asText(item['tag_number']),
        uniqueId: _asText(
          item['unique_id'],
          fallback: _asText(item['animal_unique_id'], fallback: '-'),
        ),
        birthDate: _asText(item['birth_date']),
        purchaseDate: _asText(item['purchase_date']),
        animalType: _asText(item['animal_type_name']),
        lactationNumber: _asText(item['lactation_number']),
        aiDate: _asText(item['ai_date']),
        breedName: _asText(item['breed_name']),
        gender: _asText(item['gender']),
        ageDisplay: _asText(item['age_display'], fallback: _asText(item['age'])),
        weight: _asText(item['weight']),
      );
    }

    final milkRows = <List<String>>[];
    for (final item in milkRowsRaw) {
      final date = _parseAnyDate(item['date']);
      if (!_isWithinRange(date, start, end)) continue;
      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final rate = _asDouble(item['rate']);
      final fat = _asText(item['fat']);
      final snf = _asText(item['snf']);
      final dairyName = _asText(item['dairy_name']);
      final shiftRows = <MapEntry<String, double>>[
        MapEntry('Morning', _asDouble(item['morning_milk'])),
        MapEntry('Afternoon', _asDouble(item['afternoon_milk'])),
        MapEntry('Evening', _asDouble(item['evening_milk'])),
      ].where((row) => row.value > 0).toList();

      if (shiftRows.isEmpty) {
        final qty = _asDouble(item['total_milk']);
        if (qty <= 0) continue;
        milkRows.add([
          _displayDate(date),
          animal?.panName ?? '-',
          animal?.animalName ?? _asText(item['animal_name']),
          animal?.tagNumber ?? _asText(item['tag_number']),
          _resolveAnimalUniqueId(animal, item, animalId),
          '-',
          _format2(qty),
          fat,
          snf,
          dairyName,
          _format2(rate),
          _format2(rate > 0 ? qty * rate : qty),
        ]);
        continue;
      }

      for (final shiftRow in shiftRows) {
        milkRows.add([
          _displayDate(date),
          animal?.panName ?? '-',
          animal?.animalName ?? _asText(item['animal_name']),
          animal?.tagNumber ?? _asText(item['tag_number']),
          _resolveAnimalUniqueId(animal, item, animalId),
          shiftRow.key,
          _format2(shiftRow.value),
          fat,
          snf,
          dairyName,
          _format2(rate),
          _format2(rate > 0 ? shiftRow.value * rate : shiftRow.value),
        ]);
      }
    }

    final debitByDateAnimal = <String, _ProfitAccumulator>{};
    final feedingRows = <List<String>>[];
    for (final item in feedingRowsRaw) {
      final date = _parseAnyDate(item['date']);
      if (!_isWithinRange(date, start, end)) continue;
      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final ratePerUnit = _asDouble(item['rate_per_unit']);
      var feedingCost = _asDouble(item['feeding_cost']);
      if (feedingCost <= 0 && ratePerUnit > 0) {
        feedingCost = _asDouble(item['feeding_quantity']) * ratePerUnit;
      }
      if (feedingCost > 0) {
        final key = '${_dateKey(date)}|$animalId';
        debitByDateAnimal.putIfAbsent(key, _ProfitAccumulator.new).debit +=
            feedingCost;
      }
      feedingRows.add([
        _displayDate(date),
        animal?.panName ?? '-',
        animal?.animalName ?? _asText(item['animal_name']),
        animal?.tagNumber ?? _asText(item['tag_number']),
        _resolveAnimalUniqueId(animal, item, animalId),
        _asText(item['feeding_time']),
        _asText(item['diet_plan_name'], fallback: _asText(item['feed_type'])),
        _format2(_asDouble(item['feeding_quantity']) > 0 ? _asDouble(item['feeding_quantity']) : _asDouble(item['quantity'])),
        _format2(ratePerUnit),
        _format2(feedingCost),
      ]);
    }

    final medicalRows = <List<String>>[];
    for (final item in appointmentsRaw) {
      final status = _asText(item['status']).toLowerCase();
      if (!(status == 'completed' ||
          status == 'approved' ||
          status == 'in_progress')) {
        continue;
      }
      final date = _parseAnyDate(item['completed_at']) ??
          _parseAnyDate(item['accepted_at']) ??
          _parseAnyDate(item['requested_at']);
      if (!_isWithinRange(date, start, end)) continue;

      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final fees = _asDouble(item['fees']);
      final onSiteMedicine = _asDouble(item['on_site_medicine_charges']);
      final total = _asDouble(item['charges']) > 0
          ? _asDouble(item['charges'])
          : (fees + onSiteMedicine);

      final key = '${_dateKey(date)}|$animalId';
      debitByDateAnimal.putIfAbsent(key, _ProfitAccumulator.new).debit += total;

      medicalRows.add([
        _displayDate(date),
        animal?.panName ?? '-',
        animal?.animalName ?? _asText(item['animal_name']),
        animal?.tagNumber ?? '-',
        _resolveAnimalUniqueId(animal, item, animalId),
        _asText(item['disease_details'], fallback: _asText(item['concern'])),
        _asText(item['treatment_details']),
        _asText(item['onsite_treatment']),
        _asText(item['doctor_name']),
        _format2(fees),
        _format2(onSiteMedicine),
        _format2(total),
      ]);
    }

    final lifecycleRows = <List<String>>[];
    for (final item in lifecycleRowsRaw) {
      final date = _parseAnyDate(item['changed_at']);
      if (!_isWithinRange(date, start, end)) continue;
      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final type = _asText(
        item['to_status'],
        fallback: _asText(item['action_type']),
      );
      lifecycleRows.add([
        _displayDate(date),
        _asText(
          item['to_pan'],
          fallback: _asText(item['from_pan'], fallback: animal?.panName ?? '-'),
        ),
        animal?.animalName ?? _asText(item['animal_name']),
        animal?.tagNumber ?? _asText(item['tag_number']),
        _resolveAnimalUniqueId(animal, item, animalId),
        type,
        animal?.birthDate ?? '-',
        animal?.purchaseDate ?? '-',
        animal?.animalType ?? '-',
        animal?.lactationNumber ?? '-',
        animal?.aiDate ?? '-',
        animal?.breedName ?? '-',
        animal?.gender ?? '-',
        animal?.ageDisplay ?? '-',
        animal?.weight ?? '-',
      ]);
    }

    final pregnancyRows = <List<String>>[];
    for (final item in pregnancyRowsRaw) {
      final status = _asText(item['status'], fallback: '').toLowerCase();
      if (status != 'pregnant' && status != 'not_pregnant') {
        continue;
      }

      final reportDate = _parseAnyDate(item['pregnancy_check_date']) ??
          _parseAnyDate(item['ai_date']);
      if (!_isWithinRange(reportDate, start, end)) continue;

      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final remainingDaysRaw = (item['remaining_days'] ?? '').toString().trim();
      final remainingDays = remainingDaysRaw.isEmpty ? '-' : '$remainingDaysRaw days';

      pregnancyRows.add([
        _displayDate(reportDate),
        animal?.panName ?? '-',
        animal?.animalName ?? _asText(item['animal_name']),
        animal?.tagNumber ?? _asText(item['tag_number']),
        _resolveAnimalUniqueId(animal, item, animalId),
        _asText(item['ai_date']),
        _asText(item['pregnancy_check_date']),
        _asText(item['expected_calving_date']),
        remainingDays,
        _asText(item['doctor_name']),
        _asText(item['status']),
      ]);
    }

    final mastitisRows = <List<String>>[];
    for (final item in mastitisRowsRaw) {
      final date = _parseAnyDate(item['date']);
      if (!_isWithinRange(date, start, end)) continue;

      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      mastitisRows.add([
        _displayDate(date),
        animal?.panName ?? '-',
        animal?.animalName ?? _asText(item['animal_name']),
        animal?.tagNumber ?? _asText(item['tag_number']),
        _resolveAnimalUniqueId(animal, item, animalId),
        _asText(item['test_result']),
        _asText(item['treatment']),
        _asText(item['recovery_status']),
      ]);
    }

    final creditByDateAnimal = <String, _ProfitAccumulator>{};
    for (final item in milkRowsRaw) {
      final date = _parseAnyDate(item['date']);
      if (!_isWithinRange(date, start, end)) continue;
      final animalId = _asInt(item['animal_id']);
      final animal = animalLookup[animalId];
      final panId = animal?.panId ?? 0;
      if (!_matchesScope(animalId: animalId, panId: panId)) continue;

      final amount = _asDouble(item['total_milk']) * _asDouble(item['rate']);
      final key = '${_dateKey(date)}|$animalId';
      creditByDateAnimal.putIfAbsent(key, _ProfitAccumulator.new).credit += amount;
    }

    final profitRows = <List<String>>[];
    final allProfitKeys = <String>{
      ...creditByDateAnimal.keys,
      ...debitByDateAnimal.keys,
    };
    final sortedProfitKeys = allProfitKeys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in sortedProfitKeys) {
      final segments = key.split('|');
      if (segments.length != 2) continue;
      final date = _parseAnyDate(segments[0]);
      final animalId = int.tryParse(segments[1]) ?? 0;
      final animal = animalLookup[animalId];
      final debit = debitByDateAnimal[key]?.debit ?? 0;
      final credit = creditByDateAnimal[key]?.credit ?? 0;
      profitRows.add([
        _displayDate(date),
        animal?.panName ?? '-',
        animal?.animalName ?? '-',
        animal?.tagNumber ?? '-',
        _resolveAnimalUniqueId(animal, const <String, dynamic>{}, animalId),
        _format2(debit),
        _format2(credit),
        _format2(credit - debit),
      ]);
    }

    return <ReportSectionData>[
      ReportSectionData(
        title: sectionMilk,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Milk Shift',
          'Milk Quantity',
          'Fat',
          'SNF',
          'Dairy Name',
          'Rate',
          'Total',
        ],
        rows: milkRows,
      ),
      ReportSectionData(
        title: sectionFeeding,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Feeding Shift',
          'Diet/Feed Name',
          'Quantity',
          'Rate / Unit',
          'Feeding Cost',
        ],
        rows: feedingRows,
      ),
      ReportSectionData(
        title: sectionMedical,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Disease',
          'Medicine Treatment',
          'On Site Treatment',
          'Dr Name',
          'Fees',
          'on Site Medicine Charge',
          'Total',
        ],
        rows: medicalRows,
      ),
      ReportSectionData(
        title: sectionLifecycle,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Life Cycal Type',
          'Birth Date',
          'Purchase Date',
          'Animal Type',
          'Lactation Number',
          'AI Date',
          'Breed Name',
          'Gender',
          'Age',
          'Weight',
        ],
        rows: lifecycleRows,
      ),
      ReportSectionData(
        title: sectionPregnancy,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'AI Date',
          'Pregnancy Check Date',
          'Expected Calving Date',
          'Remaining Days',
          'Doctor Name',
          'Status',
        ],
        rows: pregnancyRows,
      ),
      ReportSectionData(
        title: sectionMastitis,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Test Result',
          'Treatment',
          'Recovery Status',
        ],
        rows: mastitisRows,
      ),
      ReportSectionData(
        title: sectionProfitLoss,
        headers: const [
          'Date',
          'Pen Name',
          'Cow Name',
          'Cow Tag No',
          'Id',
          'Debit',
          'Credit',
          'Total',
        ],
        rows: profitRows,
      ),
    ];
  }

  Future<List<Map<String, dynamic>>> _fetchListFromApi(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    try {
      final uri = Uri.parse(endpoint).replace(queryParameters: query);
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (response.statusCode != 200 || body is! Map || body['status'] != true) {
        return const <Map<String, dynamic>>[];
      }
      final data = body['data'];
      if (data is! List) {
        return const <Map<String, dynamic>>[];
      }
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  bool _matchesScope({required int animalId, required int panId}) {
    final selected = selectedTargetId.value;
    if (scope.value == 'pan') {
      if (selected == null || selected <= 0) return true;
      return panId > 0 && panId == selected;
    }
    if (selected == null || selected <= 0) return true;
    return animalId > 0 && animalId == selected;
  }

  bool _isWithinRange(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime? _parseAnyDate(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;

    const patterns = <String>[
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy HH:mm',
      'd-M-yyyy H:mm',
      'dd-MM-yyyy',
      'd-M-yyyy',
      'yyyy-MM-dd HH:mm:ss',
    ];
    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parse(value);
      } catch (_) {}
    }
    return null;
  }

  String _dateKey(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _displayDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _resolveAnimalUniqueId(
    _AnimalExportInfo? animal,
    Map<String, dynamic> row,
    int animalId,
  ) {
    final fromAnimal = (animal?.uniqueId ?? '').trim();
    if (fromAnimal.isNotEmpty && fromAnimal != '-') return fromAnimal;
    final fromRowUnique = _asText(
      row['unique_id'],
      fallback: _asText(row['animal_unique_id'], fallback: ''),
    );
    if (fromRowUnique.isNotEmpty && fromRowUnique != '-') return fromRowUnique;
    return animalId > 0 ? '$animalId' : '-';
  }

  String _asText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString().trim()) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().trim()) ?? 0;
  }

  String _format2(double value) => value.toStringAsFixed(2);

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> _exportFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    if (Platform.isAndroid) {
      try {
        final savedPath = await _exportChannel.invokeMethod<String>(
          'exportToPickedFolder',
          <String, dynamic>{
            'fileName': fileName,
            'mimeType': mimeType,
            'bytes': Uint8List.fromList(bytes),
          },
        );
        if (savedPath == null || savedPath.trim().isEmpty) {
          Get.snackbar('Info', 'folder_selection_cancelled'.tr);
          return;
        }
        Get.snackbar('Success', '${'report_saved_to'.tr}: $savedPath');
        return;
      } on PlatformException catch (error) {
        if (error.code == 'CANCELLED') {
          Get.snackbar('Info', 'folder_selection_cancelled'.tr);
        } else {
          Get.snackbar(
            'error'.tr,
            '${'download_failed'.tr}: ${error.message ?? error.code}',
          );
        }
        return;
      }
    }

    final file = await _createReportBytesFile(fileName: fileName, bytes: bytes);
    Get.snackbar('Success', '${'report_saved_to'.tr}: ${file.path}');
  }

  Future<File> _createReportBytesFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final dir = await _reportsDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Directory> _reportsDirectory() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final reportsDir = Directory(
      '${base.path}${Platform.pathSeparator}DairyReports',
    );
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    return reportsDir;
  }

  String _apiDate(String display) {
    final parsed = _parseDisplayDate(display) ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  DateTime? _parseDisplayDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.onClose();
  }
}

class ReportTargetOption {
  final int id;
  final String label;

  const ReportTargetOption({required this.id, required this.label});
}

class LivestockReportRow {
  final String date;
  final String targetName;
  final double milkQuantity;
  final double milkAmount;
  final double feedingQuantity;
  final double feedingCost;
  final int lifecycleEvents;
  final int lifecycleTransfer;
  final int lifecycleSold;
  final int lifecycleDeath;

  const LivestockReportRow({
    required this.date,
    required this.targetName,
    required this.milkQuantity,
    required this.milkAmount,
    required this.feedingQuantity,
    required this.feedingCost,
    required this.lifecycleEvents,
    required this.lifecycleTransfer,
    required this.lifecycleSold,
    required this.lifecycleDeath,
  });

  factory LivestockReportRow.fromJson(Map<String, dynamic> json) {
    return LivestockReportRow(
      date: (json['date'] ?? '-').toString(),
      targetName: (json['target_name'] ?? '-').toString(),
      milkQuantity: _toDouble(json['milk_quantity']),
      milkAmount: _toDouble(json['milk_amount']),
      feedingQuantity: _toDouble(json['feeding_quantity']),
      feedingCost: _toDouble(json['feeding_cost']),
      lifecycleEvents: int.tryParse((json['lifecycle_events'] ?? '').toString()) ?? 0,
      lifecycleTransfer: int.tryParse((json['lifecycle_transfer'] ?? '').toString()) ?? 0,
      lifecycleSold: int.tryParse((json['lifecycle_sold'] ?? '').toString()) ?? 0,
      lifecycleDeath: int.tryParse((json['lifecycle_death'] ?? '').toString()) ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class LivestockReportTotals {
  final double milkQuantity;
  final double milkAmount;
  final double feedingQuantity;
  final double feedingCost;
  final int lifecycleEvents;
  final int lifecycleTransfer;
  final int lifecycleSold;
  final int lifecycleDeath;

  const LivestockReportTotals({
    required this.milkQuantity,
    required this.milkAmount,
    required this.feedingQuantity,
    required this.feedingCost,
    required this.lifecycleEvents,
    required this.lifecycleTransfer,
    required this.lifecycleSold,
    required this.lifecycleDeath,
  });

  factory LivestockReportTotals.fromJson(Map<String, dynamic> json) {
    return LivestockReportTotals(
      milkQuantity: _toDouble(json['milk_quantity']),
      milkAmount: _toDouble(json['milk_amount']),
      feedingQuantity: _toDouble(json['feeding_quantity']),
      feedingCost: _toDouble(json['feeding_cost']),
      lifecycleEvents: int.tryParse((json['lifecycle_events'] ?? '').toString()) ?? 0,
      lifecycleTransfer: int.tryParse((json['lifecycle_transfer'] ?? '').toString()) ?? 0,
      lifecycleSold: int.tryParse((json['lifecycle_sold'] ?? '').toString()) ?? 0,
      lifecycleDeath: int.tryParse((json['lifecycle_death'] ?? '').toString()) ?? 0,
    );
  }

  factory LivestockReportTotals.zero() {
    return const LivestockReportTotals(
      milkQuantity: 0,
      milkAmount: 0,
      feedingQuantity: 0,
      feedingCost: 0,
      lifecycleEvents: 0,
      lifecycleTransfer: 0,
      lifecycleSold: 0,
      lifecycleDeath: 0,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class ReportSectionData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const ReportSectionData({
    required this.title,
    required this.headers,
    required this.rows,
  });
}

class ReportSummaryCardData {
  final String label;
  final String value;

  const ReportSummaryCardData({
    required this.label,
    required this.value,
  });
}

class _AnimalExportInfo {
  final int id;
  final int panId;
  final String panName;
  final String animalName;
  final String tagNumber;
  final String uniqueId;
  final String birthDate;
  final String purchaseDate;
  final String animalType;
  final String lactationNumber;
  final String aiDate;
  final String breedName;
  final String gender;
  final String ageDisplay;
  final String weight;

  const _AnimalExportInfo({
    required this.id,
    required this.panId,
    required this.panName,
    required this.animalName,
    required this.tagNumber,
    required this.uniqueId,
    required this.birthDate,
    required this.purchaseDate,
    required this.animalType,
    required this.lactationNumber,
    required this.aiDate,
    required this.breedName,
    required this.gender,
    required this.ageDisplay,
    required this.weight,
  });
}

class _ProfitAccumulator {
  double debit;
  double credit;

  _ProfitAccumulator({
    this.debit = 0,
    this.credit = 0,
  });
}
