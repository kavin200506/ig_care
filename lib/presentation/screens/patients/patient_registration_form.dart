// patient_registration_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
// Removed modal voice dialog; using inline panel instead
// import '../../widgets/voice_input_dialog.dart';
import '../../../services/voice_service_singleton.dart';
import '../../../services/voice_extractor.dart';

class PatientRegistrationForm extends StatefulWidget {
  const PatientRegistrationForm({super.key, this.autoOpenVoice = false});

  final bool autoOpenVoice;

  @override
  State<PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

// Inline voice terminal panel that does not obstruct the form
class _VoiceInlinePanel extends StatefulWidget {
  final bool autoStart;
  final ValueChanged<Map<String, String>> onExtract;
  const _VoiceInlinePanel({required this.autoStart, required this.onExtract});

  @override
  State<_VoiceInlinePanel> createState() => _VoiceInlinePanelState();
}

class _VoiceInlinePanelState extends State<_VoiceInlinePanel> {
  bool _isListening = false;
  String _realTimeText = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  Future<void> _start() async {
    setState(() => _isListening = true);
    await voiceService.init();
    await voiceService.startListening(
      onResult: (text) => setState(() => _realTimeText = text),
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $err')),
        );
        setState(() => _isListening = false);
      },
      localeId: 'en_IN',
    );
  }

  Future<void> _stop() async {
    await voiceService.stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  void _extract() {
    // Using simplified extraction similar to dialog logic
    final features = _extractFeatures(_realTimeText);
    widget.onExtract(features);
    final count = features.values.where((v) => v.isNotEmpty).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count fields extracted',
          style: const TextStyle(color: Colors.lightGreen),
        ),
      ),
    );
  }

  Map<String, String> _extractFeatures(String text) {
    // Delegate to shared extractor for better accuracy
    return extractPatientFeatures(text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Voice Terminal', style: GoogleFonts.robotoMono(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _isListening ? _stop : _start,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 16),
                      label: Text(_isListening ? 'Stop' : 'Start'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _realTimeText.isEmpty ? null : _extract,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Extract & Fill'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 140),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _realTimeText.isEmpty ? 'Listening...' : _realTimeText,
                  style: GoogleFonts.robotoMono(color: Colors.green, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  bool _showVoicePanel = false;

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
  void initState() {
    super.initState();
    if (widget.autoOpenVoice) {
      _showVoicePanel = true;
      // No dialog; inline panel will auto-start listening
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Registration', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Random fill button
          IconButton(
            tooltip: 'Fill with random values',
            icon: const Icon(Icons.shuffle),
            onPressed: _fillRandomValues,
          ),
          // Toggle inline voice panel
          IconButton(
            tooltip: _showVoicePanel ? 'Hide voice panel' : 'Show voice panel',
            icon: Icon(_showVoicePanel ? Icons.mic : Icons.mic_none),
            onPressed: () => setState(() => _showVoicePanel = !_showVoicePanel),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showVoicePanel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _VoiceInlinePanel(
                      autoStart: widget.autoOpenVoice,
                      onExtract: _applyExtractedFeatures,
                    ),
                  ),
                _buildSectionHeader('Personal Information'),
                _buildTextField(_nameController, 'Full Name', Icons.person, true),
                _buildTextField(_ageController, 'Age', Icons.cake, true, TextInputType.number),
                _buildDropdown(
                  'Gender',
                  ['Male', 'Female', 'Other'],
                  _selectedGender,
                  (value) => setState(() => _selectedGender = value!),
                ),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, false, TextInputType.phone),
                _buildTextField(_addressController, 'Address', Icons.location_on, false),
                _buildTextField(_aadhaarController, 'Aadhaar Number', Icons.badge, false),
                _buildTextField(_abhaController, 'ABHA ID', Icons.health_and_safety, false),
                _buildSectionHeader('Medical Information'),
                _buildTextField(_conditionController, 'Medical Condition', Icons.medical_services, false),
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
                      _categories.firstWhere((cat) => _getCategoryDisplayName(cat) == value!)),
                ),
                const SizedBox(height: 24),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, [
    TextInputType? keyboardType,
  ]) {
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

  Widget _buildDropdown(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
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

  // Apply extracted voice features to form fields
  void _applyExtractedFeatures(Map<String, String> features) {
    setState(() {
      if (features['name'] != null) _nameController.text = features['name']!;
      if (features['age'] != null) _ageController.text = features['age']!;
      if (features['phone'] != null) _phoneController.text = features['phone']!;
      if (features['address'] != null) _addressController.text = features['address']!;
      if (features['condition'] != null) _conditionController.text = features['condition']!;
      if (features['gender'] != null) _selectedGender = features['gender']!;
      if (features['priority'] != null) _selectedPriority = features['priority']!;
      if (features['category'] != null) _selectedCategory = features['category']!;
      if (features['aadhaar'] != null) _aadhaarController.text = features['aadhaar']!;
      if (features['abhaId'] != null) _abhaController.text = features['abhaId']!;
    });
  }

  // Quick random filler for demos/tests
  void _fillRandomValues() {
    setState(() {
      _nameController.text = 'Ravi Kumar';
      _ageController.text = '32';
      _selectedGender = 'Male';
      _phoneController.text = '9876543210';
      _addressController.text = '12 MG Road, Pune';
      _aadhaarController.text = '123412341234';
      _abhaController.text = 'ABHA12345';
      _conditionController.text = 'Fever and body ache';
      _selectedPriority = 'High';
      _selectedCategory = 'general';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filled with Random values for testing',
          style: const TextStyle(color: Colors.lightGreen),
        ),
      ),
    );
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
          'condition': _conditionController.text.trim().isEmpty
              ? 'General Checkup'
              : _conditionController.text.trim(),
          'priority': _selectedPriority,
          'category': _selectedCategory,
          'aadhaar': _aadhaarController.text.trim(),
          'abhaId': _abhaController.text.trim(),
          'lastVisit': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'nextVisit': '',
        };

        await _firestore.collection('patients').add(patientData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient registered successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error registering patient: $e')),
          );
        }
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
