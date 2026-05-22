import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../providers/cv_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  
  String _selectedLanguage = 'en'; // Default to English for internationalization
  String _selectedTemplate = 'minimalist'; // minimalist, modern-dark, executive
  
  File? _selectedImage;
  String? _base64Image;
  bool _useCustomKey = false;
  
  bool _isLoading = false;
  String _currentLoadingStatus = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  // Handle picking image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);

        if (!mounted) return;
        setState(() {
          _selectedImage = file;
          _base64Image = base64String;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume image successfully loaded'),
            backgroundColor: Color(0xFF9C27B0),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  // Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
  }

  // Loading sequence with user progress feedback
  Future<void> _startPremiumLoadingSequence() async {
    final steps = [
      "Scanning document structure...",
      "Converting to ATS-friendly format...",
      "Optimizing keywords...",
      "Generating premium design...",
    ];

    for (String step in steps) {
      if (!mounted) return;
      setState(() => _currentLoadingStatus = step);

      // Provide haptic feedback for user progress
      await HapticFeedback.lightImpact();

      // Delay for user to read status
      await Future.delayed(const Duration(milliseconds: 1800));
    }

    // After receiving AI data, navigate to paywall
    if (!mounted) return; // <-- Pridaný finálny bezpečnostný check
    Navigator.pushNamed(context, '/paywall');
  }

  // Start the generation process
  void _startGeneration() {
    if (_textController.text.trim().isEmpty && _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text or take a photo of your old resume'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentLoadingStatus = "Scanning document structure...";
    });

    // Start parallel loading animation
    _startPremiumLoadingSequence();

    // Call provider to parse resume in background
    ref.read(cvProvider.notifier).generateNewCV(
      rawText: _textController.text,
      base64Image: _base64Image,
      language: _selectedLanguage,
      apiKey: _useCustomKey ? _apiKeyController.text : null,
      onFinished: () {
        // AI processing is done, the local animation sequence will handle the navigation to the paywall.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF000000), // Pure AMOLED Black
          appBar: AppBar(
            backgroundColor: const Color(0xFF000000),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Resume Builder',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Raw Notes / Old Resume Text'),
                      const SizedBox(height: 8),
                      
                      // Text Area Container
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x14FFFFFF), // White with 8% opacity
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 8,
                          keyboardType: TextInputType.multiline,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Paste old resume text, education details, projects, or work history...',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF8E8E93), fontSize: 13),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 20),

                  // Image input options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Or scan a photo of your old CV'),
                      const SizedBox(height: 10),
                      
                      if (_selectedImage == null)
                        Row(
                          children: [
                            Expanded(
                              child: _buildUploadCard(
                                icon: Icons.camera_alt_outlined,
                                label: 'Take Photo',
                                onTap: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildUploadCard(
                                icon: Icons.photo_library_outlined,
                                label: 'From Gallery',
                                onTap: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        )
                      else
                        // Selected Image Preview Panel
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x4D9C27B0), // Purple with 30% opacity
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Photo Loaded',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Size: ${(File(_selectedImage!.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF8E8E93),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white60),
                                onPressed: _clearImage,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // Language selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Output Language'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectableChip(
                              label: '🇸🇰 Slovak',
                              isSelected: _selectedLanguage == 'sk',
                              onTap: () => setState(() => _selectedLanguage = 'sk'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSelectableChip(
                              label: '🇬🇧 English',
                              isSelected: _selectedLanguage == 'en',
                              onTap: () => setState(() => _selectedLanguage = 'en'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 300.ms),

                  const SizedBox(height: 24),

                  // Template selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('PDF Template'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectableChip(
                              label: 'Minimalist',
                              isSelected: _selectedTemplate == 'minimalist',
                              onTap: () => setState(() => _selectedTemplate = 'minimalist'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectableChip(
                              label: 'Modern Dark',
                              isSelected: _selectedTemplate == 'modern-dark',
                              onTap: () => setState(() => _selectedTemplate = 'modern-dark'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectableChip(
                              label: 'Executive',
                              isSelected: _selectedTemplate == 'executive',
                              onTap: () => setState(() => _selectedTemplate = 'executive'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 400.ms),

                  const SizedBox(height: 24),

                  // API Key toggle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Use Custom Mistral API Key',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Switch(
                            value: _useCustomKey,
                            onChanged: (val) => setState(() => _useCustomKey = val),
                          activeThumbColor: const Color(0xFFD4AF37),
                          activeTrackColor: const Color(0x809C27B0), // Purple with 50% opacity
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.white12,
                          ),
                        ],
                      ),

                      if (_useCustomKey) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x4DD4AF37), // Gold with 30% opacity
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: true,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter your Mistral API key (MISTRAL_API_KEY)...',
                              hintStyle: GoogleFonts.inter(color: const Color(0xFF8E8E93), fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ).animate().fade(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 500.ms),

                  const SizedBox(height: 40),

                  // GENERATE BUTTON
                  _buildGenerateButton().animate().fade(duration: 400.ms, delay: 600.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 600.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // LOADING OVERLAY
        if (_isLoading) _buildLoadingOverlay(_currentLoadingStatus),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x0DFFFFFF), // White with 5% opacity
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF9C27B0), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x269C27B0) : const Color(0xFF1C1C1E), // 15% opacity
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF9C27B0) : const Color(0x0DFFFFFF), // 5% opacity
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _startGeneration,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFD4AF37)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x4D9C27B0), // 30% opacity
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Generate Resume',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(String statusText) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(235), // 92% opacity
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_5n8yhyqy.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const PremiumScannerVisual();
                  },
                ),
              ),
              const SizedBox(height: 36),
              Text(
                statusText,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      color: Color(0xCC9C27B0), // 80% opacity
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our algorithm is optimizing keywords...',
                style: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumScannerVisual extends StatefulWidget {
  const PremiumScannerVisual({super.key});

  @override
  State<PremiumScannerVisual> createState() => _PremiumScannerVisualState();
}

class _PremiumScannerVisualState extends State<PremiumScannerVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x4D9C27B0), // 30% opacity
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Inside the box, a document outline icon
              const Center(
                child: Icon(
                  Icons.document_scanner,
                  color: Color(0x669C27B0), // 40% opacity
                  size: 60,
                ),
              ),
              // Scanning laser line
              Positioned(
                left: 10,
                right: 10,
                top: 10 + (_controller.value * 100),
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xCCD4AF37), // 80% opacity
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

