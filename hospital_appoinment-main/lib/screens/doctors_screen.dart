import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}



  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = data;
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

  void _showDoctorDialog({Map<String, dynamic>? doctor}) async {
    final bool isEdit = doctor != null;
    final TextEditingController nameController =
        TextEditingController(text: doctor?['full_name'] ?? '');
    final TextEditingController specController =
        TextEditingController(text: doctor?['specialization'] ?? '');
    final TextEditingController feeController = TextEditingController(
        text: doctor?['consultation_fee']?.toString() ?? '');

    List<dynamic> users = [];
    List<dynamic> depts = [];
    int? selectedUserId = doctor?['user_id'];
    int? selectedDeptId = doctor?['department_id'];
    bool dialogLoading = true;
    String? currentUserEmail;

    // Get logged-in user info if adding new doctor
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
            Future.wait([
              _apiService.getUsers(),
              _apiService.getDepartments(),
            ]).then((results) {
              setDialogState(() {
                users = results[0];
                depts = results[1];
                dialogLoading = false;
              });
            }).catchError((e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading data: $e')));
            });
            return const Center(child: CircularProgressIndicator());
          }

          return AlertDialog(
            title: Text(isEdit ? 'Update Doctor' : 'Add Doctor',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User Account Field - Non-editable for new doctors, show email for edit
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
                  DropdownButtonFormField<int>(
                    value: selectedDeptId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: depts
                        .map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                            value: d['id'], child: Text(d['name'])))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedDeptId = v),
                  ),
                  TextField(
                    controller: specController,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                  ),
                  TextField(
                    controller: feeController,
                    decoration:
                        const InputDecoration(labelText: 'Consultation Fee'),
                    keyboardType: TextInputType.number,
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
                  if (selectedUserId == null || selectedDeptId == null) return;
                  setDialogState(() => dialogLoading = true);
                  try {
                    final data = {
                      'user_id': selectedUserId,
                      'department_id': selectedDeptId,
                      'full_name': nameController.text,
                      'specialization': specController.text,
                      'consultation_fee':
                          double.tryParse(feeController.text) ?? 0,
                    };
                    if (isEdit) {
                      await _apiService.updateDoctor(doctor['id'], data);
                    } else {
                      await _apiService.createDoctor(data);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    _fetchDoctors();
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

  void _confirmDelete(dynamic doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete Dr. ${doctor['full_name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteDoctor(doctor['id']);
                _fetchDoctors();
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
                      'Doctors',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Text(
                      'Manage hospital medical staff',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDoctorDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Doctor'),
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
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          return _buildDoctorCard(doctor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(dynamic doctor) {
    final deptName =
        doctor['department'] != null ? doctor['department']['name'] : 'N/A';

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
            child: const Icon(Icons.person_outline,
                color: Color(0xFF5B9BD5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor['full_name']}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doctor['specialization']} • $deptName',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${doctor['consultation_fee']}',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (val) {
              if (val == 'edit') {
                _showDoctorDialog(doctor: doctor);
              } else if (val == 'delete') {
                _confirmDelete(doctor);
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
