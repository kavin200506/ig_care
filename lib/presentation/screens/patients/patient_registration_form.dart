// patient_registration_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';

class PatientRegistrationForm extends StatefulWidget {
  const PatientRegistrationForm({super.key});

  @override
  State<PatientRegistrationForm> createState() =>
      _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends State<PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _abhaController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'general';

  final List<String> _categories = [
    'general',
    'pregnant_women',
    'child_health',
    'common_diseases',
    'family_planning',
    'immunization',
    'elderly_care',
    'chronic_diseases'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Registration', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information'),
              _buildTextField(_nameController, 'Full Name', Icons.person, true),
              _buildTextField(_ageController, 'Age', Icons.cake, true,
                  TextInputType.number),
              _buildDropdown(
                'Gender',
                ['Male', 'Female', 'Other'],
                _selectedGender,
                (value) => setState(() => _selectedGender = value!),
              ),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                  false, TextInputType.phone),
              _buildTextField(
                  _addressController, 'Address', Icons.location_on, false),
              _buildTextField(
                  _aadhaarController, 'Aadhaar Number', Icons.badge, false),
              _buildTextField(
                  _abhaController, 'ABHA ID', Icons.health_and_safety, false),
              _buildSectionHeader('Medical Information'),
              _buildTextField(_conditionController, 'Medical Condition',
                  Icons.medical_services, false),
              _buildDropdown(
                'Priority',
                ['Low', 'Medium', 'High', 'Critical'],
                _selectedPriority,
                (value) => setState(() => _selectedPriority = value!),
              ),
              _buildDropdown(
                'Category',
                _categories.map((cat) => _getCategoryDisplayName(cat)).toList(),
                _getCategoryDisplayName(_selectedCategory),
                (value) => setState(() => _selectedCategory =
                    _categories.firstWhere(
                        (cat) => _getCategoryDisplayName(cat) == value!)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Register Patient',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, bool required,
      [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'pregnant_women':
        return 'Pregnant Women';
      case 'child_health':
        return 'Child Health';
      case 'common_diseases':
        return 'Common Diseases';
      case 'family_planning':
        return 'Family Planning';
      case 'immunization':
        return 'Immunization';
      case 'elderly_care':
        return 'Elderly Care';
      case 'chronic_diseases':
        return 'Chronic Diseases';
      default:
        return 'General';
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final patientData = {
          'name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'condition': _conditionController.text.trim() ?? 'General Checkup',
          'priority': _selectedPriority,
          'category': _selectedCategory,
          'aadhaar': _aadhaarController.text.trim(),
          'abhaId': _abhaController.text.trim(),
          'lastVisit': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'nextVisit': '', // Initialize with empty string
        };

        await _firestore.collection('patients').add(patientData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering patient: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _conditionController.dispose();
    _aadhaarController.dispose();
    _abhaController.dispose();
    super.dispose();
  }
}
