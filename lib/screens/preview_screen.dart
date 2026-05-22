import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/cv_data.dart';
import '../providers/cv_provider.dart';
import '../providers/permissions_provider.dart';
import '../services/pdf_service.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for editing data
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFields();
  }

  void _initializeFields() {
    final cvState = ref.read(cvProvider);
    final cv = cvState.currentCV;
    if (cv != null) {
      _nameController.text = cv.personalInfo.fullName;
      _titleController.text = cv.personalInfo.title;
      _emailController.text = cv.personalInfo.email;
      _phoneController.text = cv.personalInfo.phone;
      _locationController.text = cv.personalInfo.location;
      _aboutController.text = cv.about;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveModifiedData() {
    final cvState = ref.read(cvProvider);
    final currentCv = cvState.currentCV;
    if (currentCv != null) {
      // Build updated CVData structure
      final updatedCv = CVData(
        personalInfo: PersonalInfo(
          fullName: _nameController.text,
          title: _titleController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          location: _locationController.text,
          linkedin: currentCv.personalInfo.linkedin,
          github: currentCv.personalInfo.github,
          birthDate: currentCv.personalInfo.birthDate,
          drivingLicense: currentCv.personalInfo.drivingLicense,
        ),
        about: _aboutController.text,
        experience: currentCv.experience,
        education: currentCv.education,
        skills: currentCv.skills,
        languages: currentCv.languages,
        projects: currentCv.projects,
        certificates: currentCv.certificates,
        interests: currentCv.interests,
        references: currentCv.references,
        achievements: currentCv.achievements,
        customSections: currentCv.customSections,
        selectedTemplate: currentCv.selectedTemplate,
        selectedLanguage: currentCv.selectedLanguage,
      );

      // Save to provider (which also syncs to shared_preferences and updates state)
      ref.read(cvProvider.notifier).setCurrentCV(updatedCv);
      ref.read(cvProvider.notifier).saveToHistory(updatedCv);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes successfully saved and PDF updated'),
          backgroundColor: Color(0xFF9C27B0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvState = ref.watch(cvProvider);
    final cv = cvState.currentCV;
    final isUnlocked = ref.watch(permissionsProvider).canExportPDF;

    if (cv == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No active resume',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // AMOLED Black
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Resume Preview',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37), // Gold indicator
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF8E8E93),
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
                text: 'PDF DOCUMENT',
                icon: Icon(Icons.picture_as_pdf_outlined, size: 20)),
            Tab(text: 'EDIT DATA', icon: Icon(Icons.edit_note, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PDF Document Viewer
          _buildPdfPreviewTab(cv, isUnlocked),

          // TAB 2: Text / Details editor
          _buildEditorTab(cv),
        ],
      ),
    );
  }

  Widget _buildPdfPreviewTab(CVData cv, bool isUnlocked) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF000000),
          child: PdfPreview(
            build: (format) =>
                PdfService.generatePdf(cv, isPremium: isUnlocked),
            loadingWidget: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
              ),
            ),
            pdfPreviewPageDecoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0DFFFFFF), // white with 5% opacity
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            allowPrinting: isUnlocked,
            allowSharing: isUnlocked,
            canChangePageFormat: false,
            canChangeOrientation: false,
          ),
        ),
        if (!isUnlocked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xD9000000),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xE61C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x4DD4AF37),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x269C27B0),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0x26D4AF37),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFFD4AF37),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unlock Premium Access',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upgrade to premium to print, share, or download your ATS-optimized PDF resume.',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/paywall');
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFFD4AF37)],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Center(
                              child: Text(
                                'UNLOCK NOW',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditorTab(CVData cv) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField('Full Name', _nameController),
            const SizedBox(height: 12),
            _buildInputField('Professional Title', _titleController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInputField('Email', _emailController)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField('Phone', _phoneController)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField('Location', _locationController),

            const SizedBox(height: 28),

            Text(
              'Professional Summary (About Me)',
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInputField('About Me', _aboutController, maxLines: 4),

            const SizedBox(height: 32),

            // Save changes button
            GestureDetector(
              onTap: _saveModifiedData,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x339C27B0), // Purple with 20% opacity
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ]),
                child: Center(
                  child: Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x0DFFFFFF), // white with 5% opacity
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
