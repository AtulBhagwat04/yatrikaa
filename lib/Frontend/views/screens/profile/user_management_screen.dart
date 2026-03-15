import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(automaticallyImplyLeading: false, 
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          'User Management',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.body('Error: $_error', color: errorColor),
            TextButton(onPressed: _fetchUsers, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_users.isEmpty) return const Center(child: Text('No users found'));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final role = user['role'] ?? 'user';
        final initial = (user['name'] ?? '?')[0].toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(role).withOpacity(0.1),
              child: Text(
                initial,
                style: TextStyle(
                  color: _getRoleColor(role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: AppText.body(
              user['name'] ?? 'Unknown',
              fontWeight: FontWeight.bold,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.caption(user['email'] ?? '', size: 12),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppText.small(
                    role.toUpperCase(),
                    color: _getRoleColor(role),
                    size: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete User',
                    style: TextStyle(color: errorColor),
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'delete') {
                  _deleteUser(user['_id']);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    String r = role.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (r == 'admin') return adminColor;
    if (r == 'guide') return guideColor;
    return primaryBlue;
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/auth/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
        _fetchUsers();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
