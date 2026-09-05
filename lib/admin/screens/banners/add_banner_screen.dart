import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/admin/admin_banner_provider.dart';

class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');
  bool _isActive = true;
  File? _selectedImage;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminBannerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Banner')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.toggle_on_outlined, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Active',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
                prefixIcon: Icon(Icons.sort),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: provider.isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: provider.isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Upload Banner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Banner Image *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.divider,
                width: 1.5,
              ),
            ),
            child: _buildImagePreview(),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap to choose an image (JPEG, PNG, WebP, max 5MB)',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb
            ? (_webImageBytes != null
                ? Image.memory(
                    _webImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  )
                : const LoadingWidget())
            : Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose Image',
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final fileBytes = await file.length();

    if (fileBytes > 5 * 1024 * 1024) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Image too large. Maximum size is 5MB.',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _selectedImage = file;
    });

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => _webImageBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      Helpers.showSnackBar(
        context,
        'Please select a banner image.',
        isError: true,
      );
      return;
    }

    final provider = context.read<AdminBannerProvider>();
    final success = await provider.addBanner(
      imageFile: _selectedImage!,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
    );

    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Banner uploaded successfully');
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        provider.errorMessage ?? 'Could not upload banner',
        isError: true,
      );
    }
  }
}
