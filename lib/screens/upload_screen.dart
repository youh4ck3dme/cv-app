import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/cv_provider.dart';
import '../providers/permissions_provider.dart';
import 'preview_screen.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  String _selectedLanguage =
      'en'; // Default to English for internationalization
  String _selectedTemplate = 'minimalist'; // minimalist, modern-dark, executive

  File? _selectedImage;
  String? _base64Image;
  bool _useCustomKey = false;

  // Consent and entitlement fields
  bool _consentGiven = false;
  bool _isLoading = false;
  String _currentLoadingStatus = '';

  @override
  void initState() {
    super.initState();
    // Initialize RevenueCat and check entitlement
    _loadConsent();
    _checkEntitlement();
    _apiKeyController.addListener(_saveApiKey);
  }

  final _secureStorage = const FlutterSecureStorage();

  void _saveApiKey() async {
    await _secureStorage.write(
        key: 'customApiKey', value: _apiKeyController.text);
    _checkEntitlement();
  }

  Future<void> _loadConsent() async {
    final consent = await _secureStorage.read(key: 'consentAccepted');
    final useCustom = await _secureStorage.read(key: 'useCustomKey');
    final savedKey = await _secureStorage.read(key: 'customApiKey');
    setState(() {
      _consentGiven = consent == 'true';
      _useCustomKey = useCustom == 'true';
      if (savedKey != null) {
        _apiKeyController.text = savedKey;
      }
    });
  }

  Future<void> _checkEntitlement() async {
    ref.read(permissionsProvider.notifier).refreshPermissions();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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

    bool generationFailed = false;

    for (String step in steps) {
      if (!mounted) return;

      // If a failure has already been reported in the provider, stop immediately
      if (ref.read(cvProvider).errorMessage != null) {
        generationFailed = true;
        break;
      }

      setState(() => _currentLoadingStatus = step);

      // Provide haptic feedback for user progress
      await HapticFeedback.lightImpact();

      // Delay for user to read status (1800ms total per step), polling for failure
      for (int delay = 0; delay < 18; delay++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (ref.read(cvProvider).errorMessage != null) {
          generationFailed = true;
          break;
        }
      }
      if (generationFailed) break;
    }

    // Wait for the background generation to complete if it hasn't yet (and hasn't failed)
    if (!generationFailed) {
      if (ref.read(cvProvider).isLoading) {
        if (mounted) {
          setState(() => _currentLoadingStatus = "Finishing touch...");
        }
        // Poll until loading is finished or fails
        while (ref.read(cvProvider).isLoading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      if (ref.read(cvProvider).errorMessage != null) {
        generationFailed = true;
      }
    }

    if (!mounted) return;

    if (generationFailed || ref.read(cvProvider).currentCV == null) {
      setState(() {
        _isLoading = false;
      });
      final error = ref.read(cvProvider).errorMessage ??
          "An error occurred during CV generation.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // After receiving AI data, navigate to paywall (or directly to preview if already subscribed)
    final isUnlocked = ref.read(permissionsProvider).canExportPDF;
    if (isUnlocked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PreviewScreen()),
      );
    } else {
      Navigator.pushNamed(context, '/paywall');
    }
  }

  // Start the generation process
  void _startGeneration() async {
    if (_textController.text.trim().isEmpty && _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text or take a photo of your old resume'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return;
    }

    // If consent not stored, show detailed consent dialog (GDPR & Play Store compliant)
    if (!_consentGiven) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            _selectedLanguage == 'sk'
                ? 'Vyžaduje sa súhlas'
                : 'Consent Required',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLanguage == 'sk'
                      ? 'Pre analýzu a generovanie Vášho životopisu musíte súhlasiť so spracovaním Vašich údajov prostredníctvom umelej inteligencie.'
                      : 'To analyze and generate your resume, you must agree to the processing of your data by artificial intelligence.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedLanguage == 'sk'
                      ? 'Odosielané údaje:'
                      : 'Data to be sent:',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLanguage == 'sk'
                      ? '• Text Vášho starého životopisu\n• Priložené fotografie / obrázky'
                      : '• Your old CV text / raw notes\n• Uploaded CV photos or images',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedLanguage == 'sk'
                      ? 'Príjemcovia a účel:'
                      : 'Recipient & Purpose:',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLanguage == 'sk'
                      ? 'Údaje sa posielajú na náš zabezpečený server a následne poskytovateľovi AI (Mistral AI) za účelom pretransformovania na formátovaný životopis. Údaje nie sú použité na trénovanie modelov.'
                      : 'Data is sent to our secure gateway and then to the AI provider (Mistral AI) solely for formatting your resume. Data is not used for model training.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _launchURL(
                      'https://youh4ck3dme.github.io/cv-app/privacy'),
                  child: Text(
                    _selectedLanguage == 'sk'
                        ? 'Zobraziť Zásady ochrany osobných údajov'
                        : 'View Privacy Policy',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF9C27B0),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _selectedLanguage == 'sk' ? 'Zrušiť' : 'Cancel',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await _secureStorage.write(
                      key: 'consentAccepted', value: 'true');
                  if (!mounted) return;
                  setState(() => _consentGiven = true);
                  navigator.pop();
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(_selectedLanguage == 'sk'
                          ? 'Chyba pri ukladaní súhlasu.'
                          : 'Consent could not be saved. Please try again.'),
                    ),
                  );
                }
              },
              child: Text(
                _selectedLanguage == 'sk' ? 'Súhlasím' : 'Agree',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (!_consentGiven) {
        return;
      }
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
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
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
                            color: const Color(
                                0x14FFFFFF), // White with 8% opacity
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 8,
                          keyboardType: TextInputType.multiline,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'Paste old resume text, education details, projects, or work history...',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF8E8E93), fontSize: 13),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(
                      begin: 0.1, end: 0, duration: 400.ms, delay: 100.ms),
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
                              color: const Color(
                                  0x4D9C27B0), // Purple with 30% opacity
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
                                icon: const Icon(Icons.close,
                                    color: Colors.white60),
                                onPressed: _clearImage,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(
                      begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),

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
                              onTap: () =>
                                  setState(() => _selectedLanguage = 'sk'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSelectableChip(
                              label: '🇬🇧 English',
                              isSelected: _selectedLanguage == 'en',
                              onTap: () =>
                                  setState(() => _selectedLanguage = 'en'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(
                      begin: 0.1, end: 0, duration: 400.ms, delay: 300.ms),

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
                              onTap: () => setState(
                                  () => _selectedTemplate = 'minimalist'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectableChip(
                              label: 'Modern Dark',
                              isSelected: _selectedTemplate == 'modern-dark',
                              onTap: () => setState(
                                  () => _selectedTemplate = 'modern-dark'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectableChip(
                              label: 'Executive',
                              isSelected: _selectedTemplate == 'executive',
                              onTap: () => setState(
                                  () => _selectedTemplate = 'executive'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms, delay: 400.ms).slideY(
                      begin: 0.1, end: 0, duration: 400.ms, delay: 400.ms),

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
                            onChanged: (val) async {
                              setState(() => _useCustomKey = val);
                              await _secureStorage.write(
                                  key: 'useCustomKey', value: val.toString());
                              await _checkEntitlement();
                            },
                            activeThumbColor: const Color(0xFFD4AF37),
                            activeTrackColor: const Color(
                                0x809C27B0), // Purple with 50% opacity
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.white12,
                          ),
                        ],
                      ),

                      // Consent Checkbox (GDPR & Play Store compliant)
                      CheckboxListTile(
                        value: _consentGiven,
                        onChanged: (val) async {
                          final newVal = val ?? false;
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          try {
                            if (newVal) {
                              await _secureStorage.write(
                                  key: 'consentAccepted', value: 'true');
                            } else {
                              await _secureStorage.delete(
                                  key: 'consentAccepted');
                            }
                            if (!mounted) return;
                            setState(() => _consentGiven = newVal);
                          } catch (e) {
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to update consent. Please try again.'),
                              ),
                            );
                          }
                        },
                        title: Text(
                          _selectedLanguage == 'sk'
                              ? 'Súhlasím so spracovaním CV dát umelou inteligenciou'
                              : 'I agree to the AI processing of my CV data',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _selectedLanguage == 'sk'
                              ? 'Súhlas môžete kedykoľvek odvolať odznačením tohto boxu. Podrobnosti v Zásadách ochrany súkromia.'
                              : 'You can withdraw consent at any time by unchecking this. Read our Privacy Policy for details.',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 11),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFFD4AF37),
                      ),

                      if (_useCustomKey) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                  0x4DD4AF37), // Gold with 30% opacity
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: true,
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  'Enter your Mistral API key (MISTRAL_API_KEY)...',
                              hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFF8E8E93), fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ).animate().fade(duration: 400.ms, delay: 500.ms).slideY(
                      begin: 0.1, end: 0, duration: 400.ms, delay: 500.ms),

                  const SizedBox(height: 40),

                  // GENERATE BUTTON
                  _buildGenerateButton()
                      .animate()
                      .fade(duration: 400.ms, delay: 600.ms)
                      .slideY(
                          begin: 0.1, end: 0, duration: 400.ms, delay: 600.ms),
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
          color: isSelected
              ? const Color(0x269C27B0)
              : const Color(0xFF1C1C1E), // 15% opacity
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C27B0)
                : const Color(0x0DFFFFFF), // 5% opacity
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

class _PremiumScannerVisualState extends State<PremiumScannerVisual>
    with SingleTickerProviderStateMixin {
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
