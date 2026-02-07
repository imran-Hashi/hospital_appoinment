import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class MenusScreen extends StatefulWidget {
  final VoidCallback? onMenuChanged;
  final int? autoAssignRoleId;

  const MenusScreen({super.key, this.onMenuChanged, this.autoAssignRoleId});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _menus = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final menus = await _apiService.getAllMenus();
      if (!mounted) return;
      setState(() {
        _menus = menus;
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

  void _showMenuDialog({Map<String, dynamic>? menu}) async {
    final bool isEdit = menu != null;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: menu?['name'] ?? '');
    final TextEditingController routeController =
        TextEditingController(text: menu?['route'] ?? '');
    final TextEditingController iconController =
        TextEditingController(text: menu?['icon'] ?? '');

    // For parent selection
    int? selectedParentId = menu?['parent_id'];

    // Filter out the current menu from potential parents (to avoid cycles)
    // and only show top-level menus or whatever logic applies.
    // For simplicity, allow any other menu as parent.
    List<dynamic> potentialParents =
        _menus.where((m) => m['id'] != (menu?['id'] ?? -1)).toList();

    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Update Menu' : 'Add New Menu',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Menu Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: routeController,
                      decoration: const InputDecoration(
                          labelText: 'Route (e.g., /dashboard)'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: iconController,
                      decoration: const InputDecoration(
                          labelText: 'Icon Name (e.g., dashboard)'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedParentId,
                      decoration: const InputDecoration(
                          labelText: 'Parent Menu (Optional)'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No Parent (Top Level)'),
                        ),
                        ...potentialParents.map<DropdownMenuItem<int>>((m) {
                          return DropdownMenuItem<int>(
                            value: m['id'],
                            child: Text('${m['name']} (ID: ${m['id']})'),
                          );
                        }).toList()
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedParentId = v),
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
                      final Map<String, dynamic> menuData = {
                        'name': nameController.text,
                        'route': routeController.text,
                        'icon': iconController.text,
                        'parent_id': selectedParentId,
                      };

                      if (isEdit) {
                        await _apiService.updateMenu(menu['id'], menuData);
                      } else {
                        final newMenu = await _apiService.createMenu(menuData);
                        // Auto-assign to current role if ID is provided
                        if (widget.autoAssignRoleId != null) {
                          try {
                            await _apiService.createRoleMenu(
                                widget.autoAssignRoleId!, newMenu['id']);
                          } catch (e) {
                            print('Failed to auto-assign menu: $e');
                            // Optional: show snackbar warning
                          }
                        }
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      _fetchMenus();
                      widget.onMenuChanged?.call(); // Notify parent
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isEdit
                                ? 'Menu updated successfully'
                                : 'Menu created successfully')),
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

  void _confirmDelete(dynamic menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            Text('Are you sure you want to delete menu "${menu['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteMenu(menu['id']);
                _fetchMenus();
                widget.onMenuChanged?.call(); // Notify parent
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu deleted successfully')),
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
                        'Menu Management',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage system menus, routes, and icons',
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
                  onPressed: () => _showMenuDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Menu'),
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
                              onPressed: _fetchMenus,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMenus,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _menus.length,
                          itemBuilder: (context, index) {
                            final menu = _menus[index];
                            return _buildMenuCard(menu);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(dynamic menu) {
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
            child: Icon(
                _getIconData(menu[
                    'icon']), // You might need a helper to convert string to IconData
                color: const Color(0xFF5B9BD5),
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu['name'] ?? 'No Name',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Route: ${menu['route']} | ID: ${menu['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (menu['parent'] != null)
                  Text(
                    'Parent: ${menu['parent']['name']} (ID: ${menu['parent']['id']})',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.indigo[400],
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'edit') {
                _showMenuDialog(menu: menu);
              } else if (val == 'delete') {
                _confirmDelete(menu);
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

  // Helper to map string to IconData (Basic list, expand as needed)
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'dashboard':
        return Icons.dashboard;
      case 'people':
        return Icons.people;
      case 'person':
        return Icons.person;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'schedule':
        return Icons.schedule;
      case 'business':
        return Icons.business;
      case 'settings':
        return Icons.settings;
      case 'list':
        return Icons.list;
      case 'menu':
        return Icons.menu;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.circle; // Default icon
    }
  }
}
