import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_model.dart';

class AdminSidebar extends StatelessWidget {
  final List<Menu> menus;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.menus,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onItemSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF3F4F6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIcon(menu.icon),
                              size: 20,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              menu.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Logout placeholder at bottom if needed, though it's in the menu list
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return Icons.home_filled;
      case 'users':
      case 'people':
        return Icons.people_outline;
      case 'departments':
      case 'apartment':
        return Icons.business;
      case 'doctors':
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'patients':
      case 'people_outline':
        return Icons.person_outline;
      case 'appointments':
      case 'calendar_today':
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'event_available':
        return Icons.event_available;
      case 'logout':
        return Icons.logout;
      case 'menu':
      case 'list':
        return Icons.list;
      default:
        return Icons.circle_outlined;
    }
  }
}
