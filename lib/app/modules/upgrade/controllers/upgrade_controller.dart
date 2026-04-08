import 'package:get/get.dart';

class UpgradeController extends GetxController {
  final RxList<PlanModel> plans = <PlanModel>[
    const PlanModel(
      name: 'free_plan',
      price: '₹0',
      features: ['limited_animals', 'limited_pans', 'basic_dashboard'],
      highlighted: false,
    ),
    const PlanModel(
      name: 'paid_plan',
      price: '₹999 / year',
      features: ['unlimited_animals', 'unlimited_pans', 'advanced_reports'],
      highlighted: true,
    ),
  ].obs;
}

class PlanModel {
  final String name;
  final String price;
  final List<String> features;
  final bool highlighted;

  const PlanModel({
    required this.name,
    required this.price,
    required this.features,
    required this.highlighted,
  });
}
