import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/paywall_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AntigravityCvApp(),
    ),
  );
}

class AntigravityCvApp extends StatelessWidget {
  const AntigravityCvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Životopis',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // AMOLED Pure Black
        primaryColor: const Color(0xFF9C27B0), // Purple
        
        // Setup color scheme with purple and gold accents
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          surface: Color(0xFF1C1C1E), // Slate dark surface
          primary: Color(0xFF9C27B0), // Purple accent
          secondary: Color(0xFFD4AF37), // Gold accent
          error: Color(0xFFE53935),
        ),

        // Default typography using Outfit for headers, Inter for normal text
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          ),
          bodyMedium: GoogleFonts.inter(
            color: const Color(0xFFC7C7CC),
            fontSize: 13,
          ),
        ),

        // App Bar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Switch styling
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFD4AF37); // Gold thumb when selected
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0x809C27B0); // Purple track when selected (50% opacity = 0x80)
            }
            return Colors.white12;
          }),
        ),
      ),
      home: const DashboardScreen(),
      routes: {
        '/paywall': (context) => const PaywallScreen(),
      },
    );
  }
}
