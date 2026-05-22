import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_data.dart';

class PdfService {
  /// Generates the PDF document based on [CVData] and returns raw PDF bytes.
  static Future<Uint8List> generatePdf(CVData cvData,
      {bool isPremium = false}) async {
    final pdf = pw.Document(
      title: cvData.personalInfo.fullName,
      author: 'Antigravity CV Generator',
    );

    // Standard styling variables
    final primaryColor = PdfColor.fromHex('#6A1B9A'); // Dark Purple
    final accentColor = PdfColor.fromHex('#FFB300'); // Gold
    final darkBg = PdfColor.fromHex('#121212'); // Near black for dark accents
    final textDark = PdfColor.fromHex('#212121');
    final textMuted = PdfColor.fromHex('#616161');

    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36), // ~1.27 cm
        footer: (pw.Context context) {
          if (isPremium) {
            return pw.Container();
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Generated with AI CV Builder (Free Tier)',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8,
                color: PdfColors.grey400,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          switch (cvData.selectedTemplate) {
            case 'modern-dark':
              return _buildModernDarkLayout(
                  cvData,
                  primaryColor,
                  accentColor,
                  darkBg,
                  textDark,
                  textMuted,
                  regularFont,
                  boldFont,
                  italicFont);
            case 'executive':
              return _buildExecutiveLayout(cvData, primaryColor, accentColor,
                  textDark, textMuted, regularFont, boldFont, italicFont);
            case 'minimalist':
            default:
              return _buildMinimalistLayout(cvData, primaryColor, textDark,
                  textMuted, regularFont, boldFont, italicFont);
          }
        },
      ),
    );

    return pdf.save();
  }

  // --- MINIMALIST LAYOUT (Traditional Clean Layout) ---
  static List<pw.Widget> _buildMinimalistLayout(
    CVData cv,
    PdfColor primaryColor,
    PdfColor textDark,
    PdfColor textMuted,
    pw.Font regular,
    pw.Font bold,
    pw.Font italic,
  ) {
    return [
      // Header Section
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            cv.personalInfo.fullName.toUpperCase(),
            style: pw.TextStyle(font: bold, fontSize: 24, color: textDark),
          ),
          if (cv.personalInfo.title.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              cv.personalInfo.title,
              style: pw.TextStyle(
                  font: regular, fontSize: 13, color: primaryColor),
            ),
          ],
          pw.SizedBox(height: 6),
          // Contact Info Row
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (cv.personalInfo.email.isNotEmpty)
                _buildContactItem(
                    'Email: ${cv.personalInfo.email}', regular, textMuted),
              if (cv.personalInfo.phone.isNotEmpty)
                _buildContactItem(
                    'Tel: ${cv.personalInfo.phone}', regular, textMuted),
              if (cv.personalInfo.location.isNotEmpty)
                _buildContactItem(
                    'Loc: ${cv.personalInfo.location}', regular, textMuted),
              if (cv.personalInfo.linkedin.isNotEmpty)
                _buildContactItem('LinkedIn: ${cv.personalInfo.linkedin}',
                    regular, textMuted),
              if (cv.personalInfo.github.isNotEmpty)
                _buildContactItem(
                    'GitHub: ${cv.personalInfo.github}', regular, textMuted),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
        ],
      ),

      // About/Summary
      if (cv.about.isNotEmpty) ...[
        _buildSectionHeader('PROFESSIONAL SUMMARY', bold, primaryColor),
        pw.Paragraph(
          text: cv.about,
          style: pw.TextStyle(font: regular, fontSize: 10, color: textDark),
        ),
        pw.SizedBox(height: 14),
      ],

      // Experience
      if (cv.experience.isNotEmpty) ...[
        _buildSectionHeader('WORK EXPERIENCE', bold, primaryColor),
        pw.ListView.builder(
          itemCount: cv.experience.length,
          itemBuilder: (context, index) {
            final exp = cv.experience[index];
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${exp.role} @ ${exp.company}',
                        style: pw.TextStyle(
                            font: bold, fontSize: 11, color: textDark),
                      ),
                      pw.Text(
                        exp.period,
                        style: pw.TextStyle(
                            font: italic, fontSize: 9, color: textMuted),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  ...exp.bullets.map((bullet) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ',
                                style:
                                    pw.TextStyle(font: regular, fontSize: 10)),
                            pw.Expanded(
                              child: pw.Text(
                                bullet,
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 9.5,
                                    color: textDark),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        ),
        pw.SizedBox(height: 8),
      ],

      // Education
      if (cv.education.isNotEmpty) ...[
        _buildSectionHeader('EDUCATION', bold, primaryColor),
        ...cv.education.map((edu) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu.school,
                          style: pw.TextStyle(
                              font: bold, fontSize: 10, color: textDark)),
                      pw.Text(edu.field,
                          style: pw.TextStyle(
                              font: regular, fontSize: 9.5, color: textMuted)),
                    ],
                  ),
                  pw.Text(edu.period,
                      style: pw.TextStyle(
                          font: italic, fontSize: 9, color: textMuted)),
                ],
              ),
            )),
        pw.SizedBox(height: 10),
      ],

      // Skills & Languages (2 Columns)
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (cv.skills.isNotEmpty)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('SKILLS', bold, primaryColor),
                  ...cv.skills.map((skill) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: '${skill.label}: ',
                                style: pw.TextStyle(
                                    font: bold, fontSize: 9.5, color: textDark),
                              ),
                              pw.TextSpan(
                                text: skill.tags.join(', '),
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 9.5,
                                    color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          if (cv.languages.isNotEmpty) ...[
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('LANGUAGES', bold, primaryColor),
                  ...cv.languages.map((lang) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(lang.name,
                                style: pw.TextStyle(
                                    font: bold,
                                    fontSize: 9.5,
                                    color: textDark)),
                            pw.Text(lang.level,
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 9,
                                    color: textMuted)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ]
        ],
      ),

      // Projects
      if (cv.projects.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _buildSectionHeader('PROJECTS', bold, primaryColor),
        ...cv.projects.map((proj) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(proj.name,
                          style: pw.TextStyle(
                              font: bold, fontSize: 10, color: textDark)),
                      pw.Text(proj.period,
                          style: pw.TextStyle(
                              font: italic, fontSize: 9, color: textMuted)),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(proj.description,
                      style: pw.TextStyle(
                          font: regular, fontSize: 9, color: textDark)),
                  if (proj.technologies.isNotEmpty)
                    pw.Text('Tech: ${proj.technologies.join(", ")}',
                        style: pw.TextStyle(
                            font: italic, fontSize: 8.5, color: primaryColor)),
                ],
              ),
            )),
      ],

      // Certificates & References
      if (cv.certificates.isNotEmpty || cv.references.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (cv.certificates.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('CERTIFICATIONS', bold, primaryColor),
                    ...cv.certificates.map((cert) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                              '${cert.name} (${cert.issuer}, ${cert.date})',
                              style: pw.TextStyle(
                                  font: regular, fontSize: 9, color: textDark)),
                        )),
                  ],
                ),
              ),
            if (cv.references.isNotEmpty) ...[
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('REFERENCES', bold, primaryColor),
                    ...cv.references.map((ref) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(ref.name,
                                  style: pw.TextStyle(
                                      font: bold,
                                      fontSize: 9,
                                      color: textDark)),
                              pw.Text('${ref.position} @ ${ref.company}',
                                  style: pw.TextStyle(
                                      font: regular,
                                      fontSize: 8,
                                      color: textMuted)),
                              pw.Text('${ref.email} | ${ref.phone}',
                                  style: pw.TextStyle(
                                      font: regular,
                                      fontSize: 8,
                                      color: textMuted)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ]
          ],
        )
      ]
    ];
  }

  // --- MODERN DARK LAYOUT (Dual column, premium gold/purple design elements) ---
  static List<pw.Widget> _buildModernDarkLayout(
    CVData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    PdfColor darkBg,
    PdfColor textDark,
    PdfColor textMuted,
    pw.Font regular,
    pw.Font bold,
    pw.Font italic,
  ) {
    // An elegant dual column structure
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sidebar (Left column - Contact, Skills, Languages)
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header in sidebar
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cv.personalInfo.fullName,
                        style: pw.TextStyle(
                            font: bold, fontSize: 18, color: primaryColor),
                      ),
                      if (cv.personalInfo.title.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          cv.personalInfo.title.toUpperCase(),
                          style: pw.TextStyle(
                              font: bold, fontSize: 9, color: accentColor),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Divider(thickness: 1.5, color: primaryColor),
                pw.SizedBox(height: 10),

                // Contact Details
                _buildSectionHeader('CONTACT', bold, primaryColor),
                if (cv.personalInfo.email.isNotEmpty)
                  _buildSidebarItem(
                      'Email', cv.personalInfo.email, regular, bold, textDark),
                if (cv.personalInfo.phone.isNotEmpty)
                  _buildSidebarItem(
                      'Tel', cv.personalInfo.phone, regular, bold, textDark),
                if (cv.personalInfo.location.isNotEmpty)
                  _buildSidebarItem(
                      'Loc', cv.personalInfo.location, regular, bold, textDark),
                if (cv.personalInfo.linkedin.isNotEmpty)
                  _buildSidebarItem('LinkedIn', cv.personalInfo.linkedin,
                      regular, bold, textDark),
                if (cv.personalInfo.github.isNotEmpty)
                  _buildSidebarItem('GitHub', cv.personalInfo.github, regular,
                      bold, textDark),
                if (cv.personalInfo.birthDate.isNotEmpty)
                  _buildSidebarItem('Born', cv.personalInfo.birthDate, regular,
                      bold, textDark),

                pw.SizedBox(height: 14),

                // Skills
                if (cv.skills.isNotEmpty) ...[
                  _buildSectionHeader('SKILLS', bold, primaryColor),
                  ...cv.skills.map((skill) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(skill.label,
                                style: pw.TextStyle(
                                    font: bold,
                                    fontSize: 8.5,
                                    color: textDark)),
                            pw.SizedBox(height: 1),
                            pw.Text(skill.tags.join(', '),
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 8,
                                    color: textMuted)),
                          ],
                        ),
                      )),
                ],

                pw.SizedBox(height: 14),

                // Languages
                if (cv.languages.isNotEmpty) ...[
                  _buildSectionHeader('LANGUAGES', bold, primaryColor),
                  ...cv.languages.map((lang) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(lang.name,
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 8.5,
                                    color: textDark)),
                            pw.Text(lang.level,
                                style: pw.TextStyle(
                                    font: italic,
                                    fontSize: 8,
                                    color: textMuted)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),

          // Gap
          pw.SizedBox(width: 24),

          // Main Column (Right column - Summary, Experience, Education)
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // About
                if (cv.about.isNotEmpty) ...[
                  _buildSectionHeader('ABOUT ME', bold, primaryColor),
                  pw.Text(
                    cv.about,
                    style: pw.TextStyle(
                        font: regular, fontSize: 9.5, color: textDark),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Experience
                if (cv.experience.isNotEmpty) ...[
                  _buildSectionHeader('EXPERIENCE', bold, primaryColor),
                  ...cv.experience.map((exp) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  exp.role,
                                  style: pw.TextStyle(
                                      font: bold,
                                      fontSize: 10,
                                      color: textDark),
                                ),
                                pw.Text(
                                  exp.period,
                                  style: pw.TextStyle(
                                      font: italic,
                                      fontSize: 8.5,
                                      color: textMuted),
                                ),
                              ],
                            ),
                            pw.Text(
                              exp.company,
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9.5,
                                  color: primaryColor),
                            ),
                            pw.SizedBox(height: 3),
                            ...exp.bullets.map((bullet) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 6, bottom: 2),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('▪ ',
                                          style: pw.TextStyle(
                                              font: regular,
                                              fontSize: 8,
                                              color: accentColor)),
                                      pw.Expanded(
                                        child: pw.Text(
                                          bullet,
                                          style: pw.TextStyle(
                                              font: regular,
                                              fontSize: 8.5,
                                              color: textDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      )),
                ],

                // Education
                if (cv.education.isNotEmpty) ...[
                  _buildSectionHeader('EDUCATION', bold, primaryColor),
                  ...cv.education.map((edu) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(edu.school,
                                    style: pw.TextStyle(
                                        font: bold,
                                        fontSize: 9.5,
                                        color: textDark)),
                                pw.Text(edu.field,
                                    style: pw.TextStyle(
                                        font: regular,
                                        fontSize: 8.5,
                                        color: textMuted)),
                              ],
                            ),
                            pw.Text(edu.period,
                                style: pw.TextStyle(
                                    font: italic,
                                    fontSize: 8.5,
                                    color: textMuted)),
                          ],
                        ),
                      )),
                ],

                // Projects
                if (cv.projects.isNotEmpty) ...[
                  _buildSectionHeader('PROJECTS', bold, primaryColor),
                  ...cv.projects.map((proj) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(proj.name,
                                    style: pw.TextStyle(
                                        font: bold,
                                        fontSize: 9.5,
                                        color: textDark)),
                                pw.Text(proj.period,
                                    style: pw.TextStyle(
                                        font: italic,
                                        fontSize: 8.5,
                                        color: textMuted)),
                              ],
                            ),
                            pw.Text(proj.description,
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 8.5,
                                    color: textDark)),
                            if (proj.technologies.isNotEmpty)
                              pw.Text('Tech: ${proj.technologies.join(", ")}',
                                  style: pw.TextStyle(
                                      font: italic,
                                      fontSize: 8,
                                      color: primaryColor)),
                          ],
                        ),
                      )),
                ]
              ],
            ),
          )
        ],
      )
    ];
  }

  // --- EXECUTIVE LAYOUT (Top dark header block, elegant structures) ---
  static List<pw.Widget> _buildExecutiveLayout(
    CVData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    PdfColor textDark,
    PdfColor textMuted,
    pw.Font regular,
    pw.Font bold,
    pw.Font italic,
  ) {
    return [
      // Top Block Header
      pw.Container(
        color: PdfColors.grey100,
        padding: const pw.EdgeInsets.all(12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cv.personalInfo.fullName.toUpperCase(),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 22,
                      color: textDark,
                      letterSpacing: 1),
                ),
                if (cv.personalInfo.title.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    cv.personalInfo.title,
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 11,
                        color: primaryColor,
                        letterSpacing: 0.5),
                  ),
                ],
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (cv.personalInfo.email.isNotEmpty)
                  pw.Text(cv.personalInfo.email,
                      style: pw.TextStyle(
                          font: regular, fontSize: 8, color: textDark)),
                if (cv.personalInfo.phone.isNotEmpty)
                  pw.Text(cv.personalInfo.phone,
                      style: pw.TextStyle(
                          font: regular, fontSize: 8, color: textDark)),
                if (cv.personalInfo.location.isNotEmpty)
                  pw.Text(cv.personalInfo.location,
                      style: pw.TextStyle(
                          font: regular, fontSize: 8, color: textMuted)),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),

      // Summary
      if (cv.about.isNotEmpty) ...[
        _buildSectionHeader('EXECUTIVE PROFILE', bold, primaryColor),
        pw.Paragraph(
          text: cv.about,
          style: pw.TextStyle(font: regular, fontSize: 9.5, color: textDark),
        ),
        pw.SizedBox(height: 14),
      ],

      // Work Experience
      if (cv.experience.isNotEmpty) ...[
        _buildSectionHeader('PROFESSIONAL EXPERIENCE', bold, primaryColor),
        ...cv.experience.map((exp) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: exp.role,
                              style: pw.TextStyle(
                                  font: bold, fontSize: 10.5, color: textDark),
                            ),
                            pw.TextSpan(
                              text: ' — ${exp.company}',
                              style: pw.TextStyle(
                                  font: regular,
                                  fontSize: 10.5,
                                  color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(exp.period,
                          style: pw.TextStyle(
                              font: italic, fontSize: 8.5, color: textMuted)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  ...exp.bullets.map((bullet) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('✓ ',
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 8.5,
                                    color: primaryColor)),
                            pw.Expanded(
                              child: pw.Text(
                                bullet,
                                style: pw.TextStyle(
                                    font: regular,
                                    fontSize: 9,
                                    color: textDark),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            )),
      ],

      // Education & Accreditations
      if (cv.education.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _buildSectionHeader('EDUCATION & CREDENTIALS', bold, primaryColor),
        ...cv.education.map((edu) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${edu.school} (${edu.field})',
                      style: pw.TextStyle(
                          font: bold, fontSize: 9.5, color: textDark)),
                  pw.Text(edu.period,
                      style: pw.TextStyle(
                          font: regular, fontSize: 8.5, color: textMuted)),
                ],
              ),
            )),
      ],

      // Skills Summary
      if (cv.skills.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _buildSectionHeader('CORE COMPETENCIES', bold, primaryColor),
        pw.Wrap(
          spacing: 12,
          runSpacing: 6,
          children: cv.skills
              .map((skill) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        color: PdfColors.grey50),
                    child: pw.Text(
                      '${skill.label}: ${skill.tags.join(", ")}',
                      style: pw.TextStyle(
                          font: regular, fontSize: 8.5, color: textDark),
                    ),
                  ))
              .toList(),
        ),
      ]
    ];
  }

  // --- REUSABLE PDF BUILD HELPER WIDGETS ---

  static pw.Widget _buildContactItem(
      String text, pw.Font font, PdfColor color) {
    return pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 8.5, color: color),
    );
  }

  static pw.Widget _buildSectionHeader(
      String title, pw.Font font, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
              font: font, fontSize: 10.5, color: color, letterSpacing: 0.8),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          height: 1,
          color: color,
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildSidebarItem(String label, String value, pw.Font font,
      pw.Font boldFont, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: color),
          ),
          pw.Text(
            value,
            style:
                pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
}
