import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/privacy_policy_controller.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrivacyPolicyController>();

    return Scaffold(
      backgroundColor: MColor.lightBg,
      appBar: PickUAppBar(
        title: "Privacy Policy",
        onBackPressed: () {
          Get.back();
        },
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: MColor.primaryNavy,
            ),
            onPressed: controller.refreshPolicy,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return _buildLoadingView();
        }

        if (controller.errorMessage.isNotEmpty) {
          return _buildErrorView(controller);
        }

        if (!controller.hasPolicy || !controller.hasContent) {
          return _buildEmptyView();
        }

        return _buildPolicyContent(controller);
      }),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: MColor.primaryNavy,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading privacy policy...',
            style: TextStyle(
              fontSize: 14,
              color: MColor.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(PrivacyPolicyController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: MColor.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MColor.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MColor.mediumGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refreshPolicy,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: MColor.mediumGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Privacy Policy Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MColor.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Privacy policy content is not available at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MColor.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent(PrivacyPolicyController controller) {
    final policy = controller.privacyPolicy!;

    return RefreshIndicator(
      color: MColor.primaryNavy,
      onRefresh: controller.refreshPolicy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MColor.primaryNavy,
                    MColor.primaryNavy.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MColor.primaryNavy.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: MColor.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          policy.displayTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: MColor.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Effective Date',
                    policy.formattedEffectiveDate,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.update,
                    'Last Updated',
                    policy.formattedLastUpdated,
                  ),
                  if (policy.version != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.tag,
                      'Version',
                      policy.version!,
                    ),
                  ],
                ],
              ),
            ),

            // Content Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MColor.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MColor.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article,
                          color: MColor.primaryNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Policy Content',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MColor.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content Text
                  SelectableText(
                    policy.content ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: MColor.darkGrey,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Footer info
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MColor.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: MColor.primaryNavy,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This privacy policy may be updated from time to time. Please check back regularly for updates.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MColor.darkGrey,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: MColor.white.withOpacity(0.9),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: MColor.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MColor.white,
          ),
        ),
      ],
    );
  }
}
