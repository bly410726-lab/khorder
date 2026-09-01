import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/customer/favorite_provider.dart';
import '../../widgets/product_card.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _buildBody(favoriteProvider),
    );
  }

  Widget _buildBody(FavoriteProvider favoriteProvider) {
    if (favoriteProvider.isLoading && favoriteProvider.favorites.isEmpty) {
      return const LoadingWidget();
    }
    if (favoriteProvider.errorMessage != null &&
        favoriteProvider.favorites.isEmpty) {
      return AppErrorWidget(
        message: favoriteProvider.errorMessage!,
        onRetry: () => favoriteProvider.fetchFavorites(),
      );
    }
    if (favoriteProvider.favorites.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_outline,
        title: 'No favorites yet',
        message: 'Tap the heart icon on a product to save it here.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => favoriteProvider.fetchFavorites(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: favoriteProvider.favorites.length,
        itemBuilder: (context, index) {
          return ProductCard(product: favoriteProvider.favorites[index]);
        },
      ),
    );
  }
}