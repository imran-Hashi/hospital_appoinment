import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _patients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getPatients();
      if (!mounted) return;
      setState(() {
        _patients = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showPatientDialog({Map<String, dynamic>? patient}) async {
    final bool isEdit = patient != null;
    final TextEditingController nameController =
        TextEditingController(text: patient?['full_name'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: patient?['phone'] ?? '');
    final TextEditingController ageController =
        TextEditingController(text: patient?['age']?.toString() ?? '');

    List<dynamic> users = [];
    int? selectedUserId = patient?['user_id'];
    String? selectedGender = patient?['gender'] ?? 'Male';
    bool dialogLoading = true;
    String? currentUserEmail;

    // Get logged-in user info if adding new patient
    if (!isEdit) {
      try {
        final userId = await _apiService.getCurrentUserId();
        final userEmail = await _apiService.getCurrentUserEmail();
        if (userId != null) {
          selectedUserId = userId;
          currentUserEmail = userEmail;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting user info: $e')));
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (dialogLoading && users.isEmpty) {
            _apiService.getUsers().then((results) {
              setDialogState(() {
                users = results;
                dialogLoading = false;
              });
            }).catchError((e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading users: $e')));
            });
            return const Center(child: CircularProgressIndicator());
          }

          return AlertDialog(
            title: Text(isEdit ? 'Update Patient' : 'Add Patient',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User Account Field - Non-editable for new patients, show email for edit
                  if (!isEdit)
                    TextFormField(
                      initialValue: currentUserEmail ?? 'Loading...',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'User Account',
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    TextFormField(
                      initialValue: users.firstWhere(
                        (u) => u['id'] == selectedUserId,
                        orElse: () => {'email': 'Unknown User'},
                      )['email'],
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'User Account',
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedGender = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedUserId == null || nameController.text.isEmpty)
                    return;
                  setDialogState(() => dialogLoading = true);
                  try {
                    final data = {
                      'user_id': selectedUserId,
                      'full_name': nameController.text,
                      'phone': phoneController.text,
                      'age': int.tryParse(ageController.text) ?? 0,
                      'gender': selectedGender,
                    };
                    if (isEdit) {
                      await _apiService.updatePatient(patient['id'], data);
                    } else {
                      await _apiService.createPatient(data);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    _fetchPatients();
                  } catch (e) {
                    setDialogState(() => dialogLoading = false);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B9BD5)),
                child: dialogLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Update' : 'Create',
                        style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(dynamic patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete patient ${patient['full_name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deletePatient(patient['id']);
                _fetchPatients();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patients',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Text(
                      'Manage hospital patient records',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPatientDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B9BD5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(dynamic patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF5B9BD5).withOpacity(0.1),
            radius: 20,
            child: const Icon(Icons.person, color: Color(0xFF5B9BD5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['full_name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient['gender']} • ${patient['age']} yrs • ${patient['phone']}',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (val) {
              if (val == 'edit') {
                _showPatientDialog(patient: patient);
              } else if (val == 'delete') {
                _confirmDelete(patient);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
