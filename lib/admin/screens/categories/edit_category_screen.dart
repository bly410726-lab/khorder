import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/category_model.dart';
import '../../../providers/admin/admin_category_provider.dart';
import '../../widgets/admin_category_form.dart';

class EditCategoryScreen extends StatefulWidget {
  const EditCategoryScreen({super.key});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  CategoryModel? _category;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CategoryModel) {
      _category = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();

    if (_category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Category')),
        body: const Center(child: Text('Category not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Category')),
      body: AdminCategoryForm(
        category: _category,
        isSubmitting: provider.isSaving,
        submittingLabel: 'Save Changes',
        onSubmit: (data) async {
          final success = await provider.updateCategory(_category!.id!, data);
          if (!context.mounted) return;
          if (success) {
            Helpers.showSnackBar(context, 'Category updated successfully');
            Navigator.pop(context);
          } else {
            Helpers.showSnackBar(
              context,
              provider.errorMessage ?? 'Could not update category',
              isError: true,
            );
          }
        },
      ),
    );
  }
}