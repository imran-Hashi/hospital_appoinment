import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = data;
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

  void _showAppointmentDialog({Map<String, dynamic>? appointment}) async {
    final bool isEdit = appointment != null;
    final TextEditingController dateController = TextEditingController(
        text: appointment?['appointment_date'] != null
            ? DateFormat('yyyy-MM-dd')
                .format(DateTime.parse(appointment!['appointment_date']))
            : '');
    final TextEditingController timeController =
        TextEditingController(text: appointment?['appointment_time'] ?? '');
    final TextEditingController reasonController =
        TextEditingController(text: appointment?['reason'] ?? '');

    List<dynamic> patients = [];
    List<dynamic> doctors = [];
    int? selectedPatientId = appointment?['patient_id'];
    int? selectedDoctorId = appointment?['doctor_id'];
    String? selectedStatus = appointment?['status'] ?? 'PENDING';
    bool dialogLoading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (dialogLoading && patients.isEmpty) {
            Future.wait([
              _apiService.getPatients(),
              _apiService.getDoctors(),
            ]).then((results) {
              setDialogState(() {
                patients = results[0];
                doctors = results[1];
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
            title: Text(isEdit ? 'Update Appointment' : 'Book Appointment',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedPatientId,
                    decoration: const InputDecoration(labelText: 'Patient'),
                    items: patients
                        .map<DropdownMenuItem<int>>((p) => DropdownMenuItem(
                            value: p['id'], child: Text(p['full_name'])))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedPatientId = v),
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedDoctorId,
                    decoration: const InputDecoration(labelText: 'Doctor'),
                    items: doctors
                        .map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                            value: d['id'],
                            child: Text('Dr. ${d['full_name']}')))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedDoctorId = v),
                  ),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                  ),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Time (HH:mm)',
                        suffixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        timeController.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  TextField(
                    controller: reasonController,
                    decoration:
                        const InputDecoration(labelText: 'Reason (Optional)'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'CONFIRMED', child: Text('Confirmed')),
                      DropdownMenuItem(
                          value: 'COMPLETED', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'CANCELLED', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedStatus = v),
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
                  if (selectedPatientId == null ||
                      selectedDoctorId == null ||
                      dateController.text.isEmpty ||
                      timeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fill all required fields')));
                    return;
                  }
                  setDialogState(() => dialogLoading = true);
                  try {
                    final data = {
                      'patient_id': selectedPatientId,
                      'doctor_id': selectedDoctorId,
                      'appointment_date': dateController.text,
                      'appointment_time': timeController.text,
                      'status': selectedStatus, // Include status in data
                    };
                    if (reasonController.text.isNotEmpty) {
                      data['reason'] = reasonController.text;
                    }

                    if (isEdit) {
                      await _apiService.updateAppointment(
                          appointment['id'], data);
                    } else {
                      await _apiService.createAppointment(data);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    _fetchAppointments();
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
                    : Text(isEdit ? 'Update' : 'Book',
                        style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(dynamic appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteAppointment(appointment['id']);
                _fetchAppointments();
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
                      'Appointments',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Text(
                      'Manage doctor appointments',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAppointmentDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Book New'),
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
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final apt = _appointments[index];
                          return _buildAppointmentCard(apt);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic apt) {
    final patientName =
        apt['patient'] != null ? apt['patient']['full_name'] : 'N/A';
    final doctorName =
        apt['doctor'] != null ? apt['doctor']['full_name'] : 'N/A';
    final date = apt['appointment_date'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(apt['appointment_date']))
        : 'N/A';

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B9BD5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today,
                    color: Color(0xFF5B9BD5), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'with Dr. $doctorName',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(apt['status'] ?? 'PENDING'),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAppointmentDialog(appointment: apt);
                  } else if (val == 'delete') {
                    _confirmDelete(apt);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$date at ${apt['appointment_time']}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              Text(
                apt['reason'] ?? 'Routine Checkup',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'CONFIRMED':
        color = Colors.blue;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
