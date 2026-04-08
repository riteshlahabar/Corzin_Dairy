class Api {
  static const String baseUrl = "https://corzindm.turnkeyinfotech.live/api";

  static const String login = "$baseUrl/auth/login";
  static const String checkUser = "$baseUrl/auth/check-user";
  static const String farmerProfileByMobile = "$baseUrl/farmer/profile";

  static const String addFarmer = "$baseUrl/farmer/store";
  static const String farmerList = "$baseUrl/farmer";

  static const String addAnimal = "$baseUrl/animal/store";
  static const String animalList = "$baseUrl/animal/list";
  static const String animalTypes = "$baseUrl/animal/types";
  static const String animalLifecycle = "$baseUrl/animal/lifecycle";
  static const String animalHistory = "$baseUrl/animal/history";

  static const String addMilk = "$baseUrl/milk";
  static const String milkByAnimal = "$baseUrl/milk/animal";
  static const String milkDashboardSummary = "$baseUrl/milk/dashboard-summary";

  static const String addFeeding = "$baseUrl/feeding";
  static const String feedingTypes = "$baseUrl/feeding/types";
  static const String feedingList = "$baseUrl/feeding/list";
  static const String feedingSummary = "$baseUrl/feeding/summary";

  static const String healthMedical = "$baseUrl/health/medical";
  static const String healthMastitis = "$baseUrl/health/mastitis";
  static const String healthDmi = "$baseUrl/health/dmi";

  static const String reproductive = "$baseUrl/reproductive";

  static const String addDairy = "$baseUrl/dairy";
  static const String dairyList = "$baseUrl/dairy/list";
  static const String dairyPayments = "$baseUrl/dairy/payments";

  static const String dashboardSummary = "$baseUrl/dashboard/summary";
  static const String doctorList = "$baseUrl/doctor/list";
  static const String shopCategories = "$baseUrl/shop/categories";
  static const String shopProducts = "$baseUrl/shop/products";
  static const String subscriptionPlans = "$baseUrl/subscription/plans";
}
