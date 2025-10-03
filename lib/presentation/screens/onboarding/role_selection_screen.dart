import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../services/storage_service.dart';
import '../auth/login_screen.dart';
import 'package:asha_ehr_app/services/voice_service_singleton.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _listening = false;

  Future<void> _selectRole(BuildContext context, String role) async {
    await StorageService.saveUserRole(role);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(role: role),
        ),
      );
    }
  }

  Future<void> _startVoiceNavigation() async {
    setState(() {
      _listening = true;
    });
    await voiceService.init();
    await voiceService.startListening(
      onResult: (String command) {
        _handleVoiceCommand(command.trim().toLowerCase());
        setState(() {
          _listening = false;
        });
      },
      onError: (String? err) {
        _showError(err ?? "Unknown error");
        setState(() {
          _listening = false;
        });
      },
    );
  }

  void _handleVoiceCommand(String command) {
    if (command.contains('asha')) {
      voiceService.speak('ASHA worker selected. Proceed to login.');
      _selectRole(context, 'ASHA');
    } else if (command.contains('phc')) {
      voiceService.speak('PHC staff selected. Proceed to login.');
      _selectRole(context, 'PHC');
    } else {
      voiceService.speak("Command not recognized. Please say 'ASHA' or 'PHC'.");
      _showError("Voice command not recognized. Say 'ASHA' or 'PHC'.");
    }
  }

  void _showError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'ASHA EHR Companion',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Digital Health Records for Rural India',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Text(
                  'Select Your Role',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                _RoleButton(
                  title: 'ASHA Worker',
                  subtitle: 'Field health worker',
                  icon: Icons.person_search,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  onTap: () => _selectRole(context, 'ASHA'),
                ),
                const SizedBox(height: 20),
                _RoleButton(
                  title: 'PHC Staff',
                  subtitle: 'Primary health center',
                  icon: Icons.local_hospital,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  onTap: () => _selectRole(context, 'PHC'),
                ),
                const SizedBox(height: 36),

                // --- Microphone voice navigation button ---
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: _listening ? Colors.red : AppColors.primary,
                  ),
                  label: Text(
                    _listening ? "Listening..." : "Voice Navigation",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _listening ? null : _startVoiceNavigation,
                ),
                const SizedBox(height: 8),
                Text(
                  "Say 'ASHA' or 'PHC' to choose your role.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Smart India Hackathon 2025',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
