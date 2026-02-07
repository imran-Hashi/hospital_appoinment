import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _departments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  // Shaqada soo kicinta liiska waaxyada (Fetch Departments)
  Future<void> _fetchDepartments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = data;
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

  // Meesha lagu qoro xogta waaxda (Department Dialog)
  void _showDepartmentDialog({Map<String, dynamic>? dept}) {
    final bool isEdit = dept != null;
    final TextEditingController nameController =
        TextEditingController(text: dept?['name'] ?? '');
    final TextEditingController descController =
        TextEditingController(text: dept?['description'] ?? '');
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Cusboonaysii Waaxda' : 'Ku dar Waax cusub',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Magaca'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Faahfaahinta'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Jooji')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  setDialogState(() => dialogLoading = true);
                  try {
                    final data = {
                      'name': nameController.text,
                      'description': descController.text,
                    };
                    if (isEdit) {
                      await _apiService.updateDepartment(dept['id'], data);
                    } else {
                      await _apiService.createDepartment(data);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    _fetchDepartments();
                  } catch (e) {
                    setDialogState(() => dialogLoading = false);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Cilad: $e')));
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
                    : Text(isEdit ? 'Cusboonaysii' : 'Abuur',
                        style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hubinta tirtirista (Confirm Delete)
  void _confirmDelete(dynamic dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xaqiiji Tirtirista'),
        content: Text(
            'Ma hubaal inaad rabto inaad tirtirto waaxda ${dept['name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Jooji')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteDepartment(dept['id']);
                _fetchDepartments();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Cilad: $e')));
              }
            },
            child: const Text('Tirtir', style: TextStyle(color: Colors.red)),
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
                      'Waaxyaha',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Maamul waaxyaha isbitaalka',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDepartmentDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Ku dar Waax'),
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
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _departments.length,
                        itemBuilder: (context, index) {
                          final dept = _departments[index];
                          return _buildDeptCard(dept);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCard(dynamic dept) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B9BD5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital,
                    color: Color(0xFF5B9BD5), size: 20),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showDepartmentDialog(dept: dept);
                  } else if (val == 'delete') {
                    _confirmDelete(dept);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Wax ka beddel')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Tirtir', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dept['name'] ?? '',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            dept['description'] ?? 'No description',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
