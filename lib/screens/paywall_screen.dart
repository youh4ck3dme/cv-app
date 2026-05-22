import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cv_provider.dart';
import '../providers/permissions_provider.dart';
import '../services/pdf_service.dart';
import 'preview_screen.dart';

const Color amoledBlack = Color(0xFF000000);
const Color premiumGold = Color(0xFFFFD700);

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  // Configuration for URLs - Update these with your real links
  static const String _privacyPolicyUrl =
      'https://youh4ck3dme.github.io/cv-app/privacy';
  static const String _termsOfUseUrl =
      'https://youh4ck3dme.github.io/cv-app/terms';

  Future<void> _handlePurchase() async {
    if (_isPurchasing || _isRestoring) return;
    setState(() => _isPurchasing = true);
    try {
      // Fetching offerings from RevenueCat
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        // We select the first available package (usually the main one)
        Package package = offerings.current!.availablePackages.first;
        await Purchases.purchase(PurchaseParams.package(package));
        // Sync permissions with backend server as the source of truth
        await ref.read(permissionsProvider.notifier).refreshPermissions();
        final isUnlocked = ref.read(permissionsProvider).canExportPDF;

        if (isUnlocked) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const PreviewScreen()),
            );
          }
        } else {
          _showErrorSnackBar(
              "Premium entitlement was not validated by the server. Please try restoring purchases or contact support.");
        }
      } else {
        throw Exception("No available products found.");
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled Apple purchase sheet, ignore silently
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        _showErrorSnackBar(
            "Payment is pending. Your premium status will update once completed.");
      } else {
        _showErrorSnackBar("Purchase failed: ${e.message ?? 'Unknown error'}");
      }
    } catch (e) {
      _showErrorSnackBar(
          "Could not complete the transaction. Please try again.");
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (_isPurchasing || _isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      await Purchases.restorePurchases();
      // Sync permissions with backend server as the source of truth
      await ref.read(permissionsProvider.notifier).refreshPermissions();
      final isUnlocked = ref.read(permissionsProvider).canExportPDF;

      if (isUnlocked) {
        _showSuccessSnackBar("Purchases successfully restored and validated!");
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PreviewScreen()),
          );
        }
      } else {
        _showErrorSnackBar("No previous purchases validated by the server.");
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled Apple authentication/restore prompt, ignore silently
      } else {
        _showErrorSnackBar("Restore failed: ${e.message ?? 'Unknown error'}");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to restore purchases.");
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar("Could not open the link.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: amoledBlack, // Pure AMOLED Black
      body: Stack(
        children: [
          // 1. LAYER: Background Real PDF Preview Page
          const Center(
            child: DummyPdfPreviewPage(),
          ),

          // 2. LAYER: Glassmorphism blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: amoledBlack.withAlpha(102), // 40% opacity = 102
              ),
            ),
          ),

          // 3. LAYER: Lottie Confetti/Celebration Overlay (Non-interactive)
          IgnorePointer(
            child: Lottie.asset(
              'assets/confetti.json',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              repeat: false,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // 4. LAYER: Premium UI Content (Scroll-safe to prevent hiding text/overflow)
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      const Spacer(),

                      // Animated Icon
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 80,
                        color: premiumGold, // Gold
                      )
                          .animate()
                          .fade(duration: 500.ms)
                          .scale(
                              delay: 200.ms,
                              duration: 600.ms,
                              curve: Curves.elasticOut)
                          .rotate(delay: 200.ms, duration: 600.ms),
                      const SizedBox(height: 24),

                      // Animated Title
                      const Text(
                        "Your resume is ready!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          .animate()
                          .fade(delay: 300.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Animated Description
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Unlock professional templates and export your resume in high-quality PDF format.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      )
                          .animate()
                          .fade(delay: 450.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),

                      const Spacer(),

                      // Main Purchase Button with shimmer effect
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: SizedBox(
                          width: double.infinity,
                          height: 65,
                          child: ElevatedButton(
                            onPressed: (_isPurchasing || _isRestoring)
                                ? null
                                : _handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumGold, // Gold
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isPurchasing
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Processing...",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Unlock and download PDF\n(3 days free)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .shimmer(
                                duration: 2.seconds,
                                color: Colors.white.withAlpha(128)),
                      )
                          .animate()
                          .fade(delay: 600.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),

                      // Price detail (high contrast to satisfy Google Play Policy requirements)
                      const SizedBox(height: 12),
                      const Text(
                        "Then only 9.99€/week. Cancel anytime.",
                        style: TextStyle(
                          color: Colors.white, // High contrast white
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600, // Semi-bold for high visibility
                        ),
                      ).animate().fade(delay: 750.ms, duration: 500.ms),

                      const Spacer(),

                      // Google Play Compliance Buttons (Terms of Service, Privacy Policy, Restore)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 16, right: 16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _ComplianceButton(
                              text: "Restore Purchases",
                              onPressed: (_isPurchasing || _isRestoring)
                                  ? null
                                  : _restorePurchases,
                            ),
                            _divider(),
                            _ComplianceButton(
                              text:
                                  "Terms of Service", // Google Play compliance
                              onPressed: (_isPurchasing || _isRestoring)
                                  ? null
                                  : () => _launchURL(_termsOfUseUrl),
                            ),
                            _divider(),
                            _ComplianceButton(
                              text: "Privacy Policy",
                              onPressed: (_isPurchasing || _isRestoring)
                                  ? null
                                  : () => _launchURL(_privacyPolicyUrl),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. LAYER: Close Button (Google compliance: must have a clear close/back button to prevent Subscription Traps)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128), // 50% opacity
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(
                        30), // subtle white border for premium design
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 22),
                  tooltip: 'Close',
                  onPressed: () {
                    // Navigate back to the Dashboard Screen (first route in navigation stack)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Text("  |  ", style: TextStyle(color: Colors.grey, fontSize: 10));
}

/// Renders the first page of the actual generated PDF behind the paywall using printing package
class DummyPdfPreviewPage extends ConsumerStatefulWidget {
  const DummyPdfPreviewPage({super.key});

  @override
  ConsumerState<DummyPdfPreviewPage> createState() =>
      _DummyPdfPreviewPageState();
}

class _DummyPdfPreviewPageState extends ConsumerState<DummyPdfPreviewPage> {
  Uint8List? _pdfImageBytes;
  bool _isRasterizing = true;

  @override
  void initState() {
    super.initState();
    _loadPdfPreview();
  }

  Future<void> _loadPdfPreview() async {
    try {
      final cvState = ref.read(cvProvider);
      final currentCv = cvState.currentCV;
      if (currentCv != null) {
        final isPremium = ref.read(permissionsProvider).canExportPDF;
        final pdfBytes =
            await PdfService.generatePdf(currentCv, isPremium: isPremium);

        // Rasterize the first page of the generated PDF using printing package
        await for (final page
            in Printing.raster(pdfBytes, pages: [0], dpi: 100)) {
          final pngBytes = await page.toPng();
          if (mounted) {
            setState(() {
              _pdfImageBytes = pngBytes;
              _isRasterizing = false;
            });
          }
          break; // We only need the first page
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRasterizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _pdfImageBytes != null
        ? Image.memory(
            _pdfImageBytes!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        : Container(
            color: const Color(0xFF1C1C1E),
            child: Center(
              child: _isRasterizing
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    )
                  : Icon(
                      Icons.description,
                      size: 100,
                      color: Colors.white.withAlpha(8),
                    ),
            ),
          );
  }
}

/// Small utility widget for Footer links (Apple Compliance)
class _ComplianceButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _ComplianceButton({required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDisabled ? Colors.grey.withAlpha(100) : Colors.grey,
          fontSize: 11,
          decoration:
              isDisabled ? TextDecoration.none : TextDecoration.underline,
        ),
      ),
    );
  }
}
