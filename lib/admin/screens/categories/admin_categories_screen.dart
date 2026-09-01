import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/category_model.dart';
import '../../../providers/admin/admin_category_provider.dart';
import '../../widgets/admin_drawer.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.adminAddCategory);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: _buildContent(provider),
    );
  }

  Widget _buildContent(AdminCategoryProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.categories.isEmpty) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchCategories(),
      );
    }
    if (provider.categories.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        message: 'Tap the Add Category button to create one.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchCategories(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          return _CategoryTile(
            category: category,
            onEdit: () {
              Navigator.pushNamed(
                context,
                AppRoutes.adminEditCategory,
                arguments: category,
              );
            },
            onDelete: () => _deleteCategory(context, provider, category),
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    AdminCategoryProvider provider,
    CategoryModel category,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete "${category.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final success = await provider.deleteCategory(category.id ?? -1);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not delete category'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: AppNetworkImage(url: category.image, icon: Icons.category),
          ),
        ),
        title: Text(
          category.name ?? 'No name',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description?.isNotEmpty == true)
              Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (category.productCount != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${category.productCount} products',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 4),
            StatusBadge(status: category.status),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}