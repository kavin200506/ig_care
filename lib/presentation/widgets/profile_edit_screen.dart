import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String role;
  final VoidCallback onProfileUpdated;
  
  const ProfileEditScreen({
    super.key,
    required this.role,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _villageController = TextEditingController();
  final _wardController = TextEditingController();
  final _experienceController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = widget.role == 'ASHA'
          ? await _profileService.getAshaProfile()
          : await _profileService.getPHCProfile();
      
      if (profile != null) {
        _nameController.text = profile['name'] ?? '';
        _mobileController.text = profile['mobile'] ?? '';
        
        if (widget.role == 'ASHA') {
          _villageController.text = profile['village'] ?? '';
          _wardController.text = profile['ward'] ?? '';
          _experienceController.text = profile['experience'] ?? '';
        } else {
          _designationController.text = profile['designation'] ?? '';
          _departmentController.text = profile['department'] ?? '';
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
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
      
      widget.onProfileUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: widget.role == 'ASHA' ? AppColors.primary : AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile picture placeholder
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: widget.role == 'ASHA' 
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.secondary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: widget.role == 'ASHA' ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    if (widget.role == 'ASHA') ...[
                      _buildTextField(
                        controller: _villageController,
                        label: 'Village',
                        icon: Icons.location_city,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _wardController,
                        label: 'Ward Number',
                        icon: Icons.map,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _experienceController,
                        label: 'Years of Experience',
                        icon: Icons.work,
                      ),
                    ] else ...[
                      _buildTextField(
                        controller: _designationController,
                        label: 'Designation',
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _departmentController,
                        label: 'Department',
                        icon: Icons.business,
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.role == 'ASHA' 
                              ? AppColors.primary 
                              : AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Changes',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
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
      validator: (value) => value?.isEmpty ?? true ? 'This field is required' : null,
    );
  }
}
