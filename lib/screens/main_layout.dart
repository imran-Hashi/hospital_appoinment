import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'departments_screen.dart';
import 'doctors_screen.dart';
import 'patients_screen.dart';
import 'appointments_screen.dart';
import 'availability_screen.dart';
import 'login_screen.dart';
import 'menus_screen.dart';

class MainLayout extends StatefulWidget {
  final int roleId;

  const MainLayout({super.key, required this.roleId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final ApiService _apiService = ApiService();
  List<Menu> _menus = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
      final menus = await _apiService.getMenus(widget.roleId);
      setState(() {
        _menus = menus;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading menus: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _handleMenuSelection(int index) {
    if (_menus[index].route == '/logout') {
      // Handle logout
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
      // Close drawer after selection
      Navigator.of(context).pop();
    }
  }

  Widget _getScreenForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return const DashboardScreen();
      case '/users':
        return const UsersScreen();
      case '/departments':
        return const DepartmentsScreen();
      case '/doctors':
        return const DoctorsScreen();
      case '/patients':
        return const PatientsScreen();
      case '/appointments':
        return const AppointmentsScreen();
      case '/availability':
      case '/doctor-availability':
        return const AvailabilityScreen();
      case '/settings':
        return _buildPlaceholderScreen(route);
      case '/menus':
        return MenusScreen(
            onMenuChanged: _fetchMenus, autoAssignRoleId: widget.roleId);
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildPlaceholderScreen(String route) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '${route.replaceAll('/', '').toUpperCase()} Screen',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.indigo, size: 24),
            const SizedBox(width: 8),
            Text(
              'MedApp',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        child: AdminSidebar(
          menus: _menus,
          selectedIndex: _selectedIndex,
          onItemSelected: _handleMenuSelection,
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                        onPressed: _fetchMenus, child: const Text('Retry'))
                  ],
                ),
              )
            : _menus.isNotEmpty
                ? _getScreenForRoute(_menus[_selectedIndex].route)
                : const Center(
                    child: Text(
                      'No menus available',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
      ),
    );
  }
}
