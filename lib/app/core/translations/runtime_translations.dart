import 'package:get/get.dart';

import 'translations.dart';

class RuntimeTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => TranslationRegistry.keys;
}
