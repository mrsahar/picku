import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/privacy_policy_controller.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:pick_u/widget/picku_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late WebViewController webViewController;
  bool isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('WebView: Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView: Page finished loading: $url');
            setState(() {
              isWebViewReady = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView: Error - ${error.description}');
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PrivacyPolicyController>()
        ? Get.find<PrivacyPolicyController>()
        : Get.put(PrivacyPolicyController());

    return Scaffold(
      backgroundColor: MColor.lightBg,
      appBar: PickUAppBar(
        title: "Privacy Policy",
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: MColor.primaryNavy),
            onPressed: controller.refreshPolicy,
          ),
        ],
      ),
      body: Obx(() {
        print('PrivacyPolicyScreen: Rendering - isLoading=${controller.isLoading}, hasPolicy=${controller.hasPolicy}, hasContent=${controller.hasContent}');

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
          CircularProgressIndicator(color: MColor.primaryNavy),
          const SizedBox(height: 16),
          Text(
            'Loading privacy policy...',
            style: TextStyle(fontSize: 14, color: MColor.mediumGrey),
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
            Icon(Icons.error_outline, size: 80, color: MColor.danger),
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
              style: TextStyle(fontSize: 14, color: MColor.mediumGrey),
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
          Icon(Icons.description_outlined, size: 80, color: MColor.mediumGrey),
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
            style: TextStyle(fontSize: 14, color: MColor.mediumGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent(PrivacyPolicyController controller) {
    final policy = controller.privacyPolicy!;

    print('_buildPolicyContent: Building policy content for: ${policy.title}');
    print('_buildPolicyContent: Content length: ${policy.content?.length ?? 0}');

    // Load HTML content into WebView
    final htmlContent = _wrapHtmlContent(policy.content ?? '');
    webViewController.loadHtmlString(htmlContent);

    return RefreshIndicator(
      color: MColor.primaryNavy,
      onRefresh: controller.refreshPolicy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MColor.primaryNavy, MColor.primaryNavy.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: MColor.primaryNavy.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.calendar_today, 'Created', policy.formattedCreatedAt),
                if (policy.version != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.tag, 'Version', policy.version.toString()),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // WebView Content
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebViewWidget(controller: webViewController),
            ),
          ),

          const SizedBox(height: 16),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MColor.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: MColor.primaryNavy, size: 20),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: MColor.white.withAlpha(230), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: MColor.white.withAlpha(204),
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

  String _wrapHtmlContent(String htmlContent) {
    print('_wrapHtmlContent: Processing ${htmlContent.length} characters');

    // If already has DOCTYPE, return as-is
    if (htmlContent.trim().toUpperCase().startsWith('<!DOCTYPE')) {
      print('_wrapHtmlContent: Already complete HTML document');
      return htmlContent;
    }

    // Wrap with minimal styling
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 15px;
      line-height: 1.6;
      color: #333;
      margin: 16px;
      padding: 0;
    }
    h1, h2, h3 { color: #1A2A44; margin: 16px 0 8px 0; }
    p { margin: 8px 0; }
    img { max-width: 100%; height: auto; }
  </style>
</head>
<body>
$htmlContent
</body>
</html>
''';
  }
}

