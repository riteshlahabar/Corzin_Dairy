// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const SPLASH = _Paths.SPLASH;
  static const LOGIN = _Paths.LOGIN;
  static const ONBOARDING = _Paths.ONBOARDING;
  static const LOGIN_OTP = _Paths.LOGIN_OTP;
  static const LANGUAGE = _Paths.LANGUAGE;
  static const FARMER_DETAILS = _Paths.FARMER_DETAILS;
  static const HOME = _Paths.HOME;
  static const ANIMAL = _Paths.ANIMAL;
  static const MANAGE_ANIMAL = _Paths.MANAGE_ANIMAL;
  static const ANIMAL_HISTORY = _Paths.ANIMAL_HISTORY;
  static const MILK = _Paths.MILK;
  static const FEEDING = _Paths.FEEDING;
  static const FEED_SETTINGS = _Paths.FEED_SETTINGS;
  static const FEED_SETTINGS_LIST = _Paths.FEED_SETTINGS_LIST;
  static const DIET_PLAN = _Paths.DIET_PLAN;
  static const DIET_PLAN_LIST = _Paths.DIET_PLAN_LIST;
  static const HEALTH = _Paths.HEALTH;
  static const DOCTOR = _Paths.DOCTOR;
  static const SHOP = _Paths.SHOP;
  static const PROFILE = _Paths.PROFILE;
  static const PAYMENT = _Paths.PAYMENT;
  static const UPGRADE = _Paths.UPGRADE;
  static const DAIRY = _Paths.DAIRY;
  static const DAIRY_LIST = _Paths.DAIRY_LIST;
}

abstract class _Paths {
  _Paths._();

  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const ONBOARDING = '/onboarding';
  static const LOGIN_OTP = '/login-otp';
  static const LANGUAGE = '/language';
  static const FARMER_DETAILS = '/farmer-details';
  static const HOME = '/home';
  static const ANIMAL = '/animal';
  static const MANAGE_ANIMAL = '/manage-animal';
  static const ANIMAL_HISTORY = '/animal-history';
  static const MILK = '/milk';
  static const FEEDING = '/feeding';
  static const FEED_SETTINGS = '/feed-settings';
  static const FEED_SETTINGS_LIST = '/feed-settings-list';
  static const DIET_PLAN = '/diet-plan';
  static const DIET_PLAN_LIST = '/diet-plan-list';
  static const HEALTH = '/health';
  static const DOCTOR = '/doctor';
  static const SHOP = '/shop';
  static const PROFILE = '/profile';
  static const PAYMENT = '/payment';
  static const UPGRADE = '/upgrade';
  static const DAIRY = '/dairy';
  static const DAIRY_LIST = '/dairy-list';
}
