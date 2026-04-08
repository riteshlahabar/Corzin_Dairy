import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/colors.dart';
import '../controllers/farmer_details_controller.dart';

class FarmerDetailsView extends GetView<FarmerDetailsController> {
  const FarmerDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: Column(
        children: [
          /// 🔰 HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            width: double.infinity,
            child: Text(
              "farmer_details".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// 📄 FORM CARD
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),

              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 👤 PERSONAL INFO
                    _sectionTitle("personal_info".tr),

                    _field(
                      "first_name".tr,
                      controller.firstName,
                      icon: Icons.person_outline,
                    ),

                    _field(
                      "middle_name".tr,
                      controller.middleName,
                      icon: Icons.person_outline,
                    ),

                    _field(
                      "last_name".tr,
                      controller.lastName,
                      icon: Icons.person_outline,
                    ),

                    /// 📍 LOCATION
                    _sectionTitle("location".tr),

                    _field(
                      "village".tr,
                      controller.village,
                      icon: Icons.home_outlined,
                    ),

                    _field(
                      "city".tr,
                      controller.city,
                      icon: Icons.location_city_outlined,
                    ),

                    _field(
                      "taluka".tr,
                      controller.taluka,
                      icon: Icons.map_outlined,
                    ),

                    _field("district".tr, controller.district, icon: Icons.map),

                    _field("state".tr, controller.state, icon: Icons.public),

                    _field(
                      "pincode".tr,
                      controller.pincode,
                      icon: Icons.pin_drop_outlined,
                      isNumber: true,
                    ),

                    const SizedBox(height: 30),

                    /// ✅ SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "submit".tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 SECTION TITLE
  Widget _sectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /// 🔹 INPUT FIELD
  Widget _field(
    String label,
    TextEditingController controller, {
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),

      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,

        style: const TextStyle(fontSize: 14),

        decoration: InputDecoration(
          hintText: label,

          prefixIcon: Icon(icon, color: AppColors.primary),

          filled: true,
          fillColor: Colors.grey.shade100,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
