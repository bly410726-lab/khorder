import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../widgets/category_card.dart';
import '../../widgets/product_card.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer/category_provider.dart';
import '../../../providers/customer/product_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    await Future.wait([
      productProvider.fetchProducts(),
      productProvider.fetchFeaturedProducts(),
      categoryProvider.fetchCategories(),
    ]);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String? get _userName {
    final user = context.read<AuthProvider>().user;
    if (user?.name == null || user!.name!.isEmpty) return null;
    return user.name;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final name = _userName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_greeting${name != null ? ', $name' : ''}',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'What would you like today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.search);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(productProvider, categoryProvider),
      ),
    );
  }

  Widget _buildBody(ProductProvider productProvider, CategoryProvider categoryProvider) {
    if (productProvider.isLoading) {
      return const LoadingWidget();
    }
    if (productProvider.errorMessage != null && productProvider.products.isEmpty) {
      return AppErrorWidget(
        message: productProvider.errorMessage!,
        onRetry: _loadData,
      );
    }

    final products = productProvider.products;
    final featured = productProvider.featuredProducts;
    final categories = categoryProvider.categories;

    if (products.isEmpty && categories.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'No products available',
        message: 'Check back later, we are updating our store.',
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverToBoxAdapter(
            child: _SearchBar(),
          ),
        ),
        if (categories.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Categories',
                onSeeAll: () => Navigator.pushNamed(context, AppRoutes.category),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return SizedBox(
                    width: 104,
                    child: CategoryCard(category: category),
                  );
                },
              ),
            ),
          ),
        ],
        if (featured.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            sliver: SliverToBoxAdapter(
              child: const _SectionHeader(title: 'Featured'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: ProductCard(product: featured[index]),
                  );
                },
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          sliver: SliverToBoxAdapter(
            child: const _SectionHeader(title: 'Popular Products'),
          ),
        ),
        if (products.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No products found',
                message: 'Try another search or category.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: products[index]),
                childCount: products.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.search);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search products...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Khmer',
                style: TextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
      ],
    );
  }
}