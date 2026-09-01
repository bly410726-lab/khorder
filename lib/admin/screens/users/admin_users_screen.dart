import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin/admin_user_provider.dart';
import '../../widgets/admin_drawer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filtered(List<UserModel> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((user) {
      return (user.name?.toLowerCase().contains(q) ?? false) ||
          (user.email?.toLowerCase().contains(q) ?? false) ||
          (user.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUserProvider>();
    final users = _filtered(provider.users);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(provider, users),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminUserProvider provider, List<UserModel> users) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.users.isEmpty) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchUsers(),
      );
    }
    if (users.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: provider.users.isEmpty ? 'No customers yet' : 'No matching users',
        message: provider.users.isEmpty
            ? 'Customers who create accounts will appear here.'
            : 'Try a different search.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchUsers(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _UserTile(user: users[index]);
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          user.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email?.isNotEmpty == true)
              Text(
                user.email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (user.phone?.isNotEmpty == true)
              Text(
                user.phone!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: _RoleBadge(role: user.role),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role?.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Customer',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AppColors.primary : AppColors.success,
        ),
      ),
    );
  }
}