part of '../controllers/health_controller.dart';

extension HealthMastitisFilterHelper on HealthMastitisController {
  List<MastitisRecordItem> get filteredMastitisRecords {
    final query = mastitisSearchQuery.value.trim().toLowerCase();
    final filter = mastitisResultFilter.value.trim().toLowerCase();

    return mastitisRecords.where((item) {
      final result = item.testResult.trim().toLowerCase();
      if (filter != 'all' && result != filter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        item.animalName,
        item.tagNumber,
        item.testResult,
        item.treatment,
        item.recoveryStatus,
        item.date,
        item.notes,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  List<MastitisGroupItem> get allMastitisGroups {
    final grouped = <int, List<MastitisRecordItem>>{};

    for (final item in mastitisRecords) {
      if (item.animalId <= 0) continue;

      final groupKey = item.caseId > 0 ? item.caseId : item.id;
      grouped.putIfAbsent(groupKey, () => <MastitisRecordItem>[]).add(item);
    }

    final groups = grouped.values.map((rows) {
      rows.sort((a, b) {
        final dateCompare =
            _parseHealthMastitisDate(b.date).compareTo(_parseHealthMastitisDate(a.date));
        if (dateCompare != 0) return dateCompare;
        return b.id.compareTo(a.id);
      });

      return MastitisGroupItem(records: rows);
    }).toList();

    groups.sort((a, b) {
      final dateCompare = _parseHealthMastitisDate(b.latestDate)
          .compareTo(_parseHealthMastitisDate(a.latestDate));
      if (dateCompare != 0) return dateCompare;
      return b.caseId.compareTo(a.caseId);
    });

    return groups;
  }

  List<MastitisGroupItem> get filteredMastitisGroups {
    final query = mastitisSearchQuery.value.trim().toLowerCase();
    final filter = mastitisResultFilter.value.trim().toLowerCase();
    final from = mastitisFromDate.value == null
        ? null
        : DateTime(
            mastitisFromDate.value!.year,
            mastitisFromDate.value!.month,
            mastitisFromDate.value!.day,
          );
    final to = mastitisToDate.value == null
        ? null
        : DateTime(
            mastitisToDate.value!.year,
            mastitisToDate.value!.month,
            mastitisToDate.value!.day,
          );

    return allMastitisGroups.where((group) {
      if (filter != 'all' && group.effectiveTestResult != filter) {
        return false;
      }

      if (from != null || to != null) {
        final hasDateInRange = group.records.any((row) {
          final parsed = _parseHealthMastitisDate(row.date);
          final rowDate = DateTime(parsed.year, parsed.month, parsed.day);
          if (from != null && rowDate.isBefore(from)) {
            return false;
          }
          if (to != null && rowDate.isAfter(to)) {
            return false;
          }
          return true;
        });

        if (!hasDateInRange) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return group.searchText.contains(query);
    }).toList();
  }

  void setMastitisDateRange({DateTime? from, DateTime? to}) {
    var nextFrom = from ?? mastitisFromDate.value;
    var nextTo = to ?? mastitisToDate.value;

    if (nextFrom != null) {
      nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    }
    if (nextTo != null) {
      nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);
    }

    if (nextFrom != null && nextTo != null && nextFrom.isAfter(nextTo)) {
      if (from != null) {
        nextTo = nextFrom;
      } else {
        nextFrom = nextTo;
      }
    }

    mastitisFromDate.value = nextFrom;
    mastitisToDate.value = nextTo;
  }

  List<HealthAnimalItem> get milkingAnimals {
    return animals.where((animal) => animal.isMilkingCow).toList();
  }

  Set<int> get activeMastitisAnimalIds {
    return allMastitisGroups
        .where(
          (group) =>
              group.effectiveTestResult == 'positive' &&
              group.recoveryStatus != 'recovered' &&
              group.recoveryStatus != 'recoverd',
        )
        .map((group) => group.animalId)
        .where((animalId) => animalId > 0)
        .toSet();
  }

  List<HealthAnimalItem> get availableMastitisAnimals {
    final activeIds = activeMastitisAnimalIds;
    final seenIds = <int>{};
    return milkingAnimals
        .where((animal) => animal.id > 0 && !activeIds.contains(animal.id))
        .where((animal) => seenIds.add(animal.id))
        .toList();
  }
}

extension HealthVaccinationFilterHelper on HealthVaccinationController {
  List<VaccinationRecordItem> get filteredVaccinationRecords {
    final query = vaccinationSearchQuery.value.trim().toLowerCase();
    final from = DateTime(
      vaccinationFromDate.value.year,
      vaccinationFromDate.value.month,
      vaccinationFromDate.value.day,
    );
    final to = DateTime(
      vaccinationToDate.value.year,
      vaccinationToDate.value.month,
      vaccinationToDate.value.day,
    );

    return vaccinationRecords.where((item) {
      final parsedDate = _parseHealthDmiDate(item.date);
      if (parsedDate != null) {
        final rowDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        if (rowDate.isBefore(from) || rowDate.isAfter(to)) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return item.searchText.contains(query);
    }).toList();
  }

  List<VaccinationGroupItem> get filteredVaccinationGroups {
    final grouped = <int, List<VaccinationRecordItem>>{};

    for (final item in filteredVaccinationRecords) {
      final key = item.animalId > 0 ? item.animalId : item.id;
      grouped.putIfAbsent(key, () => <VaccinationRecordItem>[]).add(item);
    }

    final groups = grouped.values
        .map((rows) {
          rows.sort((a, b) {
            final dateCompare = _parseHealthMastitisDate(b.date).compareTo(_parseHealthMastitisDate(a.date));
            if (dateCompare != 0) return dateCompare;
            return b.id.compareTo(a.id);
          });
          return VaccinationGroupItem(records: rows);
        })
        .toList();

    groups.sort((a, b) {
      final dateCompare = _parseHealthMastitisDate(b.latestDate).compareTo(_parseHealthMastitisDate(a.latestDate));
      if (dateCompare != 0) return dateCompare;
      return a.animalName.toLowerCase().compareTo(b.animalName.toLowerCase());
    });

    return groups;
  }

  Future<void> setVaccinationDateRange({DateTime? from, DateTime? to}) async {
    var nextFrom = from ?? vaccinationFromDate.value;
    var nextTo = to ?? vaccinationToDate.value;

    nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);

    if (nextFrom.isAfter(nextTo)) {
      nextTo = nextFrom;
    }

    vaccinationFromDate.value = nextFrom;
    vaccinationToDate.value = nextTo;
  }
}

extension HealthReagentFilterHelper on HealthReagentController {
  List<ReagentUsageItem> get filteredReagentUsages {
    final query = reagentSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return reagentUsages.toList();
    }

    return reagentUsages.where((item) {
      return item.searchText.contains(query);
    }).toList();
  }
}

extension HealthDmiFilterHelper on HealthDmiController {
  List<DmiRecordItem> get filteredDmiRecords {
    final query = dmiSearchQuery.value.trim().toLowerCase();
    final selectedType = dmiAnimalTypeFilter.value.trim().toLowerCase();
    final from = DateTime(
      dmiFromDate.value.year,
      dmiFromDate.value.month,
      dmiFromDate.value.day,
    );
    final to = DateTime(
      dmiToDate.value.year,
      dmiToDate.value.month,
      dmiToDate.value.day,
    );

    return groupedDmiRecords.where((item) {
      if (selectedType != 'all' && !item.matchesAnimalTypeFilter(selectedType)) {
        return false;
      }

      final parsedDate = _parseHealthDmiDate(item.date);
      if (parsedDate != null) {
        final rowDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
        if (rowDate.isBefore(from) || rowDate.isAfter(to)) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return item.searchText.contains(query);
    }).toList();
  }

  List<DmiRecordItem> get groupedDmiRecords {
    if (dmiRecords.isEmpty) {
      return const <DmiRecordItem>[];
    }

    final animalById = <int, HealthAnimalItem>{
      for (final animal in animals)
        if (animal.id > 0) animal.id: animal,
    };
    final grouped = <String, List<DmiRecordItem>>{};

    for (final item in dmiRecords) {
      final animal = animalById[item.animalId];
      final resolvedPanId = animal?.panId ?? item.panId;
      final resolvedPanName = animal?.panName.trim().isNotEmpty == true
          ? animal!.panName.trim()
          : item.panName.trim();
      final key = resolvedPanId > 0
          ? 'pan_${resolvedPanId}_${item.date}'
          : 'animal_${item.animalId}_${item.date}';

      grouped.putIfAbsent(key, () => <DmiRecordItem>[]).add(
        item.copyWith(
          panId: resolvedPanId,
          panName: resolvedPanName,
          animalTypeNames: item.animalTypeNames.isEmpty
              ? <String>[item.animalTypeName]
              : item.animalTypeNames,
          searchAliases: item.searchAliases.isEmpty
              ? <String>[
                  item.animalName,
                  item.tagNumber,
                  item.animalTypeName,
                  resolvedPanName,
                ]
              : item.searchAliases,
        ),
      );
    }

    final results = grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;
      if (!first.isPanGroup) {
        return first.copyWith(
          animalCount: first.animalCount > 0 ? first.animalCount : 1,
        );
      }

      final panName = first.panName.trim().isNotEmpty
          ? first.panName.trim()
          : 'PAN #${first.panId}';
      final animalIds = rows
          .map((row) => row.animalId)
          .where((id) => id > 0)
          .toSet();
      final typeNames = rows
          .expand(
            (row) => row.animalTypeNames.isEmpty
                ? <String>[row.animalTypeName]
                : row.animalTypeNames,
          )
          .map((type) => type.trim())
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final aliases = rows
          .expand((row) => <String>[
                row.animalName,
                row.tagNumber,
                ...row.searchAliases,
              ])
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty && text != '-')
          .toSet()
          .toList();
      final bodyWeight = rows.fold<double>(0, (sum, row) => sum + row.bodyWeightValue);
      final totalMilk = rows.fold<double>(0, (sum, row) => sum + row.totalMilkValue);
      final requiredDmi = rows.fold<double>(0, (sum, row) => sum + row.requiredDmiValue);
      final actualDmi = rows.fold<double>(0, (sum, row) => sum + row.actualDmiValue);
      final difference = double.parse((actualDmi - requiredDmi).toStringAsFixed(2));
      final alertStatus = difference.abs() <= 1.0
          ? 'Balanced'
          : (difference < 0 ? 'Low' : 'High');
      final notes = rows
          .map((row) => row.notes.trim())
          .where((note) => note.isNotEmpty)
          .toSet()
          .join(' | ');

      return DmiRecordItem(
        animalId: 0,
        animalName: panName,
        tagNumber: 'PAN',
        animalTypeName: typeNames.length == 1 ? typeNames.first : 'Mixed',
        dmiType: 'Pan Wise',
        bodyWeight: bodyWeight.toStringAsFixed(2),
        totalMilk: totalMilk.toStringAsFixed(2),
        requiredDmi: requiredDmi.toStringAsFixed(2),
        actualDmi: actualDmi.toStringAsFixed(2),
        alertStatus: alertStatus,
        date: first.date,
        notes: notes,
        panId: first.panId,
        panName: panName,
        animalCount: animalIds.isEmpty ? rows.length : animalIds.length,
        animalTypeNames: typeNames,
        searchAliases: aliases,
      );
    }).toList();

    results.sort((a, b) {
      final aDate = _parseHealthDmiDate(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parseHealthDmiDate(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateCompare = bDate.compareTo(aDate);
      if (dateCompare != 0) return dateCompare;
      return a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
    });

    return results;
  }

  List<String> get dmiAnimalTypes {
    final types = groupedDmiRecords
        .expand((item) => item.animalTypeNames)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty && type != '-')
        .toSet()
        .toList();
    types.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return types;
  }

  Future<void> setDmiDateRange({DateTime? from, DateTime? to}) async {
    var nextFrom = from ?? dmiFromDate.value;
    var nextTo = to ?? dmiToDate.value;

    nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);

    if (nextFrom.isAfter(nextTo)) {
      nextTo = nextFrom;
    }

    dmiFromDate.value = nextFrom;
    dmiToDate.value = nextTo;
    await fetchDmiRecords();
  }

}

DateTime? _parseHealthDmiDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  try {
    return DateFormat('dd/MM/yyyy').parseStrict(text);
  } catch (_) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (_) {
      return null;
    }
  }
}

DateTime _parseHealthMastitisDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  try {
    return DateFormat('dd/MM/yyyy').parseStrict(text);
  } catch (_) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
