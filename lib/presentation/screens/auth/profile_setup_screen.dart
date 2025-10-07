import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../services/profile_service.dart';
import 'package:asha_ehr_app/services/voice_service.dart';
import '../asha/asha_dashboard.dart';
import '../phc/phc_dashboard.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role;
  
  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  bool _isLoading = false;
  
  // Common fields
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  // ASHA specific
  final _villageController = TextEditingController();
  final _wardController = TextEditingController();
  final _experienceController = TextEditingController();
  
  // PHC specific
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _villageController.dispose();
    _wardController.dispose();
    _experienceController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (widget.role == 'ASHA') {
        await _profileService.saveAshaProfile(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          village: _villageController.text.trim(),
          ward: _wardController.text.trim(),
          experience: _experienceController.text.trim(),
        );
      } else {
        await _profileService.savePHCProfile(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          designation: _designationController.text.trim(),
          department: _departmentController.text.trim(),
        );
      }
      
      if (mounted) {
        // Navigate to dashboard
        final dashboard = widget.role == 'ASHA' 
            ? const AshaDashboard() 
            : const PHCDashboard();
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => dashboard),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: widget.role == 'ASHA' ? AppColors.primary : AppColors.secondary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.role == 'ASHA' 
                              ? AppColors.primary.withOpacity(0.1) 
                              : AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.role == 'ASHA' ? Icons.person : Icons.badge,
                          size: 60,
                          color: widget.role == 'ASHA' ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Setup Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please fill in your details',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Common fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter mobile number';
                    if (value!.length != 10) return 'Please enter valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Role-specific fields
                if (widget.role == 'ASHA') ...[
                  _buildTextField(
                    controller: _villageController,
                    label: 'Village',
                    icon: Icons.location_city,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter village' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _wardController,
                    label: 'Ward Number',
                    icon: Icons.map,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter ward' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _experienceController,
                    label: 'Years of Experience',
                    icon: Icons.work,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter experience' : null,
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _designationController,
                    label: 'Designation',
                    icon: Icons.badge,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter designation' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _departmentController,
                    label: 'Department',
                    icon: Icons.business,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter department' : null,
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.role == 'ASHA' 
                          ? AppColors.primary 
                          : AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
