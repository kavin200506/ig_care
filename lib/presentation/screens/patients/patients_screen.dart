import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/patient_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';
  String? _selectedGender;
  String? _selectedPatientCategory;
  bool _isLoading = false;
  bool _firestoreConnected = true;

  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Register Patient',
      'icon': Icons.person_add,
      'color': AppColors.primary,
      'type': 'register'
    },
    {
      'title': 'Pregnant',
      'icon': Icons.pregnant_woman,
      'color': AppColors.maternal,
      'type': 'pregnant'
    },
    {
      'title': 'Child Health',
      'icon': Icons.child_care,
      'color': AppColors.pediatric,
      'type': 'child'
    },
    {
      'title': 'Common Disease',
      'icon': Icons.medical_services,
      'color': AppColors.info,
      'type': 'common_disease'
    },
  ];

  @override
  void initState() {
    super.initState();
    _testFirestoreConnection();
  }

  void _testFirestoreConnection() async {
    final connected = await _patientService.testConnection();
    setState(() {
      _firestoreConnected = connected;
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.criticalPriority;
      case 'high':
        return AppColors.highPriority;
      case 'medium':
        return AppColors.mediumPriority;
      case 'low':
        return AppColors.lowPriority;
      default:
        return AppColors.mediumPriority;
    }
  }

  Map<String, dynamic> _formatPatientData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    print('Patient data from Firestore: $data'); // Debug print
    
    return {
      'id': doc.id,
      'name': data['name'] ?? 'Unknown',
      'age': data['age']?.toString() ?? '',
      'gender': data['gender'] ?? '',
      'condition': data['condition'] ?? '',
      'priority': data['priority'] ?? 'Medium',
      'priorityColor': _getPriorityColor(data['priority'] ?? 'Medium'),
      'phone': data['phone'] ?? '',
      'address': data['address'] ?? '',
      'category': data['category'] ?? 'common_disease',
      'ashaWorkerId': data['ashaWorkerId'] ?? '',
    };
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _addressController.clear();
    _conditionController.clear();
    _selectedGender = null;
    _selectedPatientCategory = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Patients',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (!_firestoreConnected)
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => setState(() {}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addNewPatient,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      hintStyle: GoogleFonts.inter(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          
          // Category Icons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: categories.map((category) {
                    return _buildCategoryIcon(
                      icon: category['icon'] as IconData,
                      title: category['title'] as String,
                      color: category['color'] as Color,
                      type: category['type'] as String,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Critical'),
                      _buildFilterChip('High'),
                      _buildFilterChip('Medium'),
                      _buildFilterChip('Low'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Connection Status
          if (!_firestoreConnected)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firestore connection issue. Data may not sync.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Patients List
          Expanded(
            child: _buildPatientsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPatient,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPatientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedCategory == 'All' 
          ? _patientService.getPatientsStream()
          : _patientService.getPatientsByCategory(_selectedCategory),
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}'); // Debug
        print('StreamBuilder hasData: ${snapshot.hasData}'); // Debug
        print('StreamBuilder error: ${snapshot.error}'); // Debug
        
        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No patients found in Firestore');
          return _buildEmptyState();
        }

        final patients = snapshot.data!.docs.map(_formatPatientData).toList();
        print('Found ${patients.length} patients'); // Debug

        // Apply search filter
        final filteredPatients = patients.where((patient) {
          final nameMatch = patient['name'].toLowerCase().contains(_searchQuery.toLowerCase());
          final conditionMatch = patient['condition'].toLowerCase().contains(_searchQuery.toLowerCase());
          return nameMatch || conditionMatch;
        }).toList();

        // Apply priority filter
        final priorityFilteredPatients = _selectedFilter == 'All'
            ? filteredPatients
            : filteredPatients.where((patient) => patient['priority'] == _selectedFilter).toList();

        if (priorityFilteredPatients.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: priorityFilteredPatients.length,
          itemBuilder: (context, index) {
            final patient = priorityFilteredPatients[index];
            return _buildPatientCard(patient);
          },
        );
      },
    );
  }

  Widget _buildCategoryIcon({
    required IconData icon,
    required String title,
    required Color color,
    required String type,
  }) {
    final isSelected = _selectedCategory == type;
    return GestureDetector(
      onTap: () => _onCategorySelected(type),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = label),
        checkmarkColor: Colors.white,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey[100],
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (patient['priorityColor'] as Color).withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: patient['priorityColor'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${patient['gender']}, ${patient['age']} years',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (patient['priorityColor'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    patient['priority'].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: patient['priorityColor'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              patient['condition'],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  patient['phone'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient['address'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${patient['category']}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading patients...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Patients',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 60,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Patients Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Register your first patient to get started'
                  : 'No patients match your search',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add First Patient'),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (category == 'register') {
        _addNewPatient();
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _addNewPatient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Register New Patient',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildRegistrationForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Text(
            'Medical Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: _selectedPatientCategory,
            decoration: InputDecoration(
              labelText: 'Patient Category *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(value: 'pregnant', child: Text('Pregnant Woman')),
              DropdownMenuItem(value: 'child', child: Text('Child Health')),
              DropdownMenuItem(value: 'common_disease', child: Text('Common Disease')),
            ],
            onChanged: (value) => setState(() => _selectedPatientCategory = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _conditionController,
            decoration: InputDecoration(
              labelText: 'Medical Condition *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Register Patient',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _registerPatient() async {
    // Validate required fields
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _selectedGender == null ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedPatientCategory == null ||
        _conditionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patientData = {
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender!,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'category': _selectedPatientCategory!,
        'condition': _conditionController.text,
        'priority': 'Medium',
      };

      await _patientService.addPatient(patientData);
      
      // Success - close form and show message
      Navigator.pop(context);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Force refresh the list
      setState(() {});
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register patient: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _conditionController.dispose();
    super.dispose();
  }
}