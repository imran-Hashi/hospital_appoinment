import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoadingDoctors = true;
  bool _isLoadingAvailability = false;
  List<dynamic> _doctors = [];
  dynamic _selectedDoctor;
  Map<String, dynamic> _weeklyStatus = {}; // day -> availability record or null
  late TabController _tabController;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Default to Weekly as per image
    _fetchDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _apiService.getDoctors();
      setState(() {
        _doctors = doctors;
        _isLoadingDoctors = false;
        if (_doctors.isNotEmpty) {
          _selectedDoctor = _doctors[0];
          _fetchAvailabilityForDoctor(_selectedDoctor['id']);
        }
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
    }
  }

  Future<void> _fetchAvailabilityForDoctor(int doctorId) async {
    setState(() => _isLoadingAvailability = true);
    try {
      // We need a way to get availability by doctor.
      // Existing ApiService has getAvailabilities() which returns all.
      // I'll filter for now, but in a real app we'd use a specific endpoint.
      final all = await _apiService.getAvailabilities();
      final filtered = all.where((a) => a['doctor_id'] == doctorId).toList();

      final Map<String, dynamic> statusMap = {};
      for (var day in _daysOfWeek) {
        statusMap[day] = filtered.firstWhere((a) => a['day_of_week'] == day,
            orElse: () => null);
      }

      setState(() {
        _weeklyStatus = statusMap;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvailability = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleDay(String day, bool enabled) async {
    if (_selectedDoctor == null) return;

    // Optimistic UI update
    final oldRecord = _weeklyStatus[day];

    try {
      if (enabled) {
        // Create availability with default times
        final newRecord = await _apiService.createAvailability({
          'doctor_id': _selectedDoctor['id'],
          'day_of_week': day,
          'start_time': '09:00',
          'end_time': '17:00',
        });
        setState(() => _weeklyStatus[day] = newRecord);
      } else {
        if (oldRecord != null) {
          await _apiService.deleteAvailability(oldRecord['id']);
          setState(() => _weeklyStatus[day] = null);
        }
      }
    } catch (e) {
      // Revert if failed
      setState(() => _weeklyStatus[day] = oldRecord);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void _showTimePicker(String day, dynamic record) async {
    if (record == null) return;

    TimeOfDay start = TimeOfDay(
      hour: int.parse(record['start_time'].split(':')[0]),
      minute: int.parse(record['start_time'].split(':')[1]),
    );
    TimeOfDay end = TimeOfDay(
      hour: int.parse(record['end_time'].split(':')[0]),
      minute: int.parse(record['end_time'].split(':')[1]),
    );

    final TimeOfDay? pickedStart = await showTimePicker(
      context: context,
      initialTime: start,
      helpText: 'Select Start Time',
    );

    if (pickedStart != null) {
      final TimeOfDay? pickedEnd = await showTimePicker(
        context: context,
        initialTime: end,
        helpText: 'Select End Time',
      );

      if (pickedEnd != null) {
        try {
          final updated = await _apiService.updateAvailability(record['id'], {
            'doctor_id': _selectedDoctor['id'],
            'day_of_week': day,
            'start_time':
                '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}',
            'end_time':
                '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}',
          });
          setState(() => _weeklyStatus[day] = updated);
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Update failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDoctors) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<dynamic>(
            value: _selectedDoctor,
            items: _doctors
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('Dr. ${d['full_name']}',
                          style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold)),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedDoctor = val);
              _fetchAvailabilityForDoctor(val['id']);
            },
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A1C1E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text('Daily View Coming Soon')),
          _buildWeeklyView(),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    if (_isLoadingAvailability) {
      return const Center(child: CircularProgressIndicator());
    }

    final String dateRange =
        'Week of ${DateFormat('MMM dd').format(DateTime.now())} - ${DateFormat('MMM dd').format(DateTime.now().add(const Duration(days: 6)))}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateRange,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 24),
          ..._daysOfWeek.map((day) => _buildDayTile(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildDayTile(String day) {
    final record = _weeklyStatus[day];
    final bool isEnabled = record != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) => _toggleDay(day, val),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF5B9BD5),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[300],
              ),
            ],
          ),
          if (isEnabled)
            GestureDetector(
              onTap: () => _showTimePicker(day, record),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      '${record['start_time']} - ${record['end_time']}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF5B9BD5),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: Color(0xFF5B9BD5)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[100], height: 1),
        ],
      ),
    );
  }
}
