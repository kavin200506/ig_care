import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import 'patient_registration_form.dart';
import 'maternal_registration_form.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Register New Patient',
      'icon': Icons.person_add,
      'color': AppColors.primary,
      'subtitle': 'Add new patient record',
      'category': 'registration'
    },
    {
      'title': 'Pregnant Women',
      'icon': Icons.pregnant_woman,
      'color': AppColors.maternal,
      'subtitle': 'ANC & PNC care',
      'category': 'pregnant_women'
    },
    {
      'title': 'Child Health',
      'icon': Icons.child_care,
      'color': AppColors.pediatric,
      'subtitle': '0-5 years care',
      'category': 'child_health'
    },
    {
      'title': 'Common Diseases',
      'icon': Icons.medical_services,
      'color': AppColors.highPriority,
      'subtitle': 'Fever, Diarrhea, etc.',
      'category': 'common_diseases'
    },
    {
      'title': 'Family Planning',
      'icon': Icons.family_restroom,
      'color': AppColors.info,
      'subtitle': 'Contraception services',
      'category': 'family_planning'
    },
    {
      'title': 'Immunization',
      'icon': Icons.medical_information,
      'color': AppColors.success,
      'subtitle': 'Vaccination schedule',
      'category': 'immunization'
    },
    {
      'title': 'Elderly Care',
      'icon': Icons.elderly,
      'color': AppColors.warning,
      'subtitle': 'Senior citizen care',
      'category': 'elderly_care'
    },
    {
      'title': 'Chronic Diseases',
      'icon': Icons.monitor_heart,
      'color': AppColors.criticalPriority,
      'subtitle': 'Diabetes, Hypertension',
      'category': 'chronic_diseases'
    },
  ];

  // Helper method to get priority color
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Patient Management',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage all patient records and services',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Grid
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),

            // Category Filter Chip
            if (_selectedCategory != 'All') ...[
              _buildCategoryFilterChip(),
              const SizedBox(height: 16),
            ],

            // Search and Filter Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or condition...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items: ['All', 'Critical', 'High', 'Medium', 'Low']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedFilter = value!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Patient List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == 'All'
                      ? 'Patient List'
                      : '${_getCategoryDisplayName(_selectedCategory)} Patients',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _showExportOptions,
                  child: Row(
                    children: [
                      Icon(Icons.import_export,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Export',
                          style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Patient List from Firestore
            _buildPatientList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return _buildQuickActionCard(
          title: action['title'] as String,
          icon: action['icon'] as IconData,
          color: action['color'] as Color,
          subtitle: action['subtitle'] as String,
          onTap: () => _handleQuickAction(
              action['category'] as String, action['title'] as String),
        );
      },
    );
  }

  Widget _buildCategoryFilterChip() {
    return Chip(
      label: Text(
        'Category: ${_getCategoryDisplayName(_selectedCategory)}',
        style: GoogleFonts.inter(fontSize: 12),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      deleteIcon: Icon(Icons.close, size: 16),
      onDeleted: () => setState(() => _selectedCategory = 'All'),
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
        return 'All';
    }
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title.split(' ').first,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('patients').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading patients: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final patients = snapshot.data!.docs;
        final filteredPatients = _filterPatients(patients);

        if (filteredPatients.isEmpty) {
          return _buildNoResultsState();
        }

        return Column(
          children: filteredPatients.map((doc) {
            final patient = doc.data() as Map<String, dynamic>;
            return _buildPatientCard(patient, doc.id);
          }).toList(),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterPatients(
      List<QueryDocumentSnapshot> patients) {
    return patients.where((doc) {
      final patient = doc.data() as Map<String, dynamic>;
      final name = patient['name']?.toString().toLowerCase() ?? '';
      final condition = patient['condition']?.toString().toLowerCase() ?? '';
      final priority = patient['priority']?.toString() ?? '';
      final category = patient['category']?.toString() ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          condition.contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          priority.toLowerCase() == _selectedFilter.toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All' || category == _selectedCategory;

      return matchesSearch && matchesFilter && matchesCategory;
    }).toList();
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, String documentId) {
    final priority = patient['priority']?.toString() ?? 'Medium';
    final priorityColor = _getPriorityColor(priority);

    // Safe data extraction with null checks
    final name = patient['name']?.toString() ?? 'Unknown Patient';
    final gender = patient['gender']?.toString() ?? 'Unknown';
    final age = patient['age']?.toString() ?? 'Unknown';
    final condition =
        patient['condition']?.toString() ?? 'No condition specified';
    final lastVisit = _formatDate(patient['lastVisit']) ?? 'Not recorded';
    final nextVisit = _formatDate(patient['nextVisit']) ?? 'Not scheduled';
    final phone = patient['phone']?.toString();
    final address = patient['address']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: priorityColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$gender, $age years • ${_formatDocumentId(documentId)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Last: $lastVisit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.event, size: 14, color: priorityColor),
                      const SizedBox(width: 6),
                      Text(
                        'Next: $nextVisit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (phone != null || address != null)
                    Row(
                      children: [
                        if (phone != null) ...[
                          Icon(Icons.phone,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                        ],
                        if (address != null) ...[
                          Icon(Icons.location_on,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewPatientDetails(patient, documentId),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, size: 16),
                        SizedBox(width: 4),
                        Text('View Details'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _scheduleVisit(patient, documentId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 4),
                        Text('Schedule Visit'),
                      ],
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

  // Helper method to format dates safely
  String? _formatDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is Timestamp) {
      return _formatTimestamp(dateValue);
    } else if (dateValue is String) {
      return dateValue;
    } else if (dateValue is DateTime) {
      return '${dateValue.day}/${dateValue.month}/${dateValue.year}';
    }

    return dateValue.toString();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDocumentId(String documentId) {
    return documentId.length > 8
        ? '${documentId.substring(0, 8)}...'
        : documentId;
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading patients...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first patient to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddPatientDialog,
              child: const Text('Add New Patient'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No matching patients',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 80, color: AppColors.error.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Unable to load patients',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String category, String title) {
    if (category == 'registration') {
      _showAddPatientDialog();
    } else {
      setState(() {
        _selectedCategory = category;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Showing $title patients')),
      );
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Register New Patient',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Select the type of patient to register:'),
        actions: [
          // Main action buttons
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAddPatientForm();
                      },
                      icon: Icon(Icons.person_add,
                          size: 40, color: AppColors.primary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('General', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToMaternalForm();
                      },
                      icon: Icon(Icons.pregnant_woman,
                          size: 40, color: AppColors.maternal),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.maternal.withOpacity(0.1),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Maternal', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPatientForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientRegistrationForm(),
      ),
    );
  }

  void _navigateToMaternalForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaternalRegistrationForm(),
      ),
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient, String documentId) {
    // Safe data extraction
    final name = patient['name']?.toString() ?? 'Unknown';
    final age = patient['age']?.toString() ?? 'Unknown';
    final gender = patient['gender']?.toString() ?? 'Unknown';
    final condition = patient['condition']?.toString() ?? 'Not specified';
    final phone = patient['phone']?.toString();
    final address = patient['address']?.toString();
    final lastVisit = _formatDate(patient['lastVisit']) ?? 'Not recorded';
    final nextVisit = _formatDate(patient['nextVisit']) ?? 'Not scheduled';
    final priority = patient['priority']?.toString() ?? 'Medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name', style: GoogleFonts.inter()),
              Text('Age: $age years', style: GoogleFonts.inter()),
              Text('Gender: $gender', style: GoogleFonts.inter()),
              Text('Condition: $condition', style: GoogleFonts.inter()),
              if (phone != null)
                Text('Phone: $phone', style: GoogleFonts.inter()),
              if (address != null)
                Text('Address: $address', style: GoogleFonts.inter()),
              Text('Last Visit: $lastVisit', style: GoogleFonts.inter()),
              Text('Next Visit: $nextVisit', style: GoogleFonts.inter()),
              Text('Priority: $priority', style: GoogleFonts.inter()),
              Text('Patient ID: ${_formatDocumentId(documentId)}',
                  style: GoogleFonts.inter()),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _scheduleVisit(Map<String, dynamic> patient, String documentId) {
    final name = patient['name']?.toString() ?? 'Patient';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Visit for $name',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Select date and time for the next visit.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateNextVisit(documentId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Visit scheduled for $name!')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNextVisit(String documentId) async {
    try {
      final nextVisitDate = DateTime.now().add(const Duration(days: 7));
      final formattedDate =
          '${nextVisitDate.day}/${nextVisitDate.month}/${nextVisitDate.year}';

      await _firestore.collection('patients').doc(documentId).update({
        'nextVisit': formattedDate,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling visit: $e')),
      );
    }
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Patient Data',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting as PDF...')));
              },
              child: const Text('PDF')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting as Excel...')));
              },
              child: const Text('Excel')),
        ],
      ),
    );
  }
}
