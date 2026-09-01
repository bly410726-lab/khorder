import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/helpers.dart';
import '../../../providers/admin/admin_category_provider.dart';
import '../../../providers/admin/admin_product_provider.dart';
import '../../widgets/admin_product_form.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<AdminProductProvider>();
    final categoryProvider = context.watch<AdminCategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: AdminProductForm(
        categories: categoryProvider.categories,
        isSubmitting: productProvider.isSaving,
        submittingLabel: 'Create Product',
        onSubmit: (data) async {
          final success = await productProvider.addProduct(data);
          if (!context.mounted) return;
          if (success) {
            Helpers.showSnackBar(context, 'Product created successfully');
            Navigator.pop(context);
          } else {
            Helpers.showSnackBar(
              context,
              productProvider.errorMessage ?? 'Could not create product',
              isError: true,
            );
          }
        },
      ),
    );
  }
}