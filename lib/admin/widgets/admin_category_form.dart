import 'package:flutter/material.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../models/category_model.dart';

class AdminCategoryForm extends StatefulWidget {
  const AdminCategoryForm({
    super.key,
    this.category,
    required this.onSubmit,
    required this.submittingLabel,
    this.isSubmitting = false,
  });

  final CategoryModel? category;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  final String submittingLabel;
  final bool isSubmitting;

  @override
  State<AdminCategoryForm> createState() => _AdminCategoryFormState();
}

class _AdminCategoryFormState extends State<AdminCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _imageController = TextEditingController(text: c?.image ?? '');
    _status = c?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
            labelText: 'Category Name',
            icon: Icons.category_outlined,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Category name is required';
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
          CustomTextField(
            controller: _imageController,
            labelText: 'Image URL',
            icon: Icons.image_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'image': _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
      'status': _status,
    });
  }
}