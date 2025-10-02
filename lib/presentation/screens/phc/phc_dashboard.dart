import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../services/storage_service.dart';
import '../onboarding/role_selection_screen.dart';

class PHCDashboard extends StatefulWidget {
  const PHCDashboard({super.key});

  @override
  State<PHCDashboard> createState() => _PHCDashboardState();
}

class _PHCDashboardState extends State<PHCDashboard> {
  int _selectedIndex = 0;

  final Map<String, dynamic> phcStats = {
    'totalPatients': 342,
    'highRisk': 15,
    'ashaWorkers': 12,
    'villages': 8,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PHC Dashboard'),
        backgroundColor: AppColors.secondary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildReportsPage();
      case 2:
        return _buildInventoryPage();
      case 3:
        return _buildSettingsPage();
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
          _buildHeaderCard(),
          const SizedBox(height: 20),
          Text(
            'Quick Access',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAccessGrid(),
          const SizedBox(height: 24),
          Text(
            'Statistics Overview',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
  return Card(
    child: Container(
      width: double.infinity, // Make it full width
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          const Icon(Icons.local_hospital, size: 50, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'Primary Health Centre',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center, // Center text
          ),
          const SizedBox(height: 4),
          Text(
            'Rampur District',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center, // Center text
          ),
        ],
      ),
    ),
  );
}


  Widget _buildQuickAccessGrid() {
    final options = [
      {'title': 'Patient Overview', 'icon': Icons.people, 'color': AppColors.primary},
      {'title': 'Reports & Analytics', 'icon': Icons.assessment, 'color': AppColors.info},
      {'title': 'Manage ASHA Workers', 'icon': Icons.groups, 'color': AppColors.secondary},
      {'title': 'Campaign Management', 'icon': Icons.campaign, 'color': AppColors.maternal},
      {'title': 'Medicine Stock', 'icon': Icons.inventory_2, 'color': AppColors.warning},
      {'title': 'Health Trends', 'icon': Icons.trending_up, 'color': AppColors.success},
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
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _buildOptionCard(
          title: option['title'] as String,
          icon: option['icon'] as IconData,
          color: option['color'] as Color,
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: () => _showFeatureDialog(title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Patients', '${phcStats['totalPatients']}', Icons.people, AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('High Risk', '${phcStats['highRisk']}', Icons.warning, AppColors.error),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 100, color: AppColors.secondary.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text('Reports & Analytics', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInventoryPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 100, color: AppColors.warning.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text('Medicine Inventory', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature functionality will be available here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
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
              await StorageService.clearAll();
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
