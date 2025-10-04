// maternal_registration_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';

class MaternalRegistrationForm extends StatefulWidget {
  const MaternalRegistrationForm({super.key});

  @override
  State<MaternalRegistrationForm> createState() => _MaternalRegistrationFormState();
}

class _MaternalRegistrationFormState extends State<MaternalRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Family Records
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _motherAgeController = TextEditingController();
  final TextEditingController _husbandNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();
  final TextEditingController _husbandPhoneController = TextEditingController();
  final TextEditingController _mctsIdController = TextEditingController();
  final TextEditingController _abhaIdController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  // Maternal Records
  final TextEditingController _lmpController = TextEditingController();
  final TextEditingController _eddController = TextEditingController();
  final TextEditingController _pregnancyCountController = TextEditingController();
  final TextEditingController _childrenBornController = TextEditingController();
  final TextEditingController _prevDeliveryController = TextEditingController();
  final TextEditingController _currentDeliveryController = TextEditingController();

  // Hospital Records
  final TextEditingController _anganwadiIdController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _ashaNameController = TextEditingController();
  final TextEditingController _anmNameController = TextEditingController();
  final TextEditingController _shcController = TextEditingController();
  final TextEditingController _phcController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _anmPhoneController = TextEditingController();
  final TextEditingController _ashaPhoneController = TextEditingController();
  final TextEditingController _hospitalPhoneController = TextEditingController();
  final TextEditingController _awcRegController = TextEditingController();

  DateTime? _selectedLMP;
  DateTime? _selectedEDD;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maternal Registration', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.maternal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Family Records'),
              _buildTextField(_motherNameController, 'Mother\'s Name', Icons.person, true),
              _buildTextField(_motherAgeController, 'Mother\'s Age', Icons.cake, true, TextInputType.number),
              _buildTextField(_husbandNameController, 'Husband\'s Name', Icons.person_outline, false),
              _buildTextField(_addressController, 'House Address', Icons.location_on, true),
              _buildTextField(_motherPhoneController, 'Mother\'s Phone No', Icons.phone, false, TextInputType.phone),
              _buildTextField(_husbandPhoneController, 'Husband\'s Phone No', Icons.phone, false, TextInputType.phone),
              _buildTextField(_mctsIdController, 'MCTS/RCH ID', Icons.badge, false),
              _buildTextField(_abhaIdController, 'ABHA ID', Icons.health_and_safety, false),
              _buildTextField(_bankNameController, 'Bank Name with Branch', Icons.account_balance, false),
              _buildTextField(_accountNoController, 'Account No', Icons.credit_card, false),
              _buildTextField(_ifscController, 'IFSC Code', Icons.code, false),

              _buildSectionHeader('Maternal Records'),
              _buildDateField(_lmpController, 'Last Menstrual Period (LMP)', _selectedLMP, () => _selectDate(context, _lmpController, true)),
              _buildDateField(_eddController, 'Expected Delivery Date (EDD)', _selectedEDD, () => _selectDate(context, _eddController, false)),
              _buildTextField(_pregnancyCountController, 'Total Number of Pregnancies', Icons.child_friendly, false, TextInputType.number),
              _buildTextField(_childrenBornController, 'Children Born from Registered Pregnancies', Icons.child_care, false, TextInputType.number),
              _buildTextField(_prevDeliveryController, 'Place of Previous Delivery', Icons.place, false),
              _buildTextField(_currentDeliveryController, 'Place of Current Delivery', Icons.place, false),

              _buildSectionHeader('Hospital Records'),
              _buildTextField(_anganwadiIdController, 'Anganwadi Worker ID', Icons.work, false),
              _buildTextField(_blockController, 'Block/Village/Ward', Icons.map, false),
              _buildTextField(_ashaNameController, 'ASHA Name', Icons.person, false),
              _buildTextField(_anmNameController, 'ANM Name', Icons.person, false),
              _buildTextField(_shcController, 'SHC/VHC Clinic (Name & Phone)', Icons.medical_services, false),
              _buildTextField(_phcController, 'PHC/Town', Icons.location_city, false),
              _buildTextField(_hospitalController, 'Hospital/FRU', Icons.local_hospital, false),
              _buildTextField(_anmPhoneController, 'ANM Phone', Icons.phone, false, TextInputType.phone),
              _buildTextField(_ashaPhoneController, 'ASHA Phone', Icons.phone, false, TextInputType.phone),
              _buildTextField(_hospitalPhoneController, 'Hospital Phone', Icons.phone, false, TextInputType.phone),
              _buildTextField(_awcRegController, 'AWC Registration No', Icons.app_registration, false),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maternal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Register Maternal Patient',
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, DateTime? selectedDate, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate != null 
                  ? DateFormat('dd/MM/yyyy').format(selectedDate)
                  : 'Select Date',
                style: GoogleFonts.inter(
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isLMP) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: isLMP ? DateTime(2000) : DateTime.now(),
      lastDate: isLMP ? DateTime.now() : DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isLMP) {
          _selectedLMP = picked;
          // Calculate EDD (LMP + 280 days)
          _selectedEDD = picked.add(Duration(days: 280));
          _eddController.text = DateFormat('dd/MM/yyyy').format(_selectedEDD!);
        } else {
          _selectedEDD = picked;
        }
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final maternalData = {
          // Family Records
          'motherName': _motherNameController.text,
          'motherAge': _motherAgeController.text,
          'husbandName': _husbandNameController.text,
          'address': _addressController.text,
          'motherPhone': _motherPhoneController.text,
          'husbandPhone': _husbandPhoneController.text,
          'mctsRchId': _mctsIdController.text,
          'abhaId': _abhaIdController.text,
          'bankName': _bankNameController.text,
          'accountNo': _accountNoController.text,
          'ifscCode': _ifscController.text,

          // Maternal Records
          'lmp': _lmpController.text,
          'edd': _eddController.text,
          'pregnancyCount': _pregnancyCountController.text,
          'childrenBorn': _childrenBornController.text,
          'prevDeliveryPlace': _prevDeliveryController.text,
          'currentDeliveryPlace': _currentDeliveryController.text,

          // Hospital Records
          'anganwadiWorkerId': _anganwadiIdController.text,
          'blockVillageWard': _blockController.text,
          'ashaName': _ashaNameController.text,
          'anmName': _anmNameController.text,
          'shcVhc': _shcController.text,
          'phcTown': _phcController.text,
          'hospitalFru': _hospitalController.text,
          'anmPhone': _anmPhoneController.text,
          'ashaPhone': _ashaPhoneController.text,
          'hospitalPhone': _hospitalPhoneController.text,
          'awcRegNo': _awcRegController.text,

          // System fields
          'category': 'pregnant_women',
          'priority': 'High',
          'createdAt': FieldValue.serverTimestamp(),
          'lastVisit': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('patients').add(maternalData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maternal patient registered successfully!')),
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
    // Dispose all controllers
    _motherNameController.dispose();
    _motherAgeController.dispose();
    _husbandNameController.dispose();
    _addressController.dispose();
    _motherPhoneController.dispose();
    _husbandPhoneController.dispose();
    _mctsIdController.dispose();
    _abhaIdController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _lmpController.dispose();
    _eddController.dispose();
    _pregnancyCountController.dispose();
    _childrenBornController.dispose();
    _prevDeliveryController.dispose();
    _currentDeliveryController.dispose();
    _anganwadiIdController.dispose();
    _blockController.dispose();
    _ashaNameController.dispose();
    _anmNameController.dispose();
    _shcController.dispose();
    _phcController.dispose();
    _hospitalController.dispose();
    _anmPhoneController.dispose();
    _ashaPhoneController.dispose();
    _hospitalPhoneController.dispose();
    _awcRegController.dispose();
    super.dispose();
  }
}