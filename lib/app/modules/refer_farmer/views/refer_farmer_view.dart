import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/session_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/api.dart';
import '../../../core/widget/bottom_navigation_bar.dart';

class ReferFarmerView extends StatefulWidget {
  const ReferFarmerView({super.key});

  @override
  State<ReferFarmerView> createState() => _ReferFarmerViewState();
}

class _ReferFarmerViewState extends State<ReferFarmerView> {
  late final Future<_ReferralDetails> _detailsFuture = _loadReferralDetails();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'refer_to_farmer'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_ReferralDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final details = snapshot.data ?? const _ReferralDetails.empty();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroCard(),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else ...[
                  _referralCard(
                    title: 'referral_code_label'.tr,
                    value: details.code.isEmpty ? '-' : details.code,
                    actionLabel: 'copy_referral_code'.tr,
                    onTap: details.code.isEmpty ? null : () => _copy(details.code),
                  ),
                  const SizedBox(height: 12),
                  _referralCard(
                    title: 'referral_link_label'.tr,
                    value: details.link.isEmpty ? '-' : details.link,
                    actionLabel: 'copy_referral_link'.tr,
                    onTap: details.link.isEmpty ? null : () => _copy(details.link),
                    isMultiline: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E9E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            details.link.isEmpty
                                ? 'referral_details_unavailable'.tr
                                : 'refer_farmer_desc'.tr,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF5FBF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E9D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'refer_farmer_title'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'refer_farmer_desc'.tr,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referralCard({
    required String title,
    required String value,
    required String actionLabel,
    required VoidCallback? onTap,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E9E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: isMultiline ? 13.2 : 19,
              height: isMultiline ? 1.45 : 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(actionLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFCDE1CD)),
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<_ReferralDetails> _loadReferralDetails() async {
    final mobile = await SessionService.getMobile();
    if (mobile.trim().isEmpty) {
      return const _ReferralDetails.empty();
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: const {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
        return const _ReferralDetails.empty();
      }

      final farmer = Map<String, dynamic>.from(data['data']);
      final code = (farmer['referral_code'] ?? '').toString().trim().toUpperCase();
      final backendLink = (farmer['referral_link'] ?? '').toString().trim();
      final link = backendLink.isNotEmpty ? backendLink : _buildReferralLink(code);

      return _ReferralDetails(code: code, link: link);
    } catch (_) {
      return const _ReferralDetails.empty();
    }
  }

  String _buildReferralLink(String code) {
    if (code.isEmpty) return '';
    final referrer = Uri.encodeComponent('far_ref=$code');
    return 'https://play.google.com/store/apps/details?id=com.dairy.corzin&referrer=$referrer';
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    Get.snackbar('success'.tr, 'copied'.tr);
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}

class _ReferralDetails {
  const _ReferralDetails({
    required this.code,
    required this.link,
  });

  const _ReferralDetails.empty()
      : code = '',
        link = '';

  final String code;
  final String link;
}
