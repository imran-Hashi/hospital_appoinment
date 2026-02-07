import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _apiService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  void _showUserDialog({Map<String, dynamic>? user}) async {
    final bool isEdit = user != null;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController emailController =
        TextEditingController(text: user?['email'] ?? '');
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController =
        TextEditingController(text: user?['full_name'] ?? '');

    List<dynamic> roles = [];
    int? selectedRoleId = user?['role_id'];
    String? selectedStatus = user?['status'] ?? 'ACTIVE';
    bool dialogLoading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (dialogLoading && roles.isEmpty) {
            _apiService.getRoles().then((value) {
              setDialogState(() {
                roles = value;
                dialogLoading = false;
                if (!isEdit && roles.isNotEmpty) {
                  selectedRoleId = roles.first['id'];
                }
              });
            }).catchError((e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading roles: $e')),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          return AlertDialog(
            title: Text(isEdit ? 'Update User' : 'Add New User',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Invalid email'
                          : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'Password (leave blank to keep current)'
                            : 'Password',
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (isEdit) return null;
                        return v == null || v.length < 6
                            ? 'Min 6 characters'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedRoleId,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: roles.map<DropdownMenuItem<int>>((role) {
                        return DropdownMenuItem<int>(
                          value: role['id'],
                          child: Text(role['name']),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedRoleId = v),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(
                            value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedStatus = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    setDialogState(() => dialogLoading = true);
                    try {
                      final Map<String, dynamic> userData = {
                        'email': emailController.text,
                        'full_name': fullNameController.text,
                        'role_id': selectedRoleId,
                        'status': selectedStatus,
                      };
                      if (passwordController.text.isNotEmpty) {
                        userData['password'] = passwordController.text;
                      }

                      if (isEdit) {
                        await _apiService.updateUser(user['id'], userData);
                      } else {
                        await _apiService.createUser(userData);
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      _fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isEdit
                                ? 'User updated successfully'
                                : 'User created successfully')),
                      );
                    } catch (e) {
                      setDialogState(() => dialogLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
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

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user ${user['email']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteUser(user['id']);
                _fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users Management',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage system users and their roles',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B9BD5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final roleName = user['role'] != null
                                ? user['role']['name'] ?? 'No Role'
                                : 'No Role';

                            return _buildUserCard(user, roleName);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user, String role) {
    final String email = user['email'] ?? 'No Email';
    final String status = user['status'] ?? 'ACTIVE';

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF5B9BD5).withOpacity(0.1),
            radius: 18,
            child: const Icon(Icons.person, color: Color(0xFF5B9BD5), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status.toUpperCase() == 'ACTIVE'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status.toUpperCase() == 'ACTIVE'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'edit') {
                _showUserDialog(user: user);
              } else if (val == 'delete') {
                _confirmDelete(user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
