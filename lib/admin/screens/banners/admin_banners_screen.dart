import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/banner_model.dart';
import '../../../providers/admin/admin_banner_provider.dart';
import '../../widgets/admin_drawer.dart';
import 'add_banner_screen.dart';
import 'edit_banner_screen.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBannerProvider>().fetchBanners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminBannerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Banners')),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBannerScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Banner'),
      ),
      body: _buildContent(provider),
    );
  }

  Widget _buildContent(AdminBannerProvider provider) {
    if (provider.isLoading && provider.banners.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.banners.isEmpty) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchBanners(),
      );
    }
    if (provider.banners.isEmpty) {
      return EmptyState(
        icon: Icons.view_carousel_outlined,
        title: 'No banners yet',
        message: 'Tap the Add Banner button to create one.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchBanners(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: provider.banners.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final banner = provider.banners[index];
          return _BannerTile(
            banner: banner,
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditBannerScreen(banner: banner),
                ),
              );
            },
            onToggle: () => _toggleBanner(provider, banner),
            onDelete: () => _deleteBanner(provider, banner),
          );
        },
      ),
    );
  }

  Future<void> _toggleBanner(
    AdminBannerProvider provider,
    BannerModel banner,
  ) async {
    final success = await provider.toggleBanner(banner);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (banner.isActive ?? true)
                ? 'Banner deactivated'
                : 'Banner activated',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not update banner'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteBanner(
    AdminBannerProvider provider,
    BannerModel banner,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Banner',
      message: 'Are you sure you want to delete this banner?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await provider.deleteBanner(banner.id ?? -1);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not delete banner'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = banner.isActive ?? true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: AppNetworkImage(
              url: banner.image,
              fit: BoxFit.cover,
              icon: Icons.view_carousel_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title?.isNotEmpty == true
                            ? banner.title!
                            : 'Banner #${banner.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sort order: ${banner.sortOrder ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isActive: isActive),
              ],
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isActive ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                label: Text(isActive ? 'Disable' : 'Enable'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
