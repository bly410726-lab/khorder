import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/helpers.dart';
import '../../../models/product_model.dart';
import '../../../providers/admin/admin_category_provider.dart';
import '../../../providers/admin/admin_product_provider.dart';
import '../../widgets/admin_product_form.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductModel) {
      _product = args;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<AdminProductProvider>();
    final categoryProvider = context.watch<AdminCategoryProvider>();

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: AdminProductForm(
        product: _product,
        categories: categoryProvider.categories,
        isSubmitting: productProvider.isSaving,
        submittingLabel: 'Save Changes',
        onSubmit: (data) async {
          final success = await productProvider.updateProduct(
            _product!.id!,
            data,
          );
          if (!context.mounted) return;
          if (success) {
            Helpers.showSnackBar(context, 'Product updated successfully');
            Navigator.pop(context);
          } else {
            Helpers.showSnackBar(
              context,
              productProvider.errorMessage ?? 'Could not update product',
              isError: true,
            );
          }
        },
      ),
    );
  }
}