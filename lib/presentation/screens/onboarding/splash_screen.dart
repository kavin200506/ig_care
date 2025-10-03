import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen.dart';
import '../asha/asha_dashboard.dart';
import '../phc/phc_dashboard.dart';

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
    
<<<<<<< HEAD
=======
    // ignore: avoid_print
>>>>>>> ba92513 (Initial commit: Max Heap gem insertion project)
    print('First Launch: $isFirstLaunch'); // Debug
    
    if (isFirstLaunch) {
      // First time opening app - show onboarding
      print('Navigating to Onboarding');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // Not first time - check saved role
      final savedRole = await StorageService.getUserRole();
      
      print('Saved Role: $savedRole'); // Debug
      
      if (savedRole == null) {
        // No role saved - show role selection
        print('Navigating to Role Selection');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      } else {
        // Role exists - navigate to dashboard
        print('Navigating to Dashboard: $savedRole');
        if (savedRole == 'ASHA') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AshaDashboard()),
          );
        } else if (savedRole == 'PHC') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PHCDashboard()),
          );
        }
      }
    }
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
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
