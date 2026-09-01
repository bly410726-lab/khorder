import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/helpers.dart';
import '../../../providers/admin/admin_category_provider.dart';
import '../../widgets/admin_category_form.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: AdminCategoryForm(
        isSubmitting: provider.isSaving,
        submittingLabel: 'Create Category',
        onSubmit: (data) async {
          final success = await provider.addCategory(data);
          if (!context.mounted) return;
          if (success) {
            Helpers.showSnackBar(context, 'Category created successfully');
            Navigator.pop(context);
          } else {
            Helpers.showSnackBar(
              context,
              provider.errorMessage ?? 'Could not create category',
              isError: true,
            );
          }
        },
      ),
    );
  }
}