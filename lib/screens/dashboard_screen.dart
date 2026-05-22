import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cube/flutter_cube.dart';
import '../providers/cv_provider.dart';
import '../providers/permissions_provider.dart';
import 'upload_screen.dart';
import 'preview_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync permissions with backend in background when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsProvider.notifier).refreshPermissions();
    });

    final permissionsState = ref.watch(permissionsProvider);
    if (permissionsState.upgradeRequired) {
      return const UpgradeBlockerWidget();
    }

    final cvState = ref.watch(cvProvider);
    final history = cvState.history;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure AMOLED Black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // App Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'AI RESUME',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFF9C27B0)
                                  ], // Gold to Purple
                                ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                        ),
                        Text(
                          'Mobile Career Generator',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8E8E93),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Small decorative top status tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(
                          0x269C27B0), // Purple with 15% opacity (0x26)
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(
                            0x4D9C27B0), // Purple with 30% opacity (0x4D)
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37), // Gold Status Dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PRO',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ).animate().fade(duration: 500.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 32),

              // Glassmorphic CTA button "CREATE NEW CV"
              _buildCreateCvButton(context, ref),

              const SizedBox(height: 36),

              // History Title
              Text(
                'Saved Resumes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .fade(duration: 500.ms, delay: 350.ms)
                  .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 16),

              // History list
              Expanded(
                child: history.isEmpty
                    ? _buildEmptyPlaceholder()
                    : ListView.builder(
                        itemCount: history.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final cv = history[index];
                          return _buildHistoryCard(context, ref, cv, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods

  // CTA Glassmorphic Button Builder
  Widget _buildCreateCvButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Clear current active CV in state and navigate to upload
        ref.read(cvProvider.notifier).clearCurrentCV();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UploadScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x339C27B0), // Transparent Purple (20% opacity = 0x33)
                  Color(0x0DD4AF37), // Transparent Gold (5% opacity = 0x0D)
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              border: Border.fromBorderSide(
                BorderSide(
                  color: Color(
                      0x4D9C27B0), // Transparent Purple (30% opacity = 0x4D)
                  width: 1.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Decorative faint glowing background circle
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x269C27B0), // Purple with 15% opacity
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                // Main responsive content using LayoutBuilder
                LayoutBuilder(builder: (context, constraints) {
                  final bool showCrystal = constraints.maxWidth > 280;
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, top: 16, bottom: 16, right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFD4AF37), // Gold Icon
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'CREATE NEW RESUME',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Upload text or scan a photo of your old resume and let AI generate a perfect ATS-optimized version in Slovak or English.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFC7C7CC),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showCrystal)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: InteractiveCrystal3D(),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: const Color(0x269C27B0))
        .animate()
        .fade(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.15, end: 0, duration: 600.ms, delay: 200.ms);
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: Color(0x669C27B0),
          ),
          const SizedBox(height: 16),
          Text(
            'No History',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Generate your first professional CV by pressing the button above.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8E8E93),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context, WidgetRef ref, cvData, int index) {
    final languageLabel = cvData.selectedLanguage.toUpperCase();
    final templateLabel = cvData.selectedTemplate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            const Color(0xFF1C1C1E), // Dark grey background for AMOLED contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x0DFFFFFF), // white with 5% opacity (0x0D)
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Set selected CV as active and navigate to preview
          ref.read(cvProvider.notifier).setCurrentCV(cvData);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PreviewScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Purple visual tag
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1A9C27B0), // Purple with 10% opacity
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x339C27B0), // Purple with 20% opacity
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.description,
                    color: Color(0xFF9C27B0),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cvData.personalInfo.fullName.isNotEmpty
                          ? cvData.personalInfo.fullName
                          : 'Unnamed',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cvData.personalInfo.title.isNotEmpty
                          ? cvData.personalInfo.title
                          : 'No Title',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoTag(languageLabel, const Color(0xFFD4AF37)),
                        _buildInfoTag(templateLabel, Colors.white60),
                      ],
                    )
                  ],
                ),
              ),
              // Delete Action Button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
                onPressed: () {
                  _showDeleteConfirmDialog(context, ref, index);
                },
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 400.ms, delay: (index * 80).ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: (index * 80).ms);
  }

  Widget _buildInfoTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20), // 8% opacity
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withAlpha(51), // 20% opacity
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white12, width: 1),
            ),
            title: Text(
              'Delete Resume?',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Do you really want to permanently delete this resume from your device?',
              style: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93), fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.white60),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(cvProvider.notifier).deleteCV(index);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class InteractiveCrystal3D extends StatefulWidget {
  const InteractiveCrystal3D({super.key});

  @override
  State<InteractiveCrystal3D> createState() => _InteractiveCrystal3DState();
}

class _InteractiveCrystal3DState extends State<InteractiveCrystal3D>
    with SingleTickerProviderStateMixin {
  Object? _crystal;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x269C27B0), // 15% opacity
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Cube(
        interactive: true,
        onSceneCreated: (Scene scene) {
          scene.camera.position.z = 6.0;
          scene.light.position.setFrom(Vector3(0, 8, 8));

          _crystal = Object(
            fileName: 'assets/3d/crystal.obj',
            scale: Vector3(3.2, 3.2, 3.2),
            lighting: true,
          );

          scene.world.add(_crystal!);

          _controller.addListener(() {
            if (_crystal != null) {
              _crystal!.rotation.y = _controller.value * 360;
              _crystal!.rotation.x = 20; // 20 degrees tilt

              // Apply gold color settings directly to the loaded mesh materials
              _crystal!.mesh.material.diffuse =
                  Vector3(0.83, 0.686, 0.215); // Gold
              _crystal!.mesh.material.ambient = Vector3(0.3, 0.25, 0.1);
              _crystal!.mesh.material.specular = Vector3(0.8, 0.7, 0.3);

              _crystal!.updateTransform();
              scene.update();
            }
          });
        },
      ),
    );
  }
}

class UpgradeBlockerWidget extends StatelessWidget {
  const UpgradeBlockerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure AMOLED black background
      body: Stack(
        children: [
          // Background subtle glowing circles
          Positioned(
            left: -50,
            top: 100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F9C27B0), // Faint purple glow
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: 100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1FD4AF37), // Faint gold glow
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Blurry backdrop filter (Glassmorphism)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: const Color(0x66000000),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gold to purple gradient ring
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1C1C1E),
                      border: Border.all(
                        color: const Color(0x339C27B0),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x269C27B0),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      size: 64,
                      color: Color(0xFFD4AF37), // Gold
                    ),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          duration: 2.seconds,
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05))
                      .shimmer(
                          duration: 3.seconds, color: const Color(0x26FFFFFF)),
                  const SizedBox(height: 32),
                  Text(
                    'UPDATE REQUIRED',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF9C27B0)],
                        ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 300.0, 50.0)),
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    'A new version of the app is available. To continue generating and exporting CVs safely, please update to the latest version.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFC7C7CC),
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fade(duration: 500.ms, delay: 150.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),
                  // Glassmorphic action button
                  GestureDetector(
                    onTap: () {
                      debugPrint('Store redirect triggered');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFD4AF37)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D9C27B0),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Update via Play Store',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 500.ms, delay: 300.ms)
                      .scale(duration: 500.ms, delay: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
