import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../widgets/profile_edit_screen.dart';
import '../onboarding/role_selection_screen.dart';
import '../patients/patient_screen.dart';
import 'package:asha_ehr_app/services/voice_service_singleton.dart';

class AshaDashboard extends StatefulWidget {
  const AshaDashboard({super.key});

  @override
  State<AshaDashboard> createState() => _AshaDashboardState();
}

class _AshaDashboardState extends State<AshaDashboard> {
  int _selectedIndex = 0;
  final _profileService = ProfileService();
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;
  bool _isListening = false;

  Map<String, dynamic> stats = {
    'totalPatients': 0,
    'highRisk': 0,
    'todayVisits': 0,
    'pending': 0,
    'reminders': 8,
    'campaigns': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPatientStats();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _profileService.getAshaProfile();
      if (mounted) {
        setState(() {
          _profileData = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadPatientStats() async {
    try {
      final patientsSnapshot = await _firestore.collection('patients').get();
      final patients = patientsSnapshot.docs;
      
      final today = DateTime.now();
      final todayString = "${today.year}-${today.month}-${today.day}";
      
      setState(() {
        stats['totalPatients'] = patients.length;
        stats['highRisk'] = patients.where((doc) {
          final patient = doc.data() as Map<String, dynamic>;
          return (patient['priority']?.toString().toLowerCase() == 'critical' ||
                  patient['priority']?.toString().toLowerCase() == 'high');
        }).length;
        stats['todayVisits'] = patients.where((doc) {
          final patient = doc.data() as Map<String, dynamic>;
          return patient['nextVisit']?.toString().contains(todayString) == true;
        }).length;
        stats['pending'] = patients.where((doc) {
          final patient = doc.data() as Map<String, dynamic>;
          return patient['nextVisit'] != null && 
                 patient['nextVisit']!.toString().isNotEmpty;
        }).length;
      });
    } catch (e) {
      print('Error loading patient stats: $e');
    }
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

  // --- VOICE COMMAND LOGIC ---
  Future<void> _startVoiceNavigation() async {
    setState(() => _isListening = true);
    await voiceService.init();
    await voiceService.startListening(
      onResult: (String command) {
        _handleVoiceCommand(command.trim().toLowerCase());
        setState(() => _isListening = false);
      },
      onError: (String? err) {
        _showError(err ?? "Unknown error");
        setState(() => _isListening = false);
      },
    );
  }

  void _handleVoiceCommand(String command) {
    if (command.contains("logout")) {
      voiceService.speak("Logging out");
      _showLogoutDialog();
    } else if (command.contains("patients")) {
      voiceService.speak("Opening patient list");
      setState(() => _selectedIndex = 1);
    } else if (command.contains("dashboard") || command.contains("home")) {
      voiceService.speak("Going to dashboard");
      setState(() => _selectedIndex = 0);
    } else if (command.contains("schedule") || command.contains("appointment")) {
      voiceService.speak("Opening schedule");
      setState(() => _selectedIndex = 2);
    } else if (command.contains("reminder")) {
      voiceService.speak("Showing reminders");
      setState(() => _selectedIndex = 2);
    } else if (command.contains("settings") || command.contains("more")) {
      voiceService.speak("More options");
      setState(() => _selectedIndex = 3);
    } else if (command.contains("profile")) {
      voiceService.speak("Opening profile editor");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEditScreen(
            role: 'ASHA',
            onProfileUpdated: _loadProfile,
          ),
        ),
      );
    } else if (command.contains("emergency")) {
      voiceService.speak("Emergency alert dialog opened");
      _showEmergency();
    } else if (command.contains("sync")) {
      voiceService.speak("Syncing data");
      _showSync();
    } else {
      voiceService.speak(
        "Command not recognized. Try saying dashboard, patients, schedule, reminders, profile, settings, or logout."
      );
      _showError(
        "Command not recognized. Try: dashboard, patients, schedule, reminders, profile, settings, or logout."
      );
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
      appBar: _buildAppBar(),
      body: _getSelectedPage(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_selectedIndex == 0) _buildFAB(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 100.0),
            child: FloatingActionButton(
              heroTag: "voiceNav",
              backgroundColor: _isListening ? Colors.red : AppColors.primary,
              onPressed: _isListening ? null : _startVoiceNavigation,
              tooltip: _isListening ? "Listening..." : "Voice Navigation",
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'ASHA Dashboard',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: _showNotifications,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '3',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          onPressed: _showSync,
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('My Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileEditScreen(
                    role: 'ASHA',
                    onProfileUpdated: _loadProfile,
                  ),
                ),
              );
            } else if (value == 'logout') {
              _showLogoutDialog();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'emergency',
          onPressed: _showEmergency,
          backgroundColor: AppColors.error,
          child: const Icon(Icons.emergency),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'voice',
          onPressed: _showVoiceInput,
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.mic),
        ),
      ],
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return PatientScreen();
      case 2:
        return _buildSchedulePage();
      case 3:
        return _buildMorePage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 24),
          Text(
            'Main Features',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeaturesGrid(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Priority Patients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPriorityPatientsFromFirestore(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final name = _profileData?['name'] ?? 'ASHA Worker';
    final village = _profileData?['village'] ?? 'Loading...';
    final ward = _profileData?['ward'] ?? '';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingProfile ? 'Loading...' : name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isLoadingProfile 
                        ? 'ASHA Worker' 
                        : 'ASHA Worker • $village${ward.isNotEmpty ? ', Ward $ward' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_isLoadingProfile)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: 'Today',
            value: '${stats['todayVisits']}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            label: 'Pending',
            value: '${stats['pending']}',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Total',
            value: '${stats['totalPatients']}',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {'title': 'Patients', 'icon': Icons.people, 'color': AppColors.primary, 'subtitle': '${stats['totalPatients']} Active'},
      {'title': 'High-Risk Alerts', 'icon': Icons.warning_amber, 'color': AppColors.highPriority, 'subtitle': '${stats['highRisk']} Critical'},
      {'title': 'Reports', 'icon': Icons.assessment, 'color': AppColors.pediatric, 'subtitle': 'View Stats'},
      {'title': 'Offline Sync', 'icon': Icons.sync, 'color': AppColors.info, 'subtitle': 'Synced 2h ago'},
      {'title': 'Voice Input', 'icon': Icons.mic, 'color': AppColors.accent, 'subtitle': 'Speak Now'},
      {'title': 'Growth Charts', 'icon': Icons.show_chart, 'color': AppColors.success, 'subtitle': 'Track Health'},
      {'title': 'Reminders', 'icon': Icons.notifications_active, 'color': AppColors.warning, 'subtitle': '${stats['reminders']} Upcoming'},
      {'title': 'Campaigns', 'icon': Icons.campaign, 'color': AppColors.maternal, 'subtitle': '${stats['campaigns']} Active'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          title: feature['title'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          subtitle: feature['subtitle'] as String,
          onTap: () => _showFeatureDialog(feature['title'] as String),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityPatientsFromFirestore() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patients')
          .where('priority', whereIn: ['Critical', 'High'])
          .orderBy('priority')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading priority patients');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoPriorityPatientsState();
        }

        final patients = snapshot.data!.docs;
        
        return Column(
          children: patients.map((doc) {
            final patient = doc.data() as Map<String, dynamic>;
            return _buildPatientCard(patient, doc.id);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, [String? documentId]) {
    final priority = patient['priority']?.toString() ?? 'Medium';
    final priorityColor = _getPriorityColor(priority);
    
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
                        patient['name'] ?? 'Unknown Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${patient['gender'] ?? 'Unknown'}, ${patient['age'] ?? 'Unknown'} years',
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
                    patient['condition'] ?? 'No condition specified',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Last: ${patient['lastVisit'] ?? 'Not recorded'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.event, size: 14, color: priorityColor),
                      const SizedBox(width: 6),
                      Text(
                        'Next: ${patient['nextVisit'] ?? 'Not scheduled'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoPriorityPatientsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            'No priority patients found',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(
              'Schedule & Reminders',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'View upcoming visits and follow-ups',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Options',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuTile(
            Icons.person,
            'My Profile',
            'View and edit profile',
            AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileEditScreen(
                    role: 'ASHA',
                    onProfileUpdated: _loadProfile,
                  ),
                ),
              );
            },
          ),
          _buildMenuTile(Icons.language, 'Language', 'English • हिंदी', AppColors.info),
          _buildMenuTile(Icons.bar_chart, 'Performance', 'View stats', AppColors.success),
          _buildMenuTile(Icons.help, 'Help', 'Support', AppColors.warning),
          _buildMenuTile(Icons.settings, 'Settings', 'Preferences', AppColors.textSecondary),
          const SizedBox(height: 12),
          _buildMenuTile(
            Icons.logout,
            'Logout',
            'Sign out',
            AppColors.error,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    {VoidCallback? onTap}
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap ?? () {},
      ),
    );
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This feature allows you to manage $feature efficiently.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature opened!')));
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: AppColors.error),
              title: Text('High-risk patient needs attention', style: GoogleFonts.inter(fontSize: 13)),
              dense: true,
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Data synced successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Emergency', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Send emergency alert to PHC?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency alert sent!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showVoiceInput() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voice Input', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 60, color: AppColors.secondary),
            const SizedBox(height: 16),
            const Text('Speak now...'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}