// patient_registration_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../utils/colors.dart';

class PatientRegistrationForm extends StatefulWidget {
  const PatientRegistrationForm({super.key, this.autoOpenVoice = false});

  final bool autoOpenVoice;

  @override
  State<PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

// Demo Voice Panel with PHC Staff Perspective
class _VoiceInlinePanel extends StatefulWidget {
  final bool autoStart;
  final ValueChanged<Map<String, String>> onExtract;
  const _VoiceInlinePanel({required this.autoStart, required this.onExtract});

  @override
  State<_VoiceInlinePanel> createState() => _VoiceInlinePanelState();
}

class _VoiceInlinePanelState extends State<_VoiceInlinePanel> {
  bool _isTyping = false;
  bool _isExtracting = false;
  String _realTimeText = '';
  
  // PHC Staff speaking demo data (more formal/clinical)
  final String _demoText = 
      "Patient's name is Priya Sharma. Age is 28 years. Female. "
      "Phone number 9876543210. "
      "Address Rampur Village, Ward 3, Coimbatore District, Tamil Nadu. "
      "Patient is complaining of high fever, severe body pain, and headache for past 3 days. "
      "This appears to be a high-risk pregnancy case in her 8th month. "
      "Aadhaar number is 456789012345.";

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startDemo());
    }
  }

  Future<void> _startDemo() async {
    setState(() {
      _isTyping = true;
      _realTimeText = '';
    });

    // Slower typing: 80ms per character (more realistic for speech)
    for (int i = 0; i < _demoText.length; i++) {
      if (!_isTyping) break;
      
      // Variable speed: faster for spaces, slower for punctuation
      int delay = 80;
      if (_demoText[i] == ' ') {
        delay = 60;
      } else if (_demoText[i] == '.' || _demoText[i] == ',') {
        delay = 200; // Pause at punctuation
      }
      
      await Future.delayed(Duration(milliseconds: delay));
      
      if (mounted) {
        setState(() {
          _realTimeText = _demoText.substring(0, i + 1);
        });
      }
    }

    if (mounted) {
      setState(() => _isTyping = false);
    }
  }

  void _stopDemo() {
    setState(() => _isTyping = false);
  }

  String _generateAbhaId() {
    final random = Random();
    final year = DateTime.now().year.toString().substring(2);
    final randomDigits = List.generate(10, (_) => random.nextInt(10)).join();
    return '$year-$randomDigits';
  }

  String _detectCategory(String text) {
    final lower = text.toLowerCase();
    
    // Category detection based on keywords
    if (lower.contains('pregnant') || lower.contains('pregnancy') || lower.contains('delivery')) {
      return 'pregnant_women';
    } else if (lower.contains('child') || lower.contains('baby') || lower.contains('infant') || 
               (lower.contains('year') && (lower.contains('1 ') || lower.contains('2 ') || lower.contains('3 ')))) {
      return 'child_health';
    } else if (lower.contains('vaccination') || lower.contains('vaccine') || lower.contains('immunization')) {
      return 'immunization';
    } else if (lower.contains('elderly') || lower.contains('old age') || 
               (lower.contains('year') && (lower.contains('60') || lower.contains('70') || lower.contains('80')))) {
      return 'elderly_care';
    } else if (lower.contains('diabetes') || lower.contains('hypertension') || 
               lower.contains('blood pressure') || lower.contains('sugar')) {
      return 'chronic_diseases';
    } else if (lower.contains('fever') || lower.contains('cold') || lower.contains('cough') || 
               lower.contains('diarrhea') || lower.contains('headache')) {
      return 'common_diseases';
    } else if (lower.contains('family planning') || lower.contains('contraceptive')) {
      return 'family_planning';
    }
    
    return 'general';
  }

  Future<void> _extract() async {
    if (_realTimeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No voice input recorded!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isExtracting = true);

    // Simulate AI processing with progress
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Analyzing voice input...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.info,
        ),
      );
    }
    
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // Auto-detect category
      final detectedCategory = _detectCategory(_realTimeText);
      
      // Extract features with enhanced data
      final features = {
        'name': 'Priya Sharma',
        'age': '28',
        'gender': 'Female',
        'phone': '9876543210',
        'address': 'Rampur Village, Ward 3, Coimbatore District, Tamil Nadu',
        'condition': 'High fever, severe body pain, and headache for 3 days. High-risk pregnancy (8 months)',
        'priority': 'Critical', // High-risk pregnancy
        'aadhaar': '456789012345',
        'abhaId': _generateAbhaId(), // Auto-generate ABHA ID
        'category': detectedCategory,
      };

      widget.onExtract(features);
      
      setState(() => _isExtracting = false);

      // Show detailed success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                'Extraction Complete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ AI successfully extracted and filled:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildExtractedField('Name', features['name']!),
              _buildExtractedField('Age', features['age']!),
              _buildExtractedField('Gender', features['gender']!),
              _buildExtractedField('Phone', features['phone']!),
              _buildExtractedField('Category', _getCategoryName(features['category']!)),
              _buildExtractedField('Priority', features['priority']!),
              _buildExtractedField('ABHA ID', features['abhaId']!, isGenerated: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All fields auto-filled from voice',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildExtractedField(String label, String value, {bool isGenerated = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                  if (isGenerated)
                    TextSpan(
                      text: ' (auto)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'pregnant_women': return 'Pregnant Women';
      case 'child_health': return 'Child Health';
      case 'common_diseases': return 'Common Diseases';
      case 'family_planning': return 'Family Planning';
      case 'immunization': return 'Immunization';
      case 'elderly_care': return 'Elderly Care';
      case 'chronic_diseases': return 'Chronic Diseases';
      default: return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.record_voice_over, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHC Staff Voice Input',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'AI-powered patient data extraction',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'DEMO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Voice Text Display
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isTyping ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isTyping)
                      Container(
                        margin: const EdgeInsets.only(right: 6, top: 2),
                        child: Icon(Icons.mic, color: Colors.green, size: 14),
                      ),
                    Expanded(
                      child: Text(
                        _realTimeText.isEmpty 
                            ? '> Press START to simulate PHC staff voice input...' 
                            : '> $_realTimeText',
                        style: GoogleFonts.robotoMono(
                          color: Colors.green,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Extraction Status
            if (_isExtracting)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.info),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI is extracting patient data & auto-detecting category...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isTyping ? _stopDemo : _startDemo,
                    icon: Icon(
                      _isTyping ? Icons.stop : Icons.mic,
                      size: 16,
                    ),
                    label: Text(_isTyping ? 'Stop' : 'Start Voice'),
                    style: TextButton.styleFrom(
                      foregroundColor: _isTyping ? Colors.red : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_realTimeText.isEmpty || _isExtracting) ? null : _extract,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Extract & Fill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
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
          // Demo Badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.science, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'DEMO',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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

  void _applyExtractedFeatures(Map<String, String> features) {
    setState(() {
      if (features['name'] != null && features['name']!.isNotEmpty) {
        _nameController.text = features['name']!;
      }
      if (features['age'] != null && features['age']!.isNotEmpty) {
        _ageController.text = features['age']!;
      }
      if (features['phone'] != null && features['phone']!.isNotEmpty) {
        _phoneController.text = features['phone']!;
      }
      if (features['address'] != null && features['address']!.isNotEmpty) {
        _addressController.text = features['address']!;
      }
      if (features['condition'] != null && features['condition']!.isNotEmpty) {
        _conditionController.text = features['condition']!;
      }
      if (features['gender'] != null && features['gender']!.isNotEmpty) {
        _selectedGender = features['gender']!;
      }
      if (features['priority'] != null && features['priority']!.isNotEmpty) {
        _selectedPriority = features['priority']!;
      }
      if (features['category'] != null && features['category']!.isNotEmpty) {
        _selectedCategory = features['category']!;
      }
      if (features['aadhaar'] != null && features['aadhaar']!.isNotEmpty) {
        _aadhaarController.text = features['aadhaar']!;
      }
      if (features['abhaId'] != null && features['abhaId']!.isNotEmpty) {
        _abhaController.text = features['abhaId']!;
      }
    });
  }

  void _fillRandomValues() {
    final random = Random();
    final year = DateTime.now().year.toString().substring(2);
    final randomDigits = List.generate(10, (_) => random.nextInt(10)).join();
    
    setState(() {
      _nameController.text = 'Rajesh Kumar';
      _ageController.text = '42';
      _selectedGender = 'Male';
      _phoneController.text = '9876543210';
      _addressController.text = 'Govindpur Village, Coimbatore';
      _aadhaarController.text = '789012345678';
      _abhaController.text = '$year-$randomDigits';
      _conditionController.text = 'Diabetes monitoring - blood sugar levels high';
      _selectedPriority = 'Medium';
      _selectedCategory = 'chronic_diseases';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Filled with random test values'),
        backgroundColor: Colors.green,
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
            const SnackBar(
              content: Text('✅ Patient registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error registering patient: $e'),
              backgroundColor: Colors.red,
            ),
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
