import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.icon = Icons.image_outlined,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData icon;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  String? get _normalizedUrl {
    final url = widget.url?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final url = _normalizedUrl;
    if (url == null) {
      return _placeholder();
    }
    return Image.network(
      url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Icon(
        widget.icon,
        size: 28,
        color: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
