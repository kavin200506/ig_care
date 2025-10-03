import 'package:asha_ehr_app/services/voice_service_singleton.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen.dart';
import '../asha/asha_dashboard.dart';
import '../phc/phc_dashboard.dart';
// Use this import for your shared singleton instance (see previous instructions)
import 'package:asha_ehr_app/services/voice_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _checkNavigationRoute();
  }

  Future<void> _checkNavigationRoute() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    // Check if first launch
    final isFirstLaunch = await StorageService.isFirstLaunch();
    if (isFirstLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      final savedRole = await StorageService.getUserRole();
      if (savedRole == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      } else {
        if (savedRole == 'ASHA') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AshaDashboard()));
        } else if (savedRole == 'PHC') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const PHCDashboard()));
        }
      }
    }
  }

  // --- VOICE COMMAND HANDLING ---
  Future<void> _startVoiceNavigation() async {
    await voiceService.init(); // If using singleton
    await voiceService.startListening(
      onResult: (String command) {
        _handleVoiceCommand(command.trim().toLowerCase());
      },
      onError: (String? err) {
        _showError(err ?? "Unknown error");
      },
    );
  }

  void _handleVoiceCommand(String command) {
    if (command.contains('onboarding') ||
        command.contains('get started') ||
        command.contains('start')) {
      voiceService.speak('Navigating to onboarding');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (command.contains('role') ||
        command.contains('selection') ||
        command.contains('choose role')) {
      voiceService.speak('Navigating to role selection');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    } else if (command.contains('asha') ||
        command.contains('dashboard') ||
        command.contains('worker')) {
      voiceService.speak('Opening ASHA dashboard');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AshaDashboard()),
      );
    } else if (command.contains('phc') ||
        command.contains('staff')) {
      voiceService.speak('Opening PHC dashboard');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PHCDashboard()),
      );
    } else {
      voiceService.speak("Command not recognized. Try saying 'onboarding', 'role selection', 'ASHA dashboard' or 'PHC dashboard'.");
      _showError("Command not recognized. Try again.");
    }
  }

  void _showError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ASHA EHR',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Companion',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Digital Health Records for Rural India',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 32),

                  // --- MIC BUTTON FOR VOICE NAVIGATION ---
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.mic),
                    label: const Text(
                      "Voice Navigation",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _startVoiceNavigation,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Try saying: 'Onboarding', 'Role selection', 'ASHA dashboard', 'PHC dashboard'",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
