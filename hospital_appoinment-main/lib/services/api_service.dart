import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/menu_model.dart';

class ApiService {
  // Shaqada soo kicinta liiska menu-yada iyadoo la raacayo roleId
  Future<List<Menu>> getMenus(int roleId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/role-menus/$roleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // API-gu wuxuu soo celinayaa walxo ay ku jiraan 'menu'
        // Waxaan u baahanahay inaan ku dhex jirno menu-ka model-ka
        return data
            .where((item) => item['menu'] != null)
            .map((item) => Menu.fromJson(item['menu']))
            .toList();
      } else {
        throw Exception('Failed to load menus');
      }
    } catch (e) {
      throw Exception('Error fetching menus: $e');
    }
  }

  // Shaqada gelitaanka nidaamka (Log-in)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Ku kaydi xogta isticmaalaha SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userData['id'] ?? 0);
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setInt('role_id', userData['role_id'] ?? 0);

        return userData;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(e.toString());
    }
  }

  // Soo kicinta aqoonsiga isticmaalaha hadda jira (User ID)
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Soo kicinta iimaylka isticmaalaha hadda jira
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/dashboard/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/roles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load roles');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateUser(
      int id, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Waaxyaha (Departments CRUD)
  Future<List<dynamic>> getDepartments() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}/departments'));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load departments');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createDepartment(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/departments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to create department');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateDepartment(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/departments/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to update department');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Constants.baseUrl}/departments/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Dhakhaatiirta (Doctors CRUD)
  Future<List<dynamic>> getDoctors() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}/doctors'));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load doctors');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/doctors'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to create doctor');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateDoctor(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/doctors/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to update doctor');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteDoctor(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Constants.baseUrl}/doctors/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Bukaannada (Patients CRUD)
  Future<List<dynamic>> getPatients() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}/patients'));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load patients');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/patients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to create patient');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updatePatient(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/patients/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to update patient');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Constants.baseUrl}/patients/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Ballamaha (Appointments CRUD)
  Future<List<dynamic>> getAppointments() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}/appointments'));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load appointments');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createAppointment(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to create appointment');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateAppointment(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/appointments/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to update appointment');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteAppointment(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Constants.baseUrl}/appointments/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Boosaska Bannaan ee Dhakhaatiirta (Doctor Availability CRUD)
  Future<List<dynamic>> getAvailabilities() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}/doctor-availability'));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load availabilities');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createAvailability(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/doctor-availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to create availability');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateAvailability(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/doctor-availability/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to update availability');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteAvailability(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('${Constants.baseUrl}/doctor-availability/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Adeegyada Menu-yada (Menus CRUD)
  Future<List<dynamic>> getAllMenus() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/menus'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load menus');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createMenu(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/menus'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to create menu');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateMenu(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/menus/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to update menu');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteMenu(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Constants.baseUrl}/menus/$id'));
      if (response.statusCode != 200)
        throw Exception(
            json.decode(response.body)['message'] ?? 'Failed to delete');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> createRoleMenu(int roleId, int menuId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/role-menus'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role_id': roleId, 'menu_id': menuId}),
      );
      if (response.statusCode != 201) {
        // If 400 (already exists), that's fine/ignored, but let's throw if other error
        // actually checking response body might be good but let's keep it simple
        throw Exception('Failed to assign menu to role');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
