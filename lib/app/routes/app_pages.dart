// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../core/widget/bottom_navigation_bar.dart';
import '../modules/animal/bindings/animal_binding.dart';
import '../modules/animal/views/animal_view.dart';
import '../modules/animal_history/bindings/animal_history_binding.dart';
import '../modules/animal_history/views/animal_history_view.dart';
import '../modules/manage_animal/bindings/manage_animal_binding.dart';
import '../modules/manage_animal/views/manage_animal_view.dart';
import '../modules/manage_pregnancy/bindings/manage_pregnancy_binding.dart';
import '../modules/manage_pregnancy/views/manage_pregnancy_view.dart';
import '../modules/dairy/bindings/dairy_binding.dart';
import '../modules/dairy/views/dairy_view.dart';
import '../modules/doctor/bindings/doctor_binding.dart';
import '../modules/doctor/views/doctor_appointments_nearby_view.dart';
import '../modules/farmer_details/bindings/farmer_details_binding.dart';
import '../modules/farmer_details/views/farmer_details_view.dart';
import '../modules/feeding/bindings/feeding_binding.dart';
import '../modules/feeding/views/feeding_view.dart';
import '../modules/health/bindings/health_binding.dart';
import '../modules/health/views/health_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/language/bindings/language_binding.dart';
import '../modules/language/views/language_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/login_otp/bindings/login_otp_binding.dart';
import '../modules/login_otp/views/login_otp_view.dart';
import '../modules/milk/bindings/milk_binding.dart';
import '../modules/milk/views/milk_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/payment/bindings/payment_binding.dart';
import '../modules/payment/views/payment_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/shop/bindings/shop_binding.dart';
import '../modules/shop/views/shop_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/upgrade/bindings/upgrade_binding.dart';
import '../modules/upgrade/views/upgrade_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: _Paths.SPLASH, page: () => SplashView(), binding: SplashBinding()),
    GetPage(name: _Paths.LOGIN, page: () => LoginView(), binding: LoginBinding()),
    GetPage(name: _Paths.ONBOARDING, page: () => OnboardingView(), binding: OnboardingBinding()),
    GetPage(name: _Paths.LOGIN_OTP, page: () => const LoginOtpView(), binding: LoginOtpBinding()),
    GetPage(name: _Paths.LANGUAGE, page: () => const LanguageView(), binding: LanguageBinding()),
    GetPage(name: _Paths.FARMER_DETAILS, page: () => const FarmerDetailsView(), binding: FarmerDetailsBinding()),
    GetPage(name: _Paths.HOME, page: () => const MainBottomNavView(), binding: HomeBinding()),
    GetPage(name: _Paths.ANIMAL, page: () => AnimalView(), binding: AnimalBinding()),
    GetPage(name: _Paths.MANAGE_ANIMAL, page: () => const ManageAnimalView(), binding: ManageAnimalBinding()),
    GetPage(name: _Paths.MANAGE_PREGNANCY, page: () => const ManagePregnancyView(), binding: ManagePregnancyBinding()),
    GetPage(name: _Paths.ANIMAL_HISTORY, page: () => const AnimalHistoryView(), binding: AnimalHistoryBinding()),
    GetPage(name: _Paths.MILK, page: () => const MilkView(), binding: MilkBinding()),
    GetPage(name: _Paths.FEEDING, page: () => const FeedingView(), binding: FeedingBinding()),
    GetPage(name: _Paths.HEALTH, page: () => const HealthView(), binding: HealthBinding()),
    GetPage(name: _Paths.DOCTOR, page: () => const DoctorAppointmentsNearbyView(), binding: DoctorBinding()),
    GetPage(name: _Paths.SHOP, page: () => const ShopView(), binding: ShopBinding()),
    GetPage(name: _Paths.PROFILE, page: () => const ProfileView(), binding: ProfileBinding()),
    GetPage(name: _Paths.PAYMENT, page: () => const PaymentView(), binding: PaymentBinding()),
    GetPage(name: _Paths.UPGRADE, page: () => const UpgradeView(), binding: UpgradeBinding()),
    GetPage(name: _Paths.DAIRY, page: () => const DairyView(), binding: DairyBinding()),
  ];
}

