import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';

class AdminProductForm extends StatefulWidget {
  const AdminProductForm({
    super.key,
    this.product,
    required this.categories,
    required this.onSubmit,
    required this.submittingLabel,
    this.isSubmitting = false,
  });

  final ProductModel? product;
  final List<CategoryModel> categories;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  final String submittingLabel;
  final bool isSubmitting;

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _offerPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _imageController;
  int? _categoryId;
  bool _isFeatured = false;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.price?.toString() ?? '',
    );
    _offerPriceController = TextEditingController(
      text: p?.offerPrice?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: p?.quantity?.toString() ?? '',
    );
    _imageController = TextEditingController(text: p?.image ?? '');
    _categoryId = p?.categoryId;
    _isFeatured = p?.isFeatured ?? false;
    _status = p?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _quantityController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomTextField(
            controller: _nameController,
            labelText: 'Product Name',
            icon: Icons.badge_outlined,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _descriptionController,
            labelText: 'Description',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _priceController,
                  labelText: 'Price (USD)',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                  validator: (value) {
                    final price = double.tryParse(value ?? '');
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _offerPriceController,
                  labelText: 'Offer Price',
                  icon: Icons.local_offer_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _quantityController,
                  labelText: 'Stock Quantity',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity < 0) {
                      return 'Enter valid stock';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...widget.categories.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(
                          category.name ?? 'Category',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _categoryId = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _imageController,
            labelText: 'Image URL',
            icon: Icons.image_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Featured'),
                  value: _isFeatured,
                  onChanged: (value) {
                    setState(() => _isFeatured = value);
                  },
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? 'active');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.submittingLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final offerText = _offerPriceController.text.trim();
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'quantity': int.parse(_quantityController.text.trim()),
      'category_id': _categoryId,
      'image': _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
      'is_featured': _isFeatured,
      'status': _status,
      if (offerText.isNotEmpty) 'offer_price': double.parse(offerText),
    };

    await widget.onSubmit(data);
  }
}